import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeCurrencyAlertRepository alertRepository;
  late FakeCurrencyDao currencyDao;
  late FakeNotificationService notificationService;

  /// Cotação guardada no banco para um par, montada a partir de [quotedRate] —
  /// a cotação na convenção que o usuário vê e digita no alerta (quantos reais
  /// vale um dólar). O banco guarda o inverso disso, como faz o
  /// CurrencyRepository.
  Currency storedQuote(double quotedRate) => Currency(
      id: "USD",
      value: 1 / quotedRate,
      historicalDate: DateTime.now().toIso8601String(),
      timestamp: DateTime.now().toIso8601String(),
      friendlyName: "Dólar dos Estados Unidos");

  /// [counterCurrency] é a contrapartida escolhida nas configurações, que é a
  /// que os alertas criados daqui em diante recebem.
  CurrencyAlertsBloc buildBloc(
      {double quotedRate = 5.5, String? counterCurrency}) {
    currencyDao.latestCurrency = storedQuote(quotedRate);
    var configuration = Configuration(1);
    if (counterCurrency != null) {
      configuration.overrideDefaultCurrency = true;
      configuration.selectedOverrideCurrencyCode = counterCurrency;
    }
    return CurrencyAlertsBloc(
        currencyAlertRepository: alertRepository,
        currencyRepository: CurrencyRepository.withDependencies(
            currencyDao: currencyDao,
            configurationRepository:
                FakeConfigurationRepository(configuration: configuration),
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
          condition: CurrencyAlertCondition.above,
          counterCurrency: "BRL"));
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

    test('grava a contrapartida em vigor no alerta', () async {
      var bloc = buildBloc(counterCurrency: "EUR");

      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);

      expect(alertRepository.alerts.single.counterCurrency, "EUR");
    });

    test('usa BRL quando nenhuma contrapartida foi escolhida', () async {
      var bloc = buildBloc();

      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);

      expect(alertRepository.alerts.single.counterCurrency, "BRL");
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
      var bloc = buildBloc(quotedRate: 5.5);
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);

      await bloc.checkAlerts(
          notificationTitle: "Alerta",
          notificationBody: (alert, value) =>
              "${alert.currencyCode} ${value.toStringAsFixed(2)}");

      expect(alertRepository.alerts.single.triggered, isTrue);
      expect(notificationService.shown, hasLength(1));
      expect(notificationService.shown.single['title'], "Alerta");
      expect(notificationService.shown.single['body'], "USD 5.50");
    });

    test('avisa a cotação na mesma convenção da tela, e não o seu inverso',
        () async {
      var bloc = buildBloc(quotedRate: 5.5);
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);
      double? reportedValue;

      await bloc.checkAlerts(
          notificationTitle: "Alerta",
          notificationBody: (alert, value) {
            reportedValue = value;
            return "";
          });

      expect(reportedValue, closeTo(5.5, 0.0001));
    });

    test('não dispara "abaixo de" com a cotação acima do alvo', () async {
      // O valor guardado para uma cotação de 5,50 é 0,1818: comparar direto com
      // ele faria este alerta disparar na hora, com a relação invertida.
      var bloc = buildBloc(quotedRate: 5.5);
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.below);

      await bloc.checkAlerts(
          notificationTitle: "Alerta", notificationBody: (alert, value) => "");

      expect(alertRepository.alerts.single.triggered, isFalse);
      expect(notificationService.shown, isEmpty);
    });

    test('não dispara quando a condição não é atendida', () async {
      var bloc = buildBloc(quotedRate: 4.0);
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);

      await bloc.checkAlerts(
          notificationTitle: "Alerta", notificationBody: (alert, value) => "");

      expect(alertRepository.alerts.single.triggered, isFalse);
      expect(notificationService.shown, isEmpty);
    });

    test('confere o alerta contra a contrapartida que ele guarda, e não contra a '
        'escolhida nas configurações', () async {
      // O alerta nasceu frente ao real; depois disso o app passou a cotar em
      // euros. Ler o alvo em euros mudaria o que o alerta quer dizer.
      var bloc = buildBloc(counterCurrency: "EUR");
      alertRepository.alerts.add(CurrencyAlert(
          id: 1,
          currencyCode: "USD",
          targetValue: 5.0,
          condition: CurrencyAlertCondition.above,
          counterCurrency: "BRL"));

      await bloc.checkAlerts(
          notificationTitle: "Alerta", notificationBody: (alert, value) => "");

      expect(currencyDao.latestDataCounterCurrencies, ["BRL"]);
    });

    test('consulta um par por vez quando os alertas têm contrapartidas '
        'diferentes', () async {
      var bloc = buildBloc();
      currencyDao.latestCurrencyByPair.addAll({
        // Frente ao real o dólar já passou do alvo; frente ao euro, não.
        "USD-BRL": storedQuote(5.5),
        "USD-EUR": storedQuote(0.9),
      });
      alertRepository.alerts.addAll([
        CurrencyAlert(
            id: 1,
            currencyCode: "USD",
            targetValue: 5.0,
            condition: CurrencyAlertCondition.above,
            counterCurrency: "BRL"),
        CurrencyAlert(
            id: 2,
            currencyCode: "USD",
            targetValue: 5.0,
            condition: CurrencyAlertCondition.above,
            counterCurrency: "EUR"),
      ]);

      await bloc.checkAlerts(
          notificationTitle: "Alerta",
          notificationBody: (alert, value) =>
              "${alert.currencyCode} ${value.toStringAsFixed(2)} "
              "${alert.counterCurrency}");

      expect(currencyDao.latestDataCounterCurrencies.toSet(), {"BRL", "EUR"});
      expect(notificationService.shown, hasLength(1));
      expect(notificationService.shown.single['body'], "USD 5.50 BRL");
      expect(alertRepository.alerts.firstWhere((a) => a.id == 1).triggered,
          isTrue);
      expect(alertRepository.alerts.firstWhere((a) => a.id == 2).triggered,
          isFalse);
    });

    test('consulta o par uma única vez quando vários alertas o compartilham',
        () async {
      var bloc = buildBloc(quotedRate: 4.0);
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);
      await bloc.addAlert("USD", 6.0, CurrencyAlertCondition.above);

      await bloc.checkAlerts(
          notificationTitle: "Alerta", notificationBody: (alert, value) => "");

      expect(currencyDao.latestDataCounterCurrencies, ["BRL"]);
    });

    test('ignora alertas já disparados', () async {
      var bloc = buildBloc(quotedRate: 5.5);
      await bloc.addAlert("USD", 5.0, CurrencyAlertCondition.above);
      alertRepository.alerts.single.triggered = true;

      await bloc.checkAlerts(
          notificationTitle: "Alerta", notificationBody: (alert, value) => "");

      expect(notificationService.shown, isEmpty);
    });

    test('ignora alertas inativos', () async {
      var bloc = buildBloc(quotedRate: 5.5);
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
