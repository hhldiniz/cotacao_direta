import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MyAppLocalizations {
  MyAppLocalizations(this.locale);

  final Locale locale;

  static MyAppLocalizations? of(BuildContext context) {
    return Localizations.of<MyAppLocalizations>(context, MyAppLocalizations);
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'conversionButtonLabel': 'Conversions',
      'conversionPageTitle': "Currency Conversion",
      'homePageHeadsUpText': 'Exchange rates in %s',
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
      'overrideDefaultCurrencySwitchLabel': 'Override default currency',
      'selectedOverrideCurrencyLabel': 'Currency',
      'homeCurrenciesSettingLabel': 'Quotes on the home screen',
      'homeCurrenciesPickerTitle': 'Quotes shown as bubbles',
      'homeCurrenciesPickerDescription':
          'The first currency chosen gets the big bubble.',
      'homeCurrenciesSelectedCountLabel': '%s selected',
      'homeCurrenciesEmptySelectionLabel': 'Choose at least one currency',
      'homeCurrenciesSaveBtnLabel': 'Save',
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
      'overrideDefaultCurrencySwitchLabel': 'Sobrescrever moeda padrão',
      'selectedOverrideCurrencyLabel': 'Moeda',
      'homeCurrenciesSettingLabel': 'Cotações na tela inicial',
      'homeCurrenciesPickerTitle': 'Cotações mostradas em bolhas',
      'homeCurrenciesPickerDescription':
          'A primeira moeda escolhida fica na bolha de destaque.',
      'homeCurrenciesSelectedCountLabel': '%s escolhidas',
      'homeCurrenciesEmptySelectionLabel': 'Escolha pelo menos uma moeda',
      'homeCurrenciesSaveBtnLabel': 'Salvar',
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
    }
  };

  String? get conversionButtonLabel {
    return _localizedValues[locale.languageCode]!['conversionButtonLabel'];
  }

  String? get conversionPageTitle {
    return _localizedValues[locale.languageCode]!['conversionPageTitle'];
  }

  String? get homePageHeadsUpText {
    return _localizedValues[locale.languageCode]!['homePageHeadsUpText'];
  }

  String? get conversionMultiplierHint {
    return _localizedValues[locale.languageCode]!['conversionMultiplierHint'];
  }

  String? get conversionPageExplanationText {
    return _localizedValues[locale.languageCode]!
        ['conversionPageExplanationText'];
  }

  String? get conversionFromLabel {
    return _localizedValues[locale.languageCode]!['conversionFromLabel'];
  }

  String? get conversionToLabel {
    return _localizedValues[locale.languageCode]!['conversionToLabel'];
  }

  String? get conversionSwapTooltip {
    return _localizedValues[locale.languageCode]!['conversionSwapTooltip'];
  }

  String? get conversionClearAmountTooltip {
    return _localizedValues[locale.languageCode]!
        ['conversionClearAmountTooltip'];
  }

  String? get conversionInvalidAmountError {
    return _localizedValues[locale.languageCode]!
        ['conversionInvalidAmountError'];
  }

  String? get conversionCurrencyPickerTitle {
    return _localizedValues[locale.languageCode]!
        ['conversionCurrencyPickerTitle'];
  }

  String? get conversionCurrencySearchHint {
    return _localizedValues[locale.languageCode]!
        ['conversionCurrencySearchHint'];
  }

  String? get conversionCurrencyNotFoundLabel {
    return _localizedValues[locale.languageCode]!
        ['conversionCurrencyNotFoundLabel'];
  }

  /// Título da seção do seletor com as moedas da tela inicial, que aparecem
  /// antes das demais.
  String? get conversionCurrencyPickerYoursLabel {
    return _localizedValues[locale.languageCode]!
        ['conversionCurrencyPickerYoursLabel'];
  }

  /// Título da seção com o resto da lista, logo abaixo das moedas da tela
  /// inicial.
  String? get conversionCurrencyPickerOthersLabel {
    return _localizedValues[locale.languageCode]!
        ['conversionCurrencyPickerOthersLabel'];
  }

  String? get conversionRateUnavailableLabel {
    return _localizedValues[locale.languageCode]!
        ['conversionRateUnavailableLabel'];
  }

  String? get conversionCopyResultTooltip {
    return _localizedValues[locale.languageCode]!
        ['conversionCopyResultTooltip'];
  }

  String? get conversionResultCopiedLabel {
    return _localizedValues[locale.languageCode]!
        ['conversionResultCopiedLabel'];
  }

  String? get mainCurrenciesBottomNavItemLabel {
    return _localizedValues[locale.languageCode]!
        ['mainCurrenciesBottomNavItemLabel'];
  }

  String? get currencyHistoryBottomNavItemLabel {
    return _localizedValues[locale.languageCode]!
        ['currencyHistoryBottomNavItemLabel'];
  }

  String? get aboutBottomNavItemLabel {
    return _localizedValues[locale.languageCode]!['aboutBottomNavItemLabel'];
  }

  String? get currencyHistoryFromDateLabel {
    return _localizedValues[locale.languageCode]!
        ['currencyHistoryFromDateLabel'];
  }

  String? get currencyHistoryToDateLabel {
    return _localizedValues[locale.languageCode]!['currencyHistoryToDateLabel'];
  }

  String? get currencyHistoryCurrenciesSectionLabel {
    return _localizedValues[locale.languageCode]!
        ['currencyHistoryCurrenciesSectionLabel'];
  }

  String? get currencyHistoryCryptocurrenciesSectionLabel {
    return _localizedValues[locale.languageCode]!
        ['currencyHistoryCryptocurrenciesSectionLabel'];
  }

  String? get noDataLabel {
    return _localizedValues[locale.languageCode]!['noDataLabel'];
  }

  String? get getCurrencyHistoryBtnLabel {
    return _localizedValues[locale.languageCode]!['getCurrencyHistoryBtnLabel'];
  }

  String? get getConfigBottomNavItemLabel {
    return _localizedValues[locale.languageCode]!['configBottomNavItemLabel'];
  }

  String? get overrideDefaultCurrencySwitchLabel {
    return _localizedValues[locale.languageCode]!
        ['overrideDefaultCurrencySwitchLabel'];
  }

  String? get selectedOverrideCurrencyLabel {
    return _localizedValues[locale.languageCode]!
        ['selectedOverrideCurrencyLabel'];
  }

  String? get homeCurrenciesSettingLabel {
    return _localizedValues[locale.languageCode]!['homeCurrenciesSettingLabel'];
  }

  String? get homeCurrenciesPickerTitle {
    return _localizedValues[locale.languageCode]!['homeCurrenciesPickerTitle'];
  }

  String? get homeCurrenciesPickerDescription {
    return _localizedValues[locale.languageCode]!
        ['homeCurrenciesPickerDescription'];
  }

  String? get homeCurrenciesSelectedCountLabel {
    return _localizedValues[locale.languageCode]!
        ['homeCurrenciesSelectedCountLabel'];
  }

  String? get homeCurrenciesEmptySelectionLabel {
    return _localizedValues[locale.languageCode]!
        ['homeCurrenciesEmptySelectionLabel'];
  }

  String? get homeCurrenciesSaveBtnLabel {
    return _localizedValues[locale.languageCode]!
        ['homeCurrenciesSaveBtnLabel'];
  }

  String? get appConfigurationsSectionLabel {
    return _localizedValues[locale.languageCode]!
        ['appConfigurationsSectionLabel'];
  }

  String? get pwaInstallSectionLabel {
    return _localizedValues[locale.languageCode]!['pwaInstallSectionLabel'];
  }

  String? get pwaInstallCardLabel {
    return _localizedValues[locale.languageCode]!['pwaInstallCardLabel'];
  }

  String? get pwaInstallCardDescription {
    return _localizedValues[locale.languageCode]!['pwaInstallCardDescription'];
  }

  String? get pwaInstallBtnLabel {
    return _localizedValues[locale.languageCode]!['pwaInstallBtnLabel'];
  }

  String? get pwaInstallIosCardDescription {
    return _localizedValues[locale.languageCode]!
        ['pwaInstallIosCardDescription'];
  }

  String? get pwaInstallIosBtnLabel {
    return _localizedValues[locale.languageCode]!['pwaInstallIosBtnLabel'];
  }

  String? get pwaInstallIosDialogTitle {
    return _localizedValues[locale.languageCode]!['pwaInstallIosDialogTitle'];
  }

  String? get pwaInstallIosDialogBody {
    return _localizedValues[locale.languageCode]!['pwaInstallIosDialogBody'];
  }

  String? get pwaInstallIosDialogCloseBtnLabel {
    return _localizedValues[locale.languageCode]!
        ['pwaInstallIosDialogCloseBtnLabel'];
  }

  String? get pwaInstallAcceptedLabel {
    return _localizedValues[locale.languageCode]!['pwaInstallAcceptedLabel'];
  }

  String? get pwaInstallDismissedLabel {
    return _localizedValues[locale.languageCode]!['pwaInstallDismissedLabel'];
  }

  String? get aboutAppDescription {
    return _localizedValues[locale.languageCode]!['aboutAppDescription'];
  }

  String? get aboutVersionLabel {
    return _localizedValues[locale.languageCode]!['aboutVersionLabel'];
  }

  String? get aboutDeveloperLabel {
    return _localizedValues[locale.languageCode]!['aboutDeveloperLabel'];
  }

  String? get aboutSourceCodeLabel {
    return _localizedValues[locale.languageCode]!['aboutSourceCodeLabel'];
  }

  String? get currencyAlertsBottomNavItemLabel {
    return _localizedValues[locale.languageCode]!
        ['currencyAlertsBottomNavItemLabel'];
  }

  String? get currencyAlertsSectionLabel {
    return _localizedValues[locale.languageCode]!['currencyAlertsSectionLabel'];
  }

  String? get currencyAlertEmptyListLabel {
    return _localizedValues[locale.languageCode]!['currencyAlertEmptyListLabel'];
  }

  String? get addCurrencyAlertBtnLabel {
    return _localizedValues[locale.languageCode]!['addCurrencyAlertBtnLabel'];
  }

  String? get addCurrencyAlertDialogTitle {
    return _localizedValues[locale.languageCode]!
        ['addCurrencyAlertDialogTitle'];
  }

  String? get currencyAlertCurrencyLabel {
    return _localizedValues[locale.languageCode]!['currencyAlertCurrencyLabel'];
  }

  String? get currencyAlertConditionLabel {
    return _localizedValues[locale.languageCode]!
        ['currencyAlertConditionLabel'];
  }

  String? get currencyAlertConditionAbove {
    return _localizedValues[locale.languageCode]!
        ['currencyAlertConditionAbove'];
  }

  String? get currencyAlertConditionBelow {
    return _localizedValues[locale.languageCode]!
        ['currencyAlertConditionBelow'];
  }

  String? get currencyAlertTargetValueLabel {
    return _localizedValues[locale.languageCode]!
        ['currencyAlertTargetValueLabel'];
  }

  String? get currencyAlertInvalidValueError {
    return _localizedValues[locale.languageCode]!
        ['currencyAlertInvalidValueError'];
  }

  String? get currencyAlertSaveBtnLabel {
    return _localizedValues[locale.languageCode]!['currencyAlertSaveBtnLabel'];
  }

  String? get currencyAlertCancelBtnLabel {
    return _localizedValues[locale.languageCode]!
        ['currencyAlertCancelBtnLabel'];
  }

  String? get currencyAlertTriggeredLabel {
    return _localizedValues[locale.languageCode]!['currencyAlertTriggeredLabel'];
  }

  String? get currencyAlertActiveLabel {
    return _localizedValues[locale.languageCode]!['currencyAlertActiveLabel'];
  }

  String? get currencyAlertDeleteTooltip {
    return _localizedValues[locale.languageCode]!['currencyAlertDeleteTooltip'];
  }

  String? get currencyAlertNotificationTitle {
    return _localizedValues[locale.languageCode]!
        ['currencyAlertNotificationTitle'];
  }

  String? get currencyAlertNotificationBody {
    return _localizedValues[locale.languageCode]!
        ['currencyAlertNotificationBody'];
  }

  String? get aiInsightsBottomNavItemLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsBottomNavItemLabel'];
  }

  String? get aiInsightsSectionLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsSectionLabel'];
  }

  String? get aiInsightsDescription {
    return _localizedValues[locale.languageCode]!['aiInsightsDescription'];
  }

  String? get aiInsightsAssetLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsAssetLabel'];
  }

  String? get aiInsightsAssetPickerTitle {
    return _localizedValues[locale.languageCode]!['aiInsightsAssetPickerTitle'];
  }

  String? get aiInsightsAssetNotFoundLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsAssetNotFoundLabel'];
  }

  String? get aiInsightsHorizonLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsHorizonLabel'];
  }

  String? get aiInsightsHorizonOptionLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsHorizonOptionLabel'];
  }

  String? get aiInsightsAmountLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsAmountLabel'];
  }

  String? get aiInsightsAnalyzeBtnLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsAnalyzeBtnLabel'];
  }

  String? get aiInsightsRunningLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsRunningLabel'];
  }

  String? get aiInsightsEmptyLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsEmptyLabel'];
  }

  String? get aiInsightsNoDataError {
    return _localizedValues[locale.languageCode]!['aiInsightsNoDataError'];
  }

  String? get aiInsightsInsufficientDataError {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsInsufficientDataError'];
  }

  String? get aiInsightsFailureError {
    return _localizedValues[locale.languageCode]!['aiInsightsFailureError'];
  }

  String? get aiInsightsSummarySectionLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsSummarySectionLabel'];
  }

  String? get aiInsightsProjectionSectionLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsProjectionSectionLabel'];
  }

  String? get aiInsightsInsightsSectionLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsInsightsSectionLabel'];
  }

  String? get aiInsightsModelSectionLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsModelSectionLabel'];
  }

  String? get aiInsightsLastPriceLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsLastPriceLabel'];
  }

  String? get aiInsightsWeeklyChangeLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsWeeklyChangeLabel'];
  }

  String? get aiInsightsMonthlyChangeLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsMonthlyChangeLabel'];
  }

  String? get aiInsightsVolatilityLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsVolatilityLabel'];
  }

  String? get aiInsightsRsiLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsRsiLabel'];
  }

  String? get aiInsightsDrawdownLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsDrawdownLabel'];
  }

  String? get aiInsightsTrendLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsTrendLabel'];
  }

  String? get aiInsightsTrendFitLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsTrendFitLabel'];
  }

  String? get aiInsightsProjectedPriceLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsProjectedPriceLabel'];
  }

  String? get aiInsightsProjectedChangeLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsProjectedChangeLabel'];
  }

  String? get aiInsightsConfidenceBandLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsConfidenceBandLabel'];
  }

  String? get aiInsightsAmountProjectionLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsAmountProjectionLabel'];
  }

  String? get aiInsightsAmountProjectionHint {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsAmountProjectionHint'];
  }

  String? get aiInsightsModelSamplesLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsModelSamplesLabel'];
  }

  String? get aiInsightsModelSkillLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsModelSkillLabel'];
  }

  String? get aiInsightsModelEpochsLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsModelEpochsLabel'];
  }

  String? get aiInsightsModelUntrainedLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsModelUntrainedLabel'];
  }

  String? get aiInsightsDisclaimerLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsDisclaimerLabel'];
  }

  String? get aiInsightsChartHistoryLabel {
    return _localizedValues[locale.languageCode]!['aiInsightsChartHistoryLabel'];
  }

  String? get aiInsightsChartProjectionLabel {
    return _localizedValues[locale.languageCode]!
        ['aiInsightsChartProjectionLabel'];
  }

  String? get aiInsightTrendUp {
    return _localizedValues[locale.languageCode]!['aiInsightTrendUp'];
  }

  String? get aiInsightTrendDown {
    return _localizedValues[locale.languageCode]!['aiInsightTrendDown'];
  }

  String? get aiInsightTrendSideways {
    return _localizedValues[locale.languageCode]!['aiInsightTrendSideways'];
  }

  String? get aiInsightMomentumOverbought {
    return _localizedValues[locale.languageCode]!
        ['aiInsightMomentumOverbought'];
  }

  String? get aiInsightMomentumOversold {
    return _localizedValues[locale.languageCode]!['aiInsightMomentumOversold'];
  }

  String? get aiInsightMomentumNeutral {
    return _localizedValues[locale.languageCode]!['aiInsightMomentumNeutral'];
  }

  String? get aiInsightVolatilityHigh {
    return _localizedValues[locale.languageCode]!['aiInsightVolatilityHigh'];
  }

  String? get aiInsightVolatilityLow {
    return _localizedValues[locale.languageCode]!['aiInsightVolatilityLow'];
  }

  String? get aiInsightProjectionUp {
    return _localizedValues[locale.languageCode]!['aiInsightProjectionUp'];
  }

  String? get aiInsightProjectionDown {
    return _localizedValues[locale.languageCode]!['aiInsightProjectionDown'];
  }

  String? get aiInsightProjectionStable {
    return _localizedValues[locale.languageCode]!['aiInsightProjectionStable'];
  }

  String? get aiInsightDrawdown {
    return _localizedValues[locale.languageCode]!['aiInsightDrawdown'];
  }

  String? get aiInsightConfidenceGood {
    return _localizedValues[locale.languageCode]!['aiInsightConfidenceGood'];
  }

  String? get aiInsightConfidenceLow {
    return _localizedValues[locale.languageCode]!['aiInsightConfidenceLow'];
  }

  String? get aiInsightDataLimited {
    return _localizedValues[locale.languageCode]!['aiInsightDataLimited'];
  }
}

class MyAppLocalizationsDelegate
    extends LocalizationsDelegate<MyAppLocalizations> {
  @override
  bool isSupported(Locale locale) => ["en", "pt"].contains(locale.languageCode);

  @override
  Future<MyAppLocalizations> load(Locale locale) {
    return SynchronousFuture<MyAppLocalizations>(MyAppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<MyAppLocalizations> old) => false;
}
