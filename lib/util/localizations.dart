import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Os idiomas que entram na build do aplicativo.
///
/// É a mesma lista que o MaterialApp declara em supportedLocales, que o
/// [MyAppLocalizationsDelegate] aceita e que a tela de opções oferece: com uma
/// fonte única, acrescentar uma tradução ao mapa de textos é o bastante para
/// ela aparecer nas três pontas.
///
/// O espanhol entra em duas traduções, uma para cada norma: a da Espanha e a
/// da América Latina — es-419, o código que o CLDR usa para a região. Por isso
/// um idioma é identificado pela etiqueta inteira ("es-ES", "es-419"), e não
/// só pelo código do idioma.
class AppLocales {
  static const List<Locale> supported = [
    Locale("en"),
    Locale("pt"),
    Locale("es", "ES"),
    Locale("es", "419"),
  ];

  /// Nome de cada idioma escrito nele mesmo. Quem está com o app em um idioma
  /// que não entende precisa reconhecer o seu na lista para conseguir voltar,
  /// então estes nomes não são traduzidos.
  static const Map<String, String> displayNames = {
    "en": "English",
    "pt": "Português",
    "es-ES": "Español (España)",
    "es-419": "Español (Latinoamérica)",
  };

  /// Os países de língua espanhola que seguem a norma da Espanha; o resto do
  /// mundo hispanofalante fica com a tradução latino-americana. São os mesmos
  /// que o CLDR pendura em "es" em vez de em "es-419".
  static const Set<String> _europeanSpanishCountries = {"ES", "GQ", "PH"};

  /// A etiqueta de um idioma da build: o código do idioma, mais a região
  /// quando ela separa duas traduções ("es-ES", "es-419").
  static String tagOf(Locale locale) {
    var countryCode = locale.countryCode;
    if (countryCode == null || countryCode.isEmpty) return locale.languageCode;
    return "${locale.languageCode}-$countryCode";
  }

  /// A etiqueta canônica do que está gravado nas configurações, ou vazio
  /// quando não é um idioma desta build — o que inclui o valor vazio, que
  /// significa "seguir o aparelho".
  ///
  /// O banco guarda o texto em caixa baixa, e a etiqueta pode chegar com "_"
  /// no lugar do "-" de quem a montou a partir de um Locale, então a
  /// comparação não depende nem da caixa nem do separador.
  static String tagFor(String? storedTag) {
    if (storedTag == null) return "";
    var normalized = storedTag.trim().toLowerCase().replaceAll("_", "-");
    if (normalized.isEmpty) return "";
    for (var locale in supported) {
      if (tagOf(locale).toLowerCase() == normalized) return tagOf(locale);
    }
    return "";
  }

  static bool isSupported(String? storedTag) => tagFor(storedTag).isNotEmpty;

  /// O idioma gravado nas configurações como [Locale], ou nulo para seguir o
  /// aparelho — o que também vale para uma etiqueta que esta build não tem,
  /// caso o app seja instalado por cima de uma versão com mais traduções.
  static Locale? localeFor(String? storedTag) {
    var tag = tagFor(storedTag);
    if (tag.isEmpty) return null;
    return supported.firstWhere((locale) => tagOf(locale) == tag);
  }

  /// O idioma da build que atende [locale], ou nulo quando nenhum atende.
  ///
  /// Comparar o código do idioma não basta desde que existem duas traduções em
  /// espanhol: o aparelho chega aqui como es-MX, es-AR, es-US… e nenhum deles
  /// é igual a uma das duas. Sem região, ou em um país que segue a norma
  /// europeia, vale a tradução da Espanha; o resto fica com a
  /// latino-americana.
  static Locale? resolve(Locale? locale) {
    if (locale == null) return null;
    for (var supportedLocale in supported) {
      if (supportedLocale == locale) return supportedLocale;
    }
    if (locale.languageCode == "es") {
      var countryCode = locale.countryCode?.toUpperCase() ?? "";
      return countryCode.isEmpty ||
              _europeanSpanishCountries.contains(countryCode)
          ? const Locale("es", "ES")
          : const Locale("es", "419");
    }
    for (var supportedLocale in supported) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }
    return null;
  }

  /// O idioma a usar entre os que o aparelho pede, na ordem de preferência
  /// dele, com o primeiro da build como reserva — o mesmo que o Flutter faz
  /// quando nada corresponde.
  ///
  /// Vai no localeListResolutionCallback do MaterialApp: a escolha padrão do
  /// Flutter, sem país correspondente, daria a primeira variante de espanhol
  /// da lista para todo mundo, isto é, a da Espanha também para quem está no
  /// México.
  static Locale resolveDeviceLocales(
      List<Locale>? deviceLocales, Iterable<Locale> supportedLocales) {
    for (var deviceLocale in deviceLocales ?? const <Locale>[]) {
      var resolved = resolve(deviceLocale);
      if (resolved != null) return resolved;
    }
    return supportedLocales.first;
  }

  /// O nome a mostrar para uma etiqueta de idioma, com a própria etiqueta como
  /// último recurso.
  static String displayNameOf(String tag) => displayNames[tagFor(tag)] ?? tag;
}

class MyAppLocalizations {
  MyAppLocalizations(this.locale) : _values = _valuesFor(locale);

  final Locale locale;

  /// Os textos do idioma resolvido, guardados na construção: os getters são
  /// muitos e são lidos a cada quadro, e o locale de uma instância não muda.
  final Map<String, String> _values;

  static MyAppLocalizations? of(BuildContext context) {
    return Localizations.of<MyAppLocalizations>(context, MyAppLocalizations);
  }

  /// Os textos do idioma da build que atende [locale]. Um idioma que não está
  /// na build cai no primeiro da lista, em vez de deixar a interface sem
  /// nenhum texto — o delegate não carrega um locale desses, mas a classe
  /// também é construída direto nos testes.
  static Map<String, String> _valuesFor(Locale locale) {
    var resolved = AppLocales.resolve(locale) ?? AppLocales.supported.first;
    return _localizedValues[AppLocales.tagOf(resolved)]!;
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'conversionButtonLabel': 'Conversions',
      'conversionPageTitle': "Currency Conversion",
      'homePageHeadsUpText': 'Exchange rates in %s',
      'homeReorderHintLabel': 'Press and hold a quote to rearrange the grid.',
      'homeReorderMoveEarlierLabel': 'Move one position back',
      'homeReorderMoveLaterLabel': 'Move one position forward',
      'conversionMultiplierHint': 'Amount',
      'conversionPageExplanationText': 'Insert the amount value of the currency '
          'that will be converted, selected a currency to be converted and the '
          'currency that it will be converted to.',
      'conversionFromLabel': 'From',
      'conversionToLabel': 'To',
      'conversionSwapTooltip': 'Swap currencies',
      'conversionClearAmountTooltip': 'Clear amount',
      'conversionInvalidAmountError': 'Enter a valid amount',
      'conversionCurrencyPickerTitle': 'Choose a currency',
      'conversionCurrencySearchHint': 'Search by name or code',
      'conversionCurrencyNotFoundLabel': 'No currency found',
      'conversionCurrencyPickerYoursLabel': 'Your currencies',
      'conversionCurrencyPickerOthersLabel': 'All currencies',
      'conversionRateUnavailableLabel': 'Exchange rate unavailable',
      'conversionCopyResultTooltip': 'Copy result',
      'conversionResultCopiedLabel': 'Result copied',
      'conversionHistorySectionLabel': 'Last %s days',
      'conversionHistoryUnavailableLabel': 'No history for this period',
      'mainCurrenciesBottomNavItemLabel': 'Currencies',
      'currencyHistoryBottomNavItemLabel': 'History',
      'configBottomNavItemLabel': 'Options',
      'aboutBottomNavItemLabel': 'About',
      'currencyHistoryFromDateLabel': 'From',
      'currencyHistoryToDateLabel': 'Until',
      'currencyHistoryCurrenciesSectionLabel': 'Currencies',
      'currencyHistoryCryptocurrenciesSectionLabel': 'Cryptocurrencies',
      'noDataLabel': 'No Data',
      'getCurrencyHistoryBtnLabel': 'Get history',
      'currencyHistoryPeriodOptionLabel': '%s days',
      'overrideDefaultCurrencySwitchLabel': 'Override default currency',
      'selectedOverrideCurrencyLabel': 'Currency',
      'homeCurrenciesSettingLabel': 'Quotes on the home screen',
      'homeCurrenciesPickerTitle': 'Quotes shown as bubbles',
      'homeCurrenciesPickerDescription':
          'The first currency chosen gets the big bubble.',
      'homeCurrenciesSelectedCountLabel': '%s selected',
      'homeCurrenciesEmptySelectionLabel': 'Choose at least one currency',
      'homeCurrenciesSaveBtnLabel': 'Save',
      'appLanguageSettingLabel': 'App language',
      'appLanguageSystemOptionLabel': 'System language',
      'appConfigurationsSectionLabel': 'App Configurations',
      'pwaInstallSectionLabel': 'Install on this device',
      'pwaInstallCardLabel': 'Install app',
      'pwaInstallCardDescription':
          'Add Cotação Direta to your device and open it from its own icon, '
          'without the browser bar.',
      'pwaInstallBtnLabel': 'Install',
      'pwaInstallIosCardDescription':
          'On iPhone and iPad the app is installed from the Safari share menu.',
      'pwaInstallIosBtnLabel': 'How to install',
      'pwaInstallIosDialogTitle': 'Add to Home Screen',
      'pwaInstallIosDialogBody':
          'In Safari, tap the share button at the bottom of the screen, choose '
          '"Add to Home Screen" and confirm. Cotação Direta then shows up '
          'among your apps.',
      'pwaInstallIosDialogCloseBtnLabel': 'Got it',
      'pwaInstallAcceptedLabel': 'App installed',
      'pwaInstallDismissedLabel': 'Installation cancelled',
      'aboutAppDescription': 'A simple app that shows the exchange rate of '
          'the main currencies against the Brazilian real.',
      'aboutVersionLabel': 'Version',
      'aboutDeveloperLabel': 'Developed by',
      'aboutSourceCodeLabel': 'Source code',
      'currencyAlertsBottomNavItemLabel': 'Alerts',
      'currencyAlertsSectionLabel': 'Exchange rate alerts',
      'currencyAlertEmptyListLabel':
          'No alerts yet. Tap the button below to create one.',
      'addCurrencyAlertBtnLabel': 'New alert',
      'addCurrencyAlertDialogTitle': 'New exchange rate alert',
      'currencyAlertCurrencyLabel': 'Currency',
      'currencyAlertConditionLabel': 'Condition',
      'currencyAlertConditionAbove': 'Rises above',
      'currencyAlertConditionBelow': 'Falls below',
      'currencyAlertTargetValueLabel': 'Target value',
      'currencyAlertInvalidValueError': 'Enter a valid value',
      'currencyAlertSaveBtnLabel': 'Save',
      'currencyAlertCancelBtnLabel': 'Cancel',
      'currencyAlertTriggeredLabel': 'Triggered',
      'currencyAlertActiveLabel': 'Waiting',
      'currencyAlertDeleteTooltip': 'Delete',
      'currencyAlertNotificationTitle': 'Exchange rate alert',
      'currencyAlertNotificationBody': '%s reached %s',
      'notificationPermissionCardLabel': 'Alert notifications',
      'notificationPermissionCardDescription':
          'Allow notifications to be told when an alert is reached. Alerts '
              'are checked while the app is open.',
      'notificationPermissionBtnLabel': 'Allow',
      'notificationPermissionDeniedDescription':
          'Notifications are blocked. Allow them again in this browser\'s '
              'site settings to be told when an alert is reached.',
      'notificationPermissionIosDescription':
          'On iPhone and iPad notifications only work with the app added to '
              'the Home Screen. Install it from the Safari share menu and '
              'open it from its icon.',
      'notificationPermissionGrantedLabel': 'Notifications enabled',
      'notificationPermissionRefusedLabel': 'Notifications not enabled',
      'aiInsightsBottomNavItemLabel': 'AI',
      'aiInsightsSectionLabel': 'On-device AI insights',
      'aiInsightsDescription': 'A small neural network is trained on this '
          'device, over the quotes the app already downloaded, to summarise the '
          'market and project the coming days. No data leaves your phone.',
      'aiInsightsAssetLabel': 'Asset',
      'aiInsightsAssetPickerTitle': 'Choose an asset',
      'aiInsightsAssetNotFoundLabel': 'No asset found',
      'aiInsightsHorizonLabel': 'Projection horizon',
      'aiInsightsHorizonOptionLabel': '%s days',
      'aiInsightsAmountLabel': 'Amount to simulate (optional)',
      'aiInsightsAnalyzeBtnLabel': 'Analyse on device',
      'aiInsightsRunningLabel': 'Training the local model…',
      'aiInsightsEmptyLabel': 'Choose an asset and run the analysis.',
      'aiInsightsNoDataError': 'No quotes found for this asset.',
      'aiInsightsInsufficientDataError':
          'Not enough history to analyse this asset.',
      'aiInsightsFailureError': 'The analysis could not be completed.',
      'aiInsightsSummarySectionLabel': 'Market summary',
      'aiInsightsProjectionSectionLabel': 'Projection',
      'aiInsightsInsightsSectionLabel': 'Insights',
      'aiInsightsModelSectionLabel': 'Local model',
      'aiInsightsLastPriceLabel': 'Latest quote',
      'aiInsightsWeeklyChangeLabel': '7-day change',
      'aiInsightsMonthlyChangeLabel': '30-day change',
      'aiInsightsVolatilityLabel': 'Annualised volatility',
      'aiInsightsRsiLabel': 'Momentum (RSI 14)',
      'aiInsightsDrawdownLabel': 'Largest drop',
      'aiInsightsTrendLabel': 'Annualised trend',
      'aiInsightsTrendFitLabel': 'Trend fit (R²)',
      'aiInsightsProjectedPriceLabel': 'Projected quote in %s days',
      'aiInsightsProjectedChangeLabel': 'Projected change',
      'aiInsightsConfidenceBandLabel': 'Range at %s confidence',
      'aiInsightsAmountProjectionLabel': 'Simulated amount',
      'aiInsightsAmountProjectionHint': '%s invested today',
      'aiInsightsModelSamplesLabel': 'Training windows',
      'aiInsightsModelSkillLabel': 'Edge over random walk',
      'aiInsightsModelEpochsLabel': 'Epochs',
      'aiInsightsModelUntrainedLabel':
          'Short history: the projection uses the statistical baseline only.',
      'aiInsightsDisclaimerLabel': 'Estimates calculated on your device from '
          'past quotes. Not investment advice.',
      'aiInsightsChartHistoryLabel': 'History',
      'aiInsightsChartProjectionLabel': 'Projection',
      'aiInsightTrendUp': 'Uptrend: %s over the last %s days.',
      'aiInsightTrendDown': 'Downtrend: %s over the last %s days.',
      'aiInsightTrendSideways': 'No clear trend: %s over the last %s days.',
      'aiInsightMomentumOverbought':
          'Stretched momentum: RSI at %s, in overbought territory.',
      'aiInsightMomentumOversold':
          'Pressured momentum: RSI at %s, in oversold territory.',
      'aiInsightMomentumNeutral': 'Balanced momentum: RSI at %s.',
      'aiInsightVolatilityHigh':
          'High volatility: %s a year, so the projection carries a wide range.',
      'aiInsightVolatilityLow': 'Low volatility: %s a year.',
      'aiInsightProjectionUp':
          'The model projects a %s rise in %s days, to %s.',
      'aiInsightProjectionDown':
          'The model projects a %s drop in %s days, to %s.',
      'aiInsightProjectionStable':
          'The model projects stability over %s days, around %s.',
      'aiInsightDrawdown':
          'The asset fell %s from its peak in the analysed period.',
      'aiInsightConfidenceGood':
          'The network beat the random walk by %s in validation.',
      'aiInsightConfidenceLow': 'The network did not beat the random walk on '
          'this history, so the projection follows the statistical baseline.',
      'aiInsightDataLimited': 'Short history (%s windows): the projection uses '
          'the statistical baseline only.',
    },
    'pt': {
      'conversionButtonLabel': "Conversões",
      'conversionPageTitle': "Conversão de Moedas",
      'homePageHeadsUpText': "Cotações em %s",
      'homeReorderHintLabel':
          'Segure uma cotação para reorganizar a grade.',
      'homeReorderMoveEarlierLabel': 'Mover uma posição para trás',
      'homeReorderMoveLaterLabel': 'Mover uma posição para frente',
      'conversionMultiplierHint': 'Quantidade',
      'conversionPageExplanationText': 'Insira a quantidade da moeda que será '
          'convertida, selecionada a moeda que será convertida e a moeda para '
          'a qual será feita a conversão.',
      'conversionFromLabel': 'De',
      'conversionToLabel': 'Para',
      'conversionSwapTooltip': 'Inverter as moedas',
      'conversionClearAmountTooltip': 'Limpar a quantidade',
      'conversionInvalidAmountError': 'Informe um valor válido',
      'conversionCurrencyPickerTitle': 'Escolha a moeda',
      'conversionCurrencySearchHint': 'Busque pelo nome ou código',
      'conversionCurrencyNotFoundLabel': 'Nenhuma moeda encontrada',
      'conversionCurrencyPickerYoursLabel': 'Suas moedas',
      'conversionCurrencyPickerOthersLabel': 'Todas as moedas',
      'conversionRateUnavailableLabel': 'Cotação indisponível',
      'conversionCopyResultTooltip': 'Copiar o resultado',
      'conversionResultCopiedLabel': 'Resultado copiado',
      'conversionHistorySectionLabel': 'Últimos %s dias',
      'conversionHistoryUnavailableLabel': 'Sem histórico para o período',
      'mainCurrenciesBottomNavItemLabel': 'Moedas',
      'currencyHistoryBottomNavItemLabel': 'Histórico',
      'configBottomNavItemLabel': 'Opções',
      'aboutBottomNavItemLabel': 'Sobre',
      'currencyHistoryFromDateLabel': 'De',
      'currencyHistoryToDateLabel': 'Até',
      'currencyHistoryCurrenciesSectionLabel': 'Moedas',
      'currencyHistoryCryptocurrenciesSectionLabel': 'Criptomoedas',
      'noDataLabel': 'Sem Dados',
      'getCurrencyHistoryBtnLabel': 'Obter histórico',
      'currencyHistoryPeriodOptionLabel': '%s dias',
      'overrideDefaultCurrencySwitchLabel': 'Sobrescrever moeda padrão',
      'selectedOverrideCurrencyLabel': 'Moeda',
      'homeCurrenciesSettingLabel': 'Cotações na tela inicial',
      'homeCurrenciesPickerTitle': 'Cotações mostradas em bolhas',
      'homeCurrenciesPickerDescription':
          'A primeira moeda escolhida fica na bolha de destaque.',
      'homeCurrenciesSelectedCountLabel': '%s escolhidas',
      'homeCurrenciesEmptySelectionLabel': 'Escolha pelo menos uma moeda',
      'homeCurrenciesSaveBtnLabel': 'Salvar',
      'appLanguageSettingLabel': 'Idioma do aplicativo',
      'appLanguageSystemOptionLabel': 'Idioma do sistema',
      'appConfigurationsSectionLabel': 'Configurações do Aplicativo',
      'pwaInstallSectionLabel': 'Instalar no aparelho',
      'pwaInstallCardLabel': 'Instalar aplicativo',
      'pwaInstallCardDescription':
          'Adicione o Cotação Direta ao seu aparelho e abra pelo ícone dele, '
          'sem a barra do navegador.',
      'pwaInstallBtnLabel': 'Instalar',
      'pwaInstallIosCardDescription':
          'No iPhone e no iPad a instalação é feita pelo menu de compartilhar '
          'do Safari.',
      'pwaInstallIosBtnLabel': 'Como instalar',
      'pwaInstallIosDialogTitle': 'Adicionar à Tela de Início',
      'pwaInstallIosDialogBody':
          'No Safari, toque no botão de compartilhar, na parte de baixo da '
          'tela, escolha "Adicionar à Tela de Início" e confirme. O Cotação '
          'Direta passa a aparecer junto dos seus aplicativos.',
      'pwaInstallIosDialogCloseBtnLabel': 'Entendi',
      'pwaInstallAcceptedLabel': 'Aplicativo instalado',
      'pwaInstallDismissedLabel': 'Instalação cancelada',
      'aboutAppDescription': 'Um aplicativo simples que mostra a cotação das '
          'principais moedas frente ao real.',
      'aboutVersionLabel': 'Versão',
      'aboutDeveloperLabel': 'Desenvolvido por',
      'aboutSourceCodeLabel': 'Código fonte',
      'currencyAlertsBottomNavItemLabel': 'Alertas',
      'currencyAlertsSectionLabel': 'Alertas de câmbio',
      'currencyAlertEmptyListLabel':
          'Nenhum alerta cadastrado. Toque no botão abaixo para criar um.',
      'addCurrencyAlertBtnLabel': 'Novo alerta',
      'addCurrencyAlertDialogTitle': 'Novo alerta de câmbio',
      'currencyAlertCurrencyLabel': 'Moeda',
      'currencyAlertConditionLabel': 'Condição',
      'currencyAlertConditionAbove': 'Subir acima de',
      'currencyAlertConditionBelow': 'Cair abaixo de',
      'currencyAlertTargetValueLabel': 'Valor alvo',
      'currencyAlertInvalidValueError': 'Informe um valor válido',
      'currencyAlertSaveBtnLabel': 'Salvar',
      'currencyAlertCancelBtnLabel': 'Cancelar',
      'currencyAlertTriggeredLabel': 'Disparado',
      'currencyAlertActiveLabel': 'Aguardando',
      'currencyAlertDeleteTooltip': 'Excluir',
      'currencyAlertNotificationTitle': 'Alerta de câmbio',
      'currencyAlertNotificationBody': '%s atingiu %s',
      'notificationPermissionCardLabel': 'Notificações dos alertas',
      'notificationPermissionCardDescription':
          'Permita as notificações para ser avisado quando um alerta for '
              'atingido. Os alertas são conferidos enquanto o app está aberto.',
      'notificationPermissionBtnLabel': 'Permitir',
      'notificationPermissionDeniedDescription':
          'As notificações estão bloqueadas. Libere-as nas configurações do '
              'site, neste navegador, para voltar a ser avisado quando um '
              'alerta for atingido.',
      'notificationPermissionIosDescription':
          'No iPhone e no iPad as notificações só funcionam com o app '
              'adicionado à Tela de Início. Instale-o pelo menu Compartilhar '
              'do Safari e abra pelo ícone.',
      'notificationPermissionGrantedLabel': 'Notificações ativadas',
      'notificationPermissionRefusedLabel': 'Notificações não ativadas',
      'aiInsightsBottomNavItemLabel': 'IA',
      'aiInsightsSectionLabel': 'Insights com IA no aparelho',
      'aiInsightsDescription': 'Uma rede neural pequena é treinada neste '
          'aparelho, sobre as cotações que o app já baixou, para resumir o '
          'mercado e projetar os próximos dias. Nenhum dado sai do seu celular.',
      'aiInsightsAssetLabel': 'Ativo',
      'aiInsightsAssetPickerTitle': 'Escolha o ativo',
      'aiInsightsAssetNotFoundLabel': 'Nenhum ativo encontrado',
      'aiInsightsHorizonLabel': 'Horizonte da projeção',
      'aiInsightsHorizonOptionLabel': '%s dias',
      'aiInsightsAmountLabel': 'Valor para simular (opcional)',
      'aiInsightsAnalyzeBtnLabel': 'Analisar no aparelho',
      'aiInsightsRunningLabel': 'Treinando o modelo local…',
      'aiInsightsEmptyLabel': 'Escolha um ativo e rode a análise.',
      'aiInsightsNoDataError': 'Nenhuma cotação encontrada para este ativo.',
      'aiInsightsInsufficientDataError':
          'Histórico insuficiente para analisar este ativo.',
      'aiInsightsFailureError': 'Não foi possível concluir a análise.',
      'aiInsightsSummarySectionLabel': 'Resumo do mercado',
      'aiInsightsProjectionSectionLabel': 'Projeção',
      'aiInsightsInsightsSectionLabel': 'Insights',
      'aiInsightsModelSectionLabel': 'Modelo local',
      'aiInsightsLastPriceLabel': 'Cotação atual',
      'aiInsightsWeeklyChangeLabel': 'Variação em 7 dias',
      'aiInsightsMonthlyChangeLabel': 'Variação em 30 dias',
      'aiInsightsVolatilityLabel': 'Volatilidade anualizada',
      'aiInsightsRsiLabel': 'Momento (IFR 14)',
      'aiInsightsDrawdownLabel': 'Maior queda',
      'aiInsightsTrendLabel': 'Tendência anualizada',
      'aiInsightsTrendFitLabel': 'Aderência da tendência (R²)',
      'aiInsightsProjectedPriceLabel': 'Cotação projetada em %s dias',
      'aiInsightsProjectedChangeLabel': 'Variação projetada',
      'aiInsightsConfidenceBandLabel': 'Faixa com %s de confiança',
      'aiInsightsAmountProjectionLabel': 'Valor simulado',
      'aiInsightsAmountProjectionHint': '%s aplicados hoje',
      'aiInsightsModelSamplesLabel': 'Janelas de treino',
      'aiInsightsModelSkillLabel': 'Vantagem sobre o passeio aleatório',
      'aiInsightsModelEpochsLabel': 'Épocas',
      'aiInsightsModelUntrainedLabel':
          'Histórico curto: a projeção usa apenas a base estatística.',
      'aiInsightsDisclaimerLabel': 'Estimativas calculadas no seu aparelho a '
          'partir de cotações passadas. Não é recomendação de investimento.',
      'aiInsightsChartHistoryLabel': 'Histórico',
      'aiInsightsChartProjectionLabel': 'Projeção',
      'aiInsightTrendUp': 'Tendência de alta: %s nos últimos %s dias.',
      'aiInsightTrendDown': 'Tendência de baixa: %s nos últimos %s dias.',
      'aiInsightTrendSideways':
          'Sem tendência definida: %s nos últimos %s dias.',
      'aiInsightMomentumOverbought':
          'Momento esticado: IFR em %s, na faixa de sobrecompra.',
      'aiInsightMomentumOversold':
          'Momento pressionado: IFR em %s, na faixa de sobrevenda.',
      'aiInsightMomentumNeutral': 'Momento equilibrado: IFR em %s.',
      'aiInsightVolatilityHigh':
          'Volatilidade alta: %s ao ano, então a projeção tem faixa larga.',
      'aiInsightVolatilityLow': 'Volatilidade baixa: %s ao ano.',
      'aiInsightProjectionUp':
          'O modelo projeta alta de %s em %s dias, para %s.',
      'aiInsightProjectionDown':
          'O modelo projeta queda de %s em %s dias, para %s.',
      'aiInsightProjectionStable':
          'O modelo projeta estabilidade em %s dias, em torno de %s.',
      'aiInsightDrawdown': 'O ativo caiu %s do topo no período analisado.',
      'aiInsightConfidenceGood':
          'A rede superou o passeio aleatório em %s na validação.',
      'aiInsightConfidenceLow': 'A rede não superou o passeio aleatório neste '
          'histórico, então a projeção segue a base estatística.',
      'aiInsightDataLimited': 'Histórico curto (%s janelas): a projeção usa '
          'apenas a base estatística.',
    },
    // O espanhol da Espanha. A diferença para o de baixo é de vocabulário —
    // "ajustes" e "móvil" aqui, "configuración" e "celular" lá — e do tempo
    // verbal do passado, que na Espanha costuma ser composto.
    'es-ES': {
      'conversionButtonLabel': 'Conversiones',
      'conversionPageTitle': 'Conversión de divisas',
      'homePageHeadsUpText': 'Cotizaciones en %s',
      'homeReorderHintLabel':
          'Mantén pulsada una cotización para reorganizar la cuadrícula.',
      'homeReorderMoveEarlierLabel': 'Mover una posición hacia atrás',
      'homeReorderMoveLaterLabel': 'Mover una posición hacia delante',
      'conversionMultiplierHint': 'Cantidad',
      'conversionPageExplanationText': 'Introduce la cantidad de la divisa que '
          'se va a convertir, elige esa divisa y la divisa a la que quieres '
          'convertirla.',
      'conversionFromLabel': 'De',
      'conversionToLabel': 'A',
      'conversionSwapTooltip': 'Invertir las divisas',
      'conversionClearAmountTooltip': 'Borrar la cantidad',
      'conversionInvalidAmountError': 'Introduce un valor válido',
      'conversionCurrencyPickerTitle': 'Elige una divisa',
      'conversionCurrencySearchHint': 'Busca por nombre o código',
      'conversionCurrencyNotFoundLabel': 'No se ha encontrado ninguna divisa',
      'conversionCurrencyPickerYoursLabel': 'Tus divisas',
      'conversionCurrencyPickerOthersLabel': 'Todas las divisas',
      'conversionRateUnavailableLabel': 'Cotización no disponible',
      'conversionCopyResultTooltip': 'Copiar el resultado',
      'conversionResultCopiedLabel': 'Resultado copiado',
      'conversionHistorySectionLabel': 'Últimos %s días',
      'conversionHistoryUnavailableLabel': 'Sin historial para el periodo',
      'mainCurrenciesBottomNavItemLabel': 'Divisas',
      'currencyHistoryBottomNavItemLabel': 'Histórico',
      'configBottomNavItemLabel': 'Ajustes',
      'aboutBottomNavItemLabel': 'Acerca de',
      'currencyHistoryFromDateLabel': 'Desde',
      'currencyHistoryToDateLabel': 'Hasta',
      'currencyHistoryCurrenciesSectionLabel': 'Divisas',
      'currencyHistoryCryptocurrenciesSectionLabel': 'Criptomonedas',
      'noDataLabel': 'Sin datos',
      'getCurrencyHistoryBtnLabel': 'Obtener el histórico',
      'currencyHistoryPeriodOptionLabel': '%s días',
      'overrideDefaultCurrencySwitchLabel': 'Sustituir la divisa por defecto',
      'selectedOverrideCurrencyLabel': 'Divisa',
      'homeCurrenciesSettingLabel': 'Cotizaciones en la pantalla de inicio',
      'homeCurrenciesPickerTitle': 'Cotizaciones mostradas en burbujas',
      'homeCurrenciesPickerDescription':
          'La primera divisa elegida ocupa la burbuja destacada.',
      'homeCurrenciesSelectedCountLabel': '%s seleccionadas',
      'homeCurrenciesEmptySelectionLabel': 'Elige al menos una divisa',
      'homeCurrenciesSaveBtnLabel': 'Guardar',
      'appLanguageSettingLabel': 'Idioma de la aplicación',
      'appLanguageSystemOptionLabel': 'Idioma del sistema',
      'appConfigurationsSectionLabel': 'Ajustes de la aplicación',
      'pwaInstallSectionLabel': 'Instalar en este dispositivo',
      'pwaInstallCardLabel': 'Instalar la aplicación',
      'pwaInstallCardDescription':
          'Añade Cotação Direta a tu dispositivo y ábrelo desde su propio '
          'icono, sin la barra del navegador.',
      'pwaInstallBtnLabel': 'Instalar',
      'pwaInstallIosCardDescription':
          'En el iPhone y el iPad la instalación se hace desde el menú de '
          'compartir de Safari.',
      'pwaInstallIosBtnLabel': 'Cómo instalar',
      'pwaInstallIosDialogTitle': 'Añadir a pantalla de inicio',
      'pwaInstallIosDialogBody':
          'En Safari, pulsa el botón de compartir, en la parte inferior de la '
          'pantalla, elige "Añadir a pantalla de inicio" y confirma. Cotação '
          'Direta aparecerá junto a tus aplicaciones.',
      'pwaInstallIosDialogCloseBtnLabel': 'Entendido',
      'pwaInstallAcceptedLabel': 'Aplicación instalada',
      'pwaInstallDismissedLabel': 'Instalación cancelada',
      'aboutAppDescription': 'Una aplicación sencilla que muestra la '
          'cotización de las principales divisas frente al real brasileño.',
      'aboutVersionLabel': 'Versión',
      'aboutDeveloperLabel': 'Desarrollado por',
      'aboutSourceCodeLabel': 'Código fuente',
      'currencyAlertsBottomNavItemLabel': 'Alertas',
      'currencyAlertsSectionLabel': 'Alertas de cambio',
      'currencyAlertEmptyListLabel':
          'Todavía no hay alertas. Pulsa el botón de abajo para crear una.',
      'addCurrencyAlertBtnLabel': 'Nueva alerta',
      'addCurrencyAlertDialogTitle': 'Nueva alerta de cambio',
      'currencyAlertCurrencyLabel': 'Divisa',
      'currencyAlertConditionLabel': 'Condición',
      'currencyAlertConditionAbove': 'Suba por encima de',
      'currencyAlertConditionBelow': 'Baje por debajo de',
      'currencyAlertTargetValueLabel': 'Valor objetivo',
      'currencyAlertInvalidValueError': 'Introduce un valor válido',
      'currencyAlertSaveBtnLabel': 'Guardar',
      'currencyAlertCancelBtnLabel': 'Cancelar',
      'currencyAlertTriggeredLabel': 'Activada',
      'currencyAlertActiveLabel': 'En espera',
      'currencyAlertDeleteTooltip': 'Eliminar',
      'currencyAlertNotificationTitle': 'Alerta de cambio',
      'currencyAlertNotificationBody': '%s ha alcanzado %s',
      'notificationPermissionCardLabel': 'Notificaciones de las alertas',
      'notificationPermissionCardDescription':
          'Permite las notificaciones para saber cuándo se alcanza una '
              'alerta. Las alertas se comprueban mientras la aplicación está '
              'abierta.',
      'notificationPermissionBtnLabel': 'Permitir',
      'notificationPermissionDeniedDescription':
          'Las notificaciones están bloqueadas. Vuelve a permitirlas en los '
              'ajustes del sitio de este navegador para recibir el aviso '
              'cuando se alcance una alerta.',
      'notificationPermissionIosDescription':
          'En el iPhone y el iPad las notificaciones solo funcionan con la '
              'aplicación añadida a la pantalla de inicio. Instálala desde el '
              'menú Compartir de Safari y ábrela desde su icono.',
      'notificationPermissionGrantedLabel': 'Notificaciones activadas',
      'notificationPermissionRefusedLabel': 'Notificaciones no activadas',
      'aiInsightsBottomNavItemLabel': 'IA',
      'aiInsightsSectionLabel': 'Análisis con IA en el dispositivo',
      'aiInsightsDescription': 'Una red neuronal pequeña se entrena en este '
          'dispositivo, con las cotizaciones que la aplicación ya ha '
          'descargado, para resumir el mercado y proyectar los próximos días. '
          'Ningún dato sale de tu móvil.',
      'aiInsightsAssetLabel': 'Activo',
      'aiInsightsAssetPickerTitle': 'Elige un activo',
      'aiInsightsAssetNotFoundLabel': 'No se ha encontrado ningún activo',
      'aiInsightsHorizonLabel': 'Horizonte de la proyección',
      'aiInsightsHorizonOptionLabel': '%s días',
      'aiInsightsAmountLabel': 'Importe a simular (opcional)',
      'aiInsightsAnalyzeBtnLabel': 'Analizar en el dispositivo',
      'aiInsightsRunningLabel': 'Entrenando el modelo local…',
      'aiInsightsEmptyLabel': 'Elige un activo y ejecuta el análisis.',
      'aiInsightsNoDataError':
          'No se han encontrado cotizaciones para este activo.',
      'aiInsightsInsufficientDataError':
          'No hay histórico suficiente para analizar este activo.',
      'aiInsightsFailureError': 'No se ha podido completar el análisis.',
      'aiInsightsSummarySectionLabel': 'Resumen del mercado',
      'aiInsightsProjectionSectionLabel': 'Proyección',
      'aiInsightsInsightsSectionLabel': 'Conclusiones',
      'aiInsightsModelSectionLabel': 'Modelo local',
      'aiInsightsLastPriceLabel': 'Cotización actual',
      'aiInsightsWeeklyChangeLabel': 'Variación en 7 días',
      'aiInsightsMonthlyChangeLabel': 'Variación en 30 días',
      'aiInsightsVolatilityLabel': 'Volatilidad anualizada',
      'aiInsightsRsiLabel': 'Momento (RSI 14)',
      'aiInsightsDrawdownLabel': 'Mayor caída',
      'aiInsightsTrendLabel': 'Tendencia anualizada',
      'aiInsightsTrendFitLabel': 'Ajuste de la tendencia (R²)',
      'aiInsightsProjectedPriceLabel': 'Cotización proyectada en %s días',
      'aiInsightsProjectedChangeLabel': 'Variación proyectada',
      'aiInsightsConfidenceBandLabel': 'Rango con %s de confianza',
      'aiInsightsAmountProjectionLabel': 'Importe simulado',
      'aiInsightsAmountProjectionHint': '%s invertidos hoy',
      'aiInsightsModelSamplesLabel': 'Ventanas de entrenamiento',
      'aiInsightsModelSkillLabel': 'Ventaja sobre el paseo aleatorio',
      'aiInsightsModelEpochsLabel': 'Épocas',
      'aiInsightsModelUntrainedLabel':
          'Histórico corto: la proyección usa solo la base estadística.',
      'aiInsightsDisclaimerLabel': 'Estimaciones calculadas en tu dispositivo '
          'a partir de cotizaciones pasadas. No son una recomendación de '
          'inversión.',
      'aiInsightsChartHistoryLabel': 'Histórico',
      'aiInsightsChartProjectionLabel': 'Proyección',
      'aiInsightTrendUp': 'Tendencia alcista: %s en los últimos %s días.',
      'aiInsightTrendDown': 'Tendencia bajista: %s en los últimos %s días.',
      'aiInsightTrendSideways':
          'Sin tendencia definida: %s en los últimos %s días.',
      'aiInsightMomentumOverbought':
          'Momento estirado: RSI en %s, en zona de sobrecompra.',
      'aiInsightMomentumOversold':
          'Momento presionado: RSI en %s, en zona de sobreventa.',
      'aiInsightMomentumNeutral': 'Momento equilibrado: RSI en %s.',
      'aiInsightVolatilityHigh': 'Volatilidad alta: %s al año, así que la '
          'proyección tiene un rango amplio.',
      'aiInsightVolatilityLow': 'Volatilidad baja: %s al año.',
      'aiInsightProjectionUp':
          'El modelo proyecta una subida del %s en %s días, hasta %s.',
      'aiInsightProjectionDown':
          'El modelo proyecta una bajada del %s en %s días, hasta %s.',
      'aiInsightProjectionStable':
          'El modelo proyecta estabilidad en %s días, en torno a %s.',
      'aiInsightDrawdown':
          'El activo cayó un %s desde su máximo en el periodo analizado.',
      'aiInsightConfidenceGood':
          'La red superó al paseo aleatorio en un %s en la validación.',
      'aiInsightConfidenceLow': 'La red no superó al paseo aleatorio con este '
          'histórico, así que la proyección sigue la base estadística.',
      'aiInsightDataLimited': 'Histórico corto (%s ventanas): la proyección '
          'usa solo la base estadística.',
    },
    // O espanhol da América Latina, o es-419 do CLDR: uma tradução só para as
    // Américas, já que as diferenças entre os países de lá são menores do que
    // as que separam qualquer um deles da Espanha.
    'es-419': {
      'conversionButtonLabel': 'Conversiones',
      'conversionPageTitle': 'Conversión de monedas',
      'homePageHeadsUpText': 'Cotizaciones en %s',
      'homeReorderHintLabel':
          'Mantén presionada una cotización para reorganizar la cuadrícula.',
      'homeReorderMoveEarlierLabel': 'Mover una posición hacia atrás',
      'homeReorderMoveLaterLabel': 'Mover una posición hacia adelante',
      'conversionMultiplierHint': 'Cantidad',
      'conversionPageExplanationText': 'Ingresa la cantidad de la moneda que '
          'vas a convertir, selecciona esa moneda y la moneda a la que quieres '
          'convertirla.',
      'conversionFromLabel': 'De',
      'conversionToLabel': 'A',
      'conversionSwapTooltip': 'Invertir las monedas',
      'conversionClearAmountTooltip': 'Borrar la cantidad',
      'conversionInvalidAmountError': 'Ingresa un valor válido',
      'conversionCurrencyPickerTitle': 'Selecciona una moneda',
      'conversionCurrencySearchHint': 'Busca por nombre o código',
      'conversionCurrencyNotFoundLabel': 'No se encontró ninguna moneda',
      'conversionCurrencyPickerYoursLabel': 'Tus monedas',
      'conversionCurrencyPickerOthersLabel': 'Todas las monedas',
      'conversionRateUnavailableLabel': 'Cotización no disponible',
      'conversionCopyResultTooltip': 'Copiar el resultado',
      'conversionResultCopiedLabel': 'Resultado copiado',
      'conversionHistorySectionLabel': 'Últimos %s días',
      'conversionHistoryUnavailableLabel': 'Sin historial para el período',
      'mainCurrenciesBottomNavItemLabel': 'Monedas',
      'currencyHistoryBottomNavItemLabel': 'Historial',
      'configBottomNavItemLabel': 'Configuración',
      'aboutBottomNavItemLabel': 'Acerca de',
      'currencyHistoryFromDateLabel': 'Desde',
      'currencyHistoryToDateLabel': 'Hasta',
      'currencyHistoryCurrenciesSectionLabel': 'Monedas',
      'currencyHistoryCryptocurrenciesSectionLabel': 'Criptomonedas',
      'noDataLabel': 'Sin datos',
      'getCurrencyHistoryBtnLabel': 'Obtener el historial',
      'currencyHistoryPeriodOptionLabel': '%s días',
      'overrideDefaultCurrencySwitchLabel':
          'Reemplazar la moneda predeterminada',
      'selectedOverrideCurrencyLabel': 'Moneda',
      'homeCurrenciesSettingLabel': 'Cotizaciones en la pantalla de inicio',
      'homeCurrenciesPickerTitle': 'Cotizaciones mostradas en burbujas',
      'homeCurrenciesPickerDescription':
          'La primera moneda seleccionada ocupa la burbuja destacada.',
      'homeCurrenciesSelectedCountLabel': '%s seleccionadas',
      'homeCurrenciesEmptySelectionLabel': 'Selecciona al menos una moneda',
      'homeCurrenciesSaveBtnLabel': 'Guardar',
      'appLanguageSettingLabel': 'Idioma de la aplicación',
      'appLanguageSystemOptionLabel': 'Idioma del sistema',
      'appConfigurationsSectionLabel': 'Configuración de la aplicación',
      'pwaInstallSectionLabel': 'Instalar en este dispositivo',
      'pwaInstallCardLabel': 'Instalar la aplicación',
      'pwaInstallCardDescription':
          'Agrega Cotação Direta a tu dispositivo y ábrelo desde su propio '
          'ícono, sin la barra del navegador.',
      'pwaInstallBtnLabel': 'Instalar',
      'pwaInstallIosCardDescription':
          'En el iPhone y el iPad la instalación se hace desde el menú de '
          'compartir de Safari.',
      'pwaInstallIosBtnLabel': 'Cómo instalar',
      'pwaInstallIosDialogTitle': 'Agregar a la pantalla de inicio',
      'pwaInstallIosDialogBody':
          'En Safari, toca el botón de compartir, en la parte de abajo de la '
          'pantalla, elige "Agregar a la pantalla de inicio" y confirma. '
          'Cotação Direta va a aparecer junto a tus aplicaciones.',
      'pwaInstallIosDialogCloseBtnLabel': 'Entendido',
      'pwaInstallAcceptedLabel': 'Aplicación instalada',
      'pwaInstallDismissedLabel': 'Instalación cancelada',
      'aboutAppDescription': 'Una aplicación sencilla que muestra la '
          'cotización de las principales monedas frente al real brasileño.',
      'aboutVersionLabel': 'Versión',
      'aboutDeveloperLabel': 'Desarrollado por',
      'aboutSourceCodeLabel': 'Código fuente',
      'currencyAlertsBottomNavItemLabel': 'Alertas',
      'currencyAlertsSectionLabel': 'Alertas de cambio',
      'currencyAlertEmptyListLabel':
          'Todavía no hay alertas. Toca el botón de abajo para crear una.',
      'addCurrencyAlertBtnLabel': 'Nueva alerta',
      'addCurrencyAlertDialogTitle': 'Nueva alerta de cambio',
      'currencyAlertCurrencyLabel': 'Moneda',
      'currencyAlertConditionLabel': 'Condición',
      'currencyAlertConditionAbove': 'Suba por encima de',
      'currencyAlertConditionBelow': 'Baje por debajo de',
      'currencyAlertTargetValueLabel': 'Valor objetivo',
      'currencyAlertInvalidValueError': 'Ingresa un valor válido',
      'currencyAlertSaveBtnLabel': 'Guardar',
      'currencyAlertCancelBtnLabel': 'Cancelar',
      'currencyAlertTriggeredLabel': 'Activada',
      'currencyAlertActiveLabel': 'En espera',
      'currencyAlertDeleteTooltip': 'Eliminar',
      'currencyAlertNotificationTitle': 'Alerta de cambio',
      'currencyAlertNotificationBody': '%s alcanzó %s',
      'notificationPermissionCardLabel': 'Notificaciones de las alertas',
      'notificationPermissionCardDescription':
          'Permite las notificaciones para saber cuándo se alcanza una '
              'alerta. Las alertas se revisan mientras la aplicación está '
              'abierta.',
      'notificationPermissionBtnLabel': 'Permitir',
      'notificationPermissionDeniedDescription':
          'Las notificaciones están bloqueadas. Vuelve a permitirlas en la '
              'configuración del sitio de este navegador para recibir el '
              'aviso cuando se alcance una alerta.',
      'notificationPermissionIosDescription':
          'En el iPhone y el iPad las notificaciones solo funcionan con la '
              'aplicación agregada a la pantalla de inicio. Instálala desde '
              'el menú Compartir de Safari y ábrela desde su ícono.',
      'notificationPermissionGrantedLabel': 'Notificaciones activadas',
      'notificationPermissionRefusedLabel': 'Notificaciones no activadas',
      'aiInsightsBottomNavItemLabel': 'IA',
      'aiInsightsSectionLabel': 'Análisis con IA en el dispositivo',
      'aiInsightsDescription': 'Una red neuronal pequeña se entrena en este '
          'dispositivo, con las cotizaciones que la aplicación ya descargó, '
          'para resumir el mercado y proyectar los próximos días. Ningún dato '
          'sale de tu celular.',
      'aiInsightsAssetLabel': 'Activo',
      'aiInsightsAssetPickerTitle': 'Selecciona un activo',
      'aiInsightsAssetNotFoundLabel': 'No se encontró ningún activo',
      'aiInsightsHorizonLabel': 'Horizonte de la proyección',
      'aiInsightsHorizonOptionLabel': '%s días',
      'aiInsightsAmountLabel': 'Monto para simular (opcional)',
      'aiInsightsAnalyzeBtnLabel': 'Analizar en el dispositivo',
      'aiInsightsRunningLabel': 'Entrenando el modelo local…',
      'aiInsightsEmptyLabel': 'Selecciona un activo y ejecuta el análisis.',
      'aiInsightsNoDataError':
          'No se encontraron cotizaciones para este activo.',
      'aiInsightsInsufficientDataError':
          'No hay historial suficiente para analizar este activo.',
      'aiInsightsFailureError': 'No se pudo completar el análisis.',
      'aiInsightsSummarySectionLabel': 'Resumen del mercado',
      'aiInsightsProjectionSectionLabel': 'Proyección',
      'aiInsightsInsightsSectionLabel': 'Conclusiones',
      'aiInsightsModelSectionLabel': 'Modelo local',
      'aiInsightsLastPriceLabel': 'Cotización actual',
      'aiInsightsWeeklyChangeLabel': 'Variación en 7 días',
      'aiInsightsMonthlyChangeLabel': 'Variación en 30 días',
      'aiInsightsVolatilityLabel': 'Volatilidad anualizada',
      'aiInsightsRsiLabel': 'Momento (RSI 14)',
      'aiInsightsDrawdownLabel': 'Mayor caída',
      'aiInsightsTrendLabel': 'Tendencia anualizada',
      'aiInsightsTrendFitLabel': 'Ajuste de la tendencia (R²)',
      'aiInsightsProjectedPriceLabel': 'Cotización proyectada en %s días',
      'aiInsightsProjectedChangeLabel': 'Variación proyectada',
      'aiInsightsConfidenceBandLabel': 'Rango con %s de confianza',
      'aiInsightsAmountProjectionLabel': 'Monto simulado',
      'aiInsightsAmountProjectionHint': '%s invertidos hoy',
      'aiInsightsModelSamplesLabel': 'Ventanas de entrenamiento',
      'aiInsightsModelSkillLabel': 'Ventaja sobre la caminata aleatoria',
      'aiInsightsModelEpochsLabel': 'Épocas',
      'aiInsightsModelUntrainedLabel':
          'Historial corto: la proyección usa solo la base estadística.',
      'aiInsightsDisclaimerLabel': 'Estimaciones calculadas en tu dispositivo '
          'a partir de cotizaciones pasadas. No son una recomendación de '
          'inversión.',
      'aiInsightsChartHistoryLabel': 'Historial',
      'aiInsightsChartProjectionLabel': 'Proyección',
      'aiInsightTrendUp': 'Tendencia alcista: %s en los últimos %s días.',
      'aiInsightTrendDown': 'Tendencia bajista: %s en los últimos %s días.',
      'aiInsightTrendSideways':
          'Sin tendencia definida: %s en los últimos %s días.',
      'aiInsightMomentumOverbought':
          'Momento estirado: RSI en %s, en zona de sobrecompra.',
      'aiInsightMomentumOversold':
          'Momento presionado: RSI en %s, en zona de sobreventa.',
      'aiInsightMomentumNeutral': 'Momento equilibrado: RSI en %s.',
      'aiInsightVolatilityHigh': 'Volatilidad alta: %s al año, así que la '
          'proyección tiene un rango amplio.',
      'aiInsightVolatilityLow': 'Volatilidad baja: %s al año.',
      'aiInsightProjectionUp':
          'El modelo proyecta un alza de %s en %s días, hasta %s.',
      'aiInsightProjectionDown':
          'El modelo proyecta una baja de %s en %s días, hasta %s.',
      'aiInsightProjectionStable':
          'El modelo proyecta estabilidad en %s días, alrededor de %s.',
      'aiInsightDrawdown':
          'El activo cayó %s desde su máximo en el período analizado.',
      'aiInsightConfidenceGood':
          'La red superó a la caminata aleatoria en %s en la validación.',
      'aiInsightConfidenceLow': 'La red no superó a la caminata aleatoria con '
          'este historial, así que la proyección sigue la base estadística.',
      'aiInsightDataLimited': 'Historial corto (%s ventanas): la proyección '
          'usa solo la base estadística.',
    }
  };

  String? get conversionButtonLabel {
    return _values['conversionButtonLabel'];
  }

  String? get conversionPageTitle {
    return _values['conversionPageTitle'];
  }

  String? get homePageHeadsUpText {
    return _values['homePageHeadsUpText'];
  }

  /// Diz que dá para reordenar a grade da tela inicial: o arrasto por toque
  /// longo não se anuncia sozinho.
  String? get homeReorderHintLabel {
    return _values['homeReorderHintLabel'];
  }

  /// Ações da grade para o leitor de tela, no lugar do arrasto.
  String? get homeReorderMoveEarlierLabel {
    return _values['homeReorderMoveEarlierLabel'];
  }

  String? get homeReorderMoveLaterLabel {
    return _values['homeReorderMoveLaterLabel'];
  }

  String? get conversionMultiplierHint {
    return _values['conversionMultiplierHint'];
  }

  String? get conversionPageExplanationText {
    return _values['conversionPageExplanationText'];
  }

  String? get conversionFromLabel {
    return _values['conversionFromLabel'];
  }

  String? get conversionToLabel {
    return _values['conversionToLabel'];
  }

  String? get conversionSwapTooltip {
    return _values['conversionSwapTooltip'];
  }

  String? get conversionClearAmountTooltip {
    return _values['conversionClearAmountTooltip'];
  }

  String? get conversionInvalidAmountError {
    return _values['conversionInvalidAmountError'];
  }

  String? get conversionCurrencyPickerTitle {
    return _values['conversionCurrencyPickerTitle'];
  }

  String? get conversionCurrencySearchHint {
    return _values['conversionCurrencySearchHint'];
  }

  String? get conversionCurrencyNotFoundLabel {
    return _values['conversionCurrencyNotFoundLabel'];
  }

  /// Título da seção do seletor com as moedas da tela inicial, que aparecem
  /// antes das demais.
  String? get conversionCurrencyPickerYoursLabel {
    return _values['conversionCurrencyPickerYoursLabel'];
  }

  /// Título da seção com o resto da lista, logo abaixo das moedas da tela
  /// inicial.
  String? get conversionCurrencyPickerOthersLabel {
    return _values['conversionCurrencyPickerOthersLabel'];
  }

  String? get conversionRateUnavailableLabel {
    return _values['conversionRateUnavailableLabel'];
  }

  String? get conversionCopyResultTooltip {
    return _values['conversionCopyResultTooltip'];
  }

  String? get conversionResultCopiedLabel {
    return _values['conversionResultCopiedLabel'];
  }

  /// Título do gráfico da tela de conversão. Traz o marcador do número de dias
  /// mostrados, que é fixo na tela mas mora no bloc.
  String? get conversionHistorySectionLabel {
    return _values['conversionHistorySectionLabel'];
  }

  String? get conversionHistoryUnavailableLabel {
    return _values['conversionHistoryUnavailableLabel'];
  }

  String? get mainCurrenciesBottomNavItemLabel {
    return _values['mainCurrenciesBottomNavItemLabel'];
  }

  String? get currencyHistoryBottomNavItemLabel {
    return _values['currencyHistoryBottomNavItemLabel'];
  }

  String? get aboutBottomNavItemLabel {
    return _values['aboutBottomNavItemLabel'];
  }

  String? get currencyHistoryFromDateLabel {
    return _values['currencyHistoryFromDateLabel'];
  }

  String? get currencyHistoryToDateLabel {
    return _values['currencyHistoryToDateLabel'];
  }

  String? get currencyHistoryCurrenciesSectionLabel {
    return _values['currencyHistoryCurrenciesSectionLabel'];
  }

  String? get currencyHistoryCryptocurrenciesSectionLabel {
    return _values['currencyHistoryCryptocurrenciesSectionLabel'];
  }

  String? get noDataLabel {
    return _values['noDataLabel'];
  }

  String? get getCurrencyHistoryBtnLabel {
    return _values['getCurrencyHistoryBtnLabel'];
  }

  /// Rótulo de cada chip de período rápido da tela de histórico. Traz o
  /// marcador do número de dias.
  String? get currencyHistoryPeriodOptionLabel {
    return _values['currencyHistoryPeriodOptionLabel'];
  }

  String? get getConfigBottomNavItemLabel {
    return _values['configBottomNavItemLabel'];
  }

  String? get overrideDefaultCurrencySwitchLabel {
    return _values['overrideDefaultCurrencySwitchLabel'];
  }

  String? get selectedOverrideCurrencyLabel {
    return _values['selectedOverrideCurrencyLabel'];
  }

  String? get homeCurrenciesSettingLabel {
    return _values['homeCurrenciesSettingLabel'];
  }

  String? get homeCurrenciesPickerTitle {
    return _values['homeCurrenciesPickerTitle'];
  }

  String? get homeCurrenciesPickerDescription {
    return _values['homeCurrenciesPickerDescription'];
  }

  String? get homeCurrenciesSelectedCountLabel {
    return _values['homeCurrenciesSelectedCountLabel'];
  }

  String? get homeCurrenciesEmptySelectionLabel {
    return _values['homeCurrenciesEmptySelectionLabel'];
  }

  String? get homeCurrenciesSaveBtnLabel {
    return _values['homeCurrenciesSaveBtnLabel'];
  }

  String? get appLanguageSettingLabel {
    return _values['appLanguageSettingLabel'];
  }

  String? get appLanguageSystemOptionLabel {
    return _values['appLanguageSystemOptionLabel'];
  }

  String? get appConfigurationsSectionLabel {
    return _values['appConfigurationsSectionLabel'];
  }

  String? get pwaInstallSectionLabel {
    return _values['pwaInstallSectionLabel'];
  }

  String? get pwaInstallCardLabel {
    return _values['pwaInstallCardLabel'];
  }

  String? get pwaInstallCardDescription {
    return _values['pwaInstallCardDescription'];
  }

  String? get pwaInstallBtnLabel {
    return _values['pwaInstallBtnLabel'];
  }

  String? get pwaInstallIosCardDescription {
    return _values['pwaInstallIosCardDescription'];
  }

  String? get pwaInstallIosBtnLabel {
    return _values['pwaInstallIosBtnLabel'];
  }

  String? get pwaInstallIosDialogTitle {
    return _values['pwaInstallIosDialogTitle'];
  }

  String? get pwaInstallIosDialogBody {
    return _values['pwaInstallIosDialogBody'];
  }

  String? get pwaInstallIosDialogCloseBtnLabel {
    return _values['pwaInstallIosDialogCloseBtnLabel'];
  }

  String? get pwaInstallAcceptedLabel {
    return _values['pwaInstallAcceptedLabel'];
  }

  String? get pwaInstallDismissedLabel {
    return _values['pwaInstallDismissedLabel'];
  }

  String? get aboutAppDescription {
    return _values['aboutAppDescription'];
  }

  String? get aboutVersionLabel {
    return _values['aboutVersionLabel'];
  }

  String? get aboutDeveloperLabel {
    return _values['aboutDeveloperLabel'];
  }

  String? get aboutSourceCodeLabel {
    return _values['aboutSourceCodeLabel'];
  }

  String? get currencyAlertsBottomNavItemLabel {
    return _values['currencyAlertsBottomNavItemLabel'];
  }

  String? get currencyAlertsSectionLabel {
    return _values['currencyAlertsSectionLabel'];
  }

  String? get currencyAlertEmptyListLabel {
    return _values['currencyAlertEmptyListLabel'];
  }

  String? get addCurrencyAlertBtnLabel {
    return _values['addCurrencyAlertBtnLabel'];
  }

  String? get addCurrencyAlertDialogTitle {
    return _values['addCurrencyAlertDialogTitle'];
  }

  String? get currencyAlertCurrencyLabel {
    return _values['currencyAlertCurrencyLabel'];
  }

  String? get currencyAlertConditionLabel {
    return _values['currencyAlertConditionLabel'];
  }

  String? get currencyAlertConditionAbove {
    return _values['currencyAlertConditionAbove'];
  }

  String? get currencyAlertConditionBelow {
    return _values['currencyAlertConditionBelow'];
  }

  String? get currencyAlertTargetValueLabel {
    return _values['currencyAlertTargetValueLabel'];
  }

  String? get currencyAlertInvalidValueError {
    return _values['currencyAlertInvalidValueError'];
  }

  String? get currencyAlertSaveBtnLabel {
    return _values['currencyAlertSaveBtnLabel'];
  }

  String? get currencyAlertCancelBtnLabel {
    return _values['currencyAlertCancelBtnLabel'];
  }

  String? get currencyAlertTriggeredLabel {
    return _values['currencyAlertTriggeredLabel'];
  }

  String? get currencyAlertActiveLabel {
    return _values['currencyAlertActiveLabel'];
  }

  String? get currencyAlertDeleteTooltip {
    return _values['currencyAlertDeleteTooltip'];
  }

  String? get currencyAlertNotificationTitle {
    return _values['currencyAlertNotificationTitle'];
  }

  String? get currencyAlertNotificationBody {
    return _values['currencyAlertNotificationBody'];
  }

  String? get notificationPermissionCardLabel {
    return _values['notificationPermissionCardLabel'];
  }

  String? get notificationPermissionCardDescription {
    return _values['notificationPermissionCardDescription'];
  }

  String? get notificationPermissionBtnLabel {
    return _values['notificationPermissionBtnLabel'];
  }

  String? get notificationPermissionDeniedDescription {
    return _values['notificationPermissionDeniedDescription'];
  }

  String? get notificationPermissionIosDescription {
    return _values['notificationPermissionIosDescription'];
  }

  String? get notificationPermissionGrantedLabel {
    return _values['notificationPermissionGrantedLabel'];
  }

  String? get notificationPermissionRefusedLabel {
    return _values['notificationPermissionRefusedLabel'];
  }

  String? get aiInsightsBottomNavItemLabel {
    return _values['aiInsightsBottomNavItemLabel'];
  }

  String? get aiInsightsSectionLabel {
    return _values['aiInsightsSectionLabel'];
  }

  String? get aiInsightsDescription {
    return _values['aiInsightsDescription'];
  }

  String? get aiInsightsAssetLabel {
    return _values['aiInsightsAssetLabel'];
  }

  String? get aiInsightsAssetPickerTitle {
    return _values['aiInsightsAssetPickerTitle'];
  }

  String? get aiInsightsAssetNotFoundLabel {
    return _values['aiInsightsAssetNotFoundLabel'];
  }

  String? get aiInsightsHorizonLabel {
    return _values['aiInsightsHorizonLabel'];
  }

  String? get aiInsightsHorizonOptionLabel {
    return _values['aiInsightsHorizonOptionLabel'];
  }

  String? get aiInsightsAmountLabel {
    return _values['aiInsightsAmountLabel'];
  }

  String? get aiInsightsAnalyzeBtnLabel {
    return _values['aiInsightsAnalyzeBtnLabel'];
  }

  String? get aiInsightsRunningLabel {
    return _values['aiInsightsRunningLabel'];
  }

  String? get aiInsightsEmptyLabel {
    return _values['aiInsightsEmptyLabel'];
  }

  String? get aiInsightsNoDataError {
    return _values['aiInsightsNoDataError'];
  }

  String? get aiInsightsInsufficientDataError {
    return _values['aiInsightsInsufficientDataError'];
  }

  String? get aiInsightsFailureError {
    return _values['aiInsightsFailureError'];
  }

  String? get aiInsightsSummarySectionLabel {
    return _values['aiInsightsSummarySectionLabel'];
  }

  String? get aiInsightsProjectionSectionLabel {
    return _values['aiInsightsProjectionSectionLabel'];
  }

  String? get aiInsightsInsightsSectionLabel {
    return _values['aiInsightsInsightsSectionLabel'];
  }

  String? get aiInsightsModelSectionLabel {
    return _values['aiInsightsModelSectionLabel'];
  }

  String? get aiInsightsLastPriceLabel {
    return _values['aiInsightsLastPriceLabel'];
  }

  String? get aiInsightsWeeklyChangeLabel {
    return _values['aiInsightsWeeklyChangeLabel'];
  }

  String? get aiInsightsMonthlyChangeLabel {
    return _values['aiInsightsMonthlyChangeLabel'];
  }

  String? get aiInsightsVolatilityLabel {
    return _values['aiInsightsVolatilityLabel'];
  }

  String? get aiInsightsRsiLabel {
    return _values['aiInsightsRsiLabel'];
  }

  String? get aiInsightsDrawdownLabel {
    return _values['aiInsightsDrawdownLabel'];
  }

  String? get aiInsightsTrendLabel {
    return _values['aiInsightsTrendLabel'];
  }

  String? get aiInsightsTrendFitLabel {
    return _values['aiInsightsTrendFitLabel'];
  }

  String? get aiInsightsProjectedPriceLabel {
    return _values['aiInsightsProjectedPriceLabel'];
  }

  String? get aiInsightsProjectedChangeLabel {
    return _values['aiInsightsProjectedChangeLabel'];
  }

  String? get aiInsightsConfidenceBandLabel {
    return _values['aiInsightsConfidenceBandLabel'];
  }

  String? get aiInsightsAmountProjectionLabel {
    return _values['aiInsightsAmountProjectionLabel'];
  }

  String? get aiInsightsAmountProjectionHint {
    return _values['aiInsightsAmountProjectionHint'];
  }

  String? get aiInsightsModelSamplesLabel {
    return _values['aiInsightsModelSamplesLabel'];
  }

  String? get aiInsightsModelSkillLabel {
    return _values['aiInsightsModelSkillLabel'];
  }

  String? get aiInsightsModelEpochsLabel {
    return _values['aiInsightsModelEpochsLabel'];
  }

  String? get aiInsightsModelUntrainedLabel {
    return _values['aiInsightsModelUntrainedLabel'];
  }

  String? get aiInsightsDisclaimerLabel {
    return _values['aiInsightsDisclaimerLabel'];
  }

  String? get aiInsightsChartHistoryLabel {
    return _values['aiInsightsChartHistoryLabel'];
  }

  String? get aiInsightsChartProjectionLabel {
    return _values['aiInsightsChartProjectionLabel'];
  }

  String? get aiInsightTrendUp {
    return _values['aiInsightTrendUp'];
  }

  String? get aiInsightTrendDown {
    return _values['aiInsightTrendDown'];
  }

  String? get aiInsightTrendSideways {
    return _values['aiInsightTrendSideways'];
  }

  String? get aiInsightMomentumOverbought {
    return _values['aiInsightMomentumOverbought'];
  }

  String? get aiInsightMomentumOversold {
    return _values['aiInsightMomentumOversold'];
  }

  String? get aiInsightMomentumNeutral {
    return _values['aiInsightMomentumNeutral'];
  }

  String? get aiInsightVolatilityHigh {
    return _values['aiInsightVolatilityHigh'];
  }

  String? get aiInsightVolatilityLow {
    return _values['aiInsightVolatilityLow'];
  }

  String? get aiInsightProjectionUp {
    return _values['aiInsightProjectionUp'];
  }

  String? get aiInsightProjectionDown {
    return _values['aiInsightProjectionDown'];
  }

  String? get aiInsightProjectionStable {
    return _values['aiInsightProjectionStable'];
  }

  String? get aiInsightDrawdown {
    return _values['aiInsightDrawdown'];
  }

  String? get aiInsightConfidenceGood {
    return _values['aiInsightConfidenceGood'];
  }

  String? get aiInsightConfidenceLow {
    return _values['aiInsightConfidenceLow'];
  }

  String? get aiInsightDataLimited {
    return _values['aiInsightDataLimited'];
  }
}

class MyAppLocalizationsDelegate
    extends LocalizationsDelegate<MyAppLocalizations> {
  @override
  bool isSupported(Locale locale) => AppLocales.resolve(locale) != null;

  @override
  Future<MyAppLocalizations> load(Locale locale) {
    return SynchronousFuture<MyAppLocalizations>(MyAppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<MyAppLocalizations> old) => false;
}
