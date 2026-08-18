import 'dart:ui';

import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:cotacao_direta/util/background_alert_check.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeCurrencyAlertRepository alertRepository;
  late FakeCurrencyDao currencyDao;
  late FakeNotificationService notificationService;

  /// Guarda a cotação já na convenção do banco (o inverso da que o usuário vê,
  /// ver CurrencyRepository).
  CurrencyAlertsBloc buildBloc(
      {double quotedRate = 5.5, required Configuration configuration}) {
    currencyDao.latestCurrency = Currency(
        id: "USD",
        value: 1 / quotedRate,
        historicalDate: DateTime.now().toIso8601String(),
        timestamp: DateTime.now().toIso8601String(),
        friendlyName: "Dólar dos Estados Unidos");
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

  group('currencyAlertNotificationBody', () {
    test('leva a cotação junto da contrapartida do alerta', () {
      var body = currencyAlertNotificationBody(
          MyAppLocalizations(const Locale("pt")),
          CurrencyAlert(
              currencyCode: "USD",
              targetValue: 5.0,
              condition: CurrencyAlertCondition.above,
              counterCurrency: "BRL"),
          5.5);

      expect(body, "USD atingiu 5.5000 BRL");
    });
  });

  group('resolveBackgroundLocale', () {
    test('usa o idioma escolhido nas configurações', () async {
      var locale = await resolveBackgroundLocale(
          configurationRepository: FakeConfigurationRepository(
              configuration: Configuration(1, languageCode: "en")),
          deviceLocale: const Locale("pt"));

      expect(locale, const Locale("en"));
    });

    test('segue o aparelho quando nenhum idioma foi escolhido', () async {
      var locale = await resolveBackgroundLocale(
          configurationRepository: FakeConfigurationRepository(
              configuration: Configuration(1, languageCode: "")),
          deviceLocale: const Locale("pt"));

      expect(locale, const Locale("pt"));
    });

    test('resolve a variante de espanhol pela região do aparelho', () async {
      var locale = await resolveBackgroundLocale(
          configurationRepository: FakeConfigurationRepository(
              configuration: Configuration(1)),
          deviceLocale: const Locale("es", "MX"));

      expect(locale, const Locale("es", "419"));
    });

    test('cai no primeiro idioma da build quando o do aparelho não está nela',
        () async {
      var locale = await resolveBackgroundLocale(
          configurationRepository: FakeConfigurationRepository(
              configuration: Configuration(1)),
          deviceLocale: const Locale("de"));

      expect(locale, AppLocales.supported.first);
    });
  });

  group('runBackgroundAlertCheck', () {
    test('notifica o alerta atingido no idioma escolhido', () async {
      var configuration = Configuration(1, languageCode: "pt");
      var bloc = buildBloc(quotedRate: 5.5, configuration: configuration);
      alertRepository.alerts.add(CurrencyAlert(
          id: 1,
          currencyCode: "USD",
          targetValue: 5.0,
          condition: CurrencyAlertCondition.above,
          counterCurrency: "BRL"));

      await runBackgroundAlertCheck(
          alertsBloc: bloc,
          configurationRepository:
              FakeConfigurationRepository(configuration: configuration),
          deviceLocale: const Locale("en"));

      expect(notificationService.shown, hasLength(1));
      expect(notificationService.shown.single['title'], "Alerta de câmbio");
      expect(notificationService.shown.single['body'], "USD atingiu 5.5000 BRL");
      expect(alertRepository.alerts.single.triggered, isTrue);
      bloc.dispose();
    });

    test('não notifica quando nenhum alvo foi atingido', () async {
      var configuration = Configuration(1);
      var bloc = buildBloc(quotedRate: 4.0, configuration: configuration);
      alertRepository.alerts.add(CurrencyAlert(
          id: 1,
          currencyCode: "USD",
          targetValue: 5.0,
          condition: CurrencyAlertCondition.above,
          counterCurrency: "BRL"));

      await runBackgroundAlertCheck(
          alertsBloc: bloc,
          configurationRepository:
              FakeConfigurationRepository(configuration: configuration),
          deviceLocale: const Locale("pt"));

      expect(notificationService.shown, isEmpty);
      expect(alertRepository.alerts.single.triggered, isFalse);
      bloc.dispose();
    });
  });
}
