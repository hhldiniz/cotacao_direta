import 'dart:ui';

import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:sprintf/sprintf.dart';

/// Texto da notificação de um alerta atingido.
///
/// Fica aqui, e não em cada chamador, porque a checagem acontece em dois
/// lugares — a tela inicial, com o app aberto, e a tarefa de segundo plano do
/// Android — e o aviso precisa sair igual nos dois. A cotação vai com a
/// contrapartida do próprio alerta: "USD atingiu 5,5000" fica ambíguo para
/// quem cadastrou alertas frente a moedas diferentes.
String currencyAlertNotificationBody(
        MyAppLocalizations localization, CurrencyAlert alert, double value) =>
    sprintf(localization.currencyAlertNotificationBody!, [
      alert.currencyCode,
      "${value.toStringAsFixed(4)} ${alert.counterCurrency}"
    ]);

/// Idioma da notificação disparada fora da interface.
///
/// Sem árvore de widgets não há [MyAppLocalizations.of], então a escolha é
/// refeita aqui do mesmo jeito que o MaterialApp faz: vale o idioma gravado
/// nas configurações e, quando ele está vazio ("seguir o aparelho"), o do
/// próprio aparelho.
Future<Locale> resolveBackgroundLocale(
    {ConfigurationRepository? configurationRepository,
    Locale? deviceLocale}) async {
  var configuration =
      await (configurationRepository ?? ConfigurationRepository())
          .getConfiguration();
  var chosen = AppLocales.localeFor(configuration.languageCode);
  if (chosen != null) return chosen;
  return AppLocales.resolve(deviceLocale ?? PlatformDispatcher.instance.locale) ??
      AppLocales.supported.first;
}

/// Confere os alertas uma vez, fora da interface, e notifica os que já foram
/// atingidos.
///
/// É o corpo da tarefa periódica do Android. Mora fora do arquivo do plugin
/// para poder ser exercitado nos testes sem WorkManager: o que interessa aqui
/// — o idioma escolhido e o texto do aviso — não depende de quem agendou a
/// execução.
Future<void> runBackgroundAlertCheck(
    {CurrencyAlertsBloc? alertsBloc,
    ConfigurationRepository? configurationRepository,
    Locale? deviceLocale}) async {
  var bloc = alertsBloc ?? CurrencyAlertsBloc();
  try {
    var localization = MyAppLocalizations(await resolveBackgroundLocale(
        configurationRepository: configurationRepository,
        deviceLocale: deviceLocale));
    await bloc.checkAlerts(
        notificationTitle: localization.currencyAlertNotificationTitle!,
        notificationBody: (alert, value) =>
            currencyAlertNotificationBody(localization, alert, value));
  } finally {
    // Só descarta o que foi criado aqui: um bloc recebido pronto pertence a
    // quem o passou (nos testes, ao próprio teste).
    if (alertsBloc == null) bloc.dispose();
  }
}
