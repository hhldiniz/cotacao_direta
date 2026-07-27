import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeCurrencyAlertRepository alertRepository;
  late FakeCurrencyDao currencyDao;
  late FakeNotificationService notificationService;

  CurrencyAlertsBloc buildBloc({double currencyValue = 5.5}) {
    currencyDao.latestCurrency = Currency(
        id: "USD",
        value: currencyValue,
        historicalDate: DateTime.now().toIso8601String(),
        timestamp: DateTime.now().toIso8601String(),
        friendlyName: "Dólar dos Estados Unidos");
    return CurrencyAlertsBloc(
        currencyAlertRepository: alertRepository,
        currencyRepository: CurrencyRepository.withDependencies(
            currencyDao: currencyDao,
            configurationRepository: FakeConfigurationRepository(),
            networkUtils: FakeNetworkUtils(available: false)),
        notificationService: notificationService);
  }

  setUp(() {
    alertRepository = FakeCurrencyAlertRepository();
    currencyDao = FakeCurrencyDao();
    notificationService = FakeNotificationService();
  });

  group('CurrencyAlertsBloc.loadAlerts', () {
    test('publica os alertas gravados na stream', () async {
      alertRepository.alerts.add(CurrencyAlert(
          currencyCode: "USD",
          targetValue: 5.0,
          condition: CurrencyAlertCondition.above));
      var bloc = buildBloc();
      var received = bloc.alertsStream.first;

      await bloc.loadAlerts();

      expect((await received).single.currencyCode, "USD");
    });
  });

  group('CurrencyAlertsBloc.addAlert', () {
    test('grava o alerta no repositório', () async {
      var bloc = buildBloc();

      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);

      expect(alertRepository.alerts, hasLength(1));
      expect(alertRepository.alerts.single.currencyCode, "USD");
      expect(alertRepository.alerts.single.targetValue, 5.0);
    });

    test('atualiza a stream depois de adicionar', () async {
      var bloc = buildBloc();
      var received = bloc.alertsStream.first;

      await bloc.addAlert("EUR", 6.0, CurrencyAlertCondition.below);

      expect((await received).single.currencyCode, "EUR");
    });
  });

  group('CurrencyAlertsBloc.deleteAlert', () {
    test('remove o alerta do repositório', () async {
      var bloc = buildBloc();
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);
      var id = alertRepository.alerts.single.id!;

      await bloc.deleteAlert(id);

      expect(alertRepository.alerts, isEmpty);
    });
  });

  group('CurrencyAlertsBloc.checkAlerts', () {
    test('dispara notificação e marca como disparado quando a condição é atendida',
        () async {
      var bloc = buildBloc(currencyValue: 5.5);
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);

      await bloc.checkAlerts(
          notificationTitle: "Alerta",
          notificationBody: (alert, value) => "${alert.currencyCode} $value");

      expect(alertRepository.alerts.single.triggered, isTrue);
      expect(notificationService.shown, hasLength(1));
      expect(notificationService.shown.single['title'], "Alerta");
      expect(notificationService.shown.single['body'], "USD 5.5");
    });

    test('não dispara quando a condição não é atendida', () async {
      var bloc = buildBloc(currencyValue: 4.0);
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);

      await bloc.checkAlerts(
          notificationTitle: "Alerta", notificationBody: (alert, value) => "");

      expect(alertRepository.alerts.single.triggered, isFalse);
      expect(notificationService.shown, isEmpty);
    });

    test('ignora alertas já disparados', () async {
      var bloc = buildBloc(currencyValue: 5.5);
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);
      alertRepository.alerts.single.triggered = true;

      await bloc.checkAlerts(
          notificationTitle: "Alerta", notificationBody: (alert, value) => "");

      expect(notificationService.shown, isEmpty);
    });

    test('ignora alertas inativos', () async {
      var bloc = buildBloc(currencyValue: 5.5);
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);
      alertRepository.alerts.single.active = false;

      await bloc.checkAlerts(
          notificationTitle: "Alerta", notificationBody: (alert, value) => "");

      expect(notificationService.shown, isEmpty);
    });
  });

  group('CurrencyAlertsBloc.dispose', () {
    test('fecha a stream de alertas', () async {
      var bloc = buildBloc();

      bloc.dispose();

      expect(await bloc.alertsStream.isEmpty, isTrue);
    });
  });
}
