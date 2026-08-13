import 'package:cotacao_direta/util/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Todos os textos expostos pela classe, para conferir os dois idiomas de uma
/// vez sem depender do mapa interno.
List<String?> _allLabels(MyAppLocalizations localizations) => [
      localizations.conversionButtonLabel,
      localizations.conversionPageTitle,
      localizations.homePageHeadsUpText,
      localizations.conversionMultiplierHint,
      localizations.conversionPageExplanationText,
      localizations.conversionFromLabel,
      localizations.conversionToLabel,
      localizations.conversionSwapTooltip,
      localizations.conversionClearAmountTooltip,
      localizations.conversionInvalidAmountError,
      localizations.conversionCurrencyPickerTitle,
      localizations.conversionCurrencySearchHint,
      localizations.conversionCurrencyNotFoundLabel,
      localizations.conversionCurrencyPickerYoursLabel,
      localizations.conversionCurrencyPickerOthersLabel,
      localizations.conversionRateUnavailableLabel,
      localizations.conversionCopyResultTooltip,
      localizations.conversionResultCopiedLabel,
      localizations.mainCurrenciesBottomNavItemLabel,
      localizations.currencyHistoryBottomNavItemLabel,
      localizations.aboutBottomNavItemLabel,
      localizations.currencyHistoryFromDateLabel,
      localizations.currencyHistoryToDateLabel,
      localizations.currencyHistoryCurrenciesSectionLabel,
      localizations.currencyHistoryCryptocurrenciesSectionLabel,
      localizations.noDataLabel,
      localizations.getCurrencyHistoryBtnLabel,
      localizations.getConfigBottomNavItemLabel,
      localizations.overrideDefaultCurrencySwitchLabel,
      localizations.selectedOverrideCurrencyLabel,
      localizations.homeCurrenciesSettingLabel,
      localizations.homeCurrenciesPickerTitle,
      localizations.homeCurrenciesPickerDescription,
      localizations.homeCurrenciesSelectedCountLabel,
      localizations.homeCurrenciesEmptySelectionLabel,
      localizations.homeCurrenciesSaveBtnLabel,
      localizations.appConfigurationsSectionLabel,
      localizations.pwaInstallSectionLabel,
      localizations.pwaInstallCardLabel,
      localizations.pwaInstallCardDescription,
      localizations.pwaInstallBtnLabel,
      localizations.pwaInstallIosCardDescription,
      localizations.pwaInstallIosBtnLabel,
      localizations.pwaInstallIosDialogTitle,
      localizations.pwaInstallIosDialogBody,
      localizations.pwaInstallIosDialogCloseBtnLabel,
      localizations.pwaInstallAcceptedLabel,
      localizations.pwaInstallDismissedLabel,
      localizations.aboutAppDescription,
      localizations.aboutVersionLabel,
      localizations.aboutDeveloperLabel,
      localizations.aboutSourceCodeLabel,
      localizations.currencyAlertsBottomNavItemLabel,
      localizations.currencyAlertsSectionLabel,
      localizations.currencyAlertEmptyListLabel,
      localizations.addCurrencyAlertBtnLabel,
      localizations.addCurrencyAlertDialogTitle,
      localizations.currencyAlertCurrencyLabel,
      localizations.currencyAlertConditionLabel,
      localizations.currencyAlertConditionAbove,
      localizations.currencyAlertConditionBelow,
      localizations.currencyAlertTargetValueLabel,
      localizations.currencyAlertInvalidValueError,
      localizations.currencyAlertSaveBtnLabel,
      localizations.currencyAlertCancelBtnLabel,
      localizations.currencyAlertTriggeredLabel,
      localizations.currencyAlertActiveLabel,
      localizations.currencyAlertDeleteTooltip,
      localizations.currencyAlertNotificationTitle,
      localizations.currencyAlertNotificationBody,
      localizations.aiInsightsBottomNavItemLabel,
      localizations.aiInsightsSectionLabel,
      localizations.aiInsightsDescription,
      localizations.aiInsightsAssetLabel,
      localizations.aiInsightsAssetPickerTitle,
      localizations.aiInsightsAssetNotFoundLabel,
      localizations.aiInsightsHorizonLabel,
      localizations.aiInsightsHorizonOptionLabel,
      localizations.aiInsightsAmountLabel,
      localizations.aiInsightsAnalyzeBtnLabel,
      localizations.aiInsightsRunningLabel,
      localizations.aiInsightsEmptyLabel,
      localizations.aiInsightsNoDataError,
      localizations.aiInsightsInsufficientDataError,
      localizations.aiInsightsFailureError,
      localizations.aiInsightsSummarySectionLabel,
      localizations.aiInsightsProjectionSectionLabel,
      localizations.aiInsightsInsightsSectionLabel,
      localizations.aiInsightsModelSectionLabel,
      localizations.aiInsightsLastPriceLabel,
      localizations.aiInsightsWeeklyChangeLabel,
      localizations.aiInsightsMonthlyChangeLabel,
      localizations.aiInsightsVolatilityLabel,
      localizations.aiInsightsRsiLabel,
      localizations.aiInsightsDrawdownLabel,
      localizations.aiInsightsTrendLabel,
      localizations.aiInsightsTrendFitLabel,
      localizations.aiInsightsProjectedPriceLabel,
      localizations.aiInsightsProjectedChangeLabel,
      localizations.aiInsightsConfidenceBandLabel,
      localizations.aiInsightsAmountProjectionLabel,
      localizations.aiInsightsAmountProjectionHint,
      localizations.aiInsightsModelSamplesLabel,
      localizations.aiInsightsModelSkillLabel,
      localizations.aiInsightsModelEpochsLabel,
      localizations.aiInsightsModelUntrainedLabel,
      localizations.aiInsightsDisclaimerLabel,
      localizations.aiInsightsChartHistoryLabel,
      localizations.aiInsightsChartProjectionLabel,
      localizations.aiInsightTrendUp,
      localizations.aiInsightTrendDown,
      localizations.aiInsightTrendSideways,
      localizations.aiInsightMomentumOverbought,
      localizations.aiInsightMomentumOversold,
      localizations.aiInsightMomentumNeutral,
      localizations.aiInsightVolatilityHigh,
      localizations.aiInsightVolatilityLow,
      localizations.aiInsightProjectionUp,
      localizations.aiInsightProjectionDown,
      localizations.aiInsightProjectionStable,
      localizations.aiInsightDrawdown,
      localizations.aiInsightConfidenceGood,
      localizations.aiInsightConfidenceLow,
      localizations.aiInsightDataLimited,
    ];

/// Modelos de frase dos insights que recebem números do motor de análise, com
/// quantos marcadores cada um espera.
const Map<String, int> _insightPlaceholderCount = {
  'aiInsightTrendUp': 2,
  'aiInsightTrendDown': 2,
  'aiInsightTrendSideways': 2,
  'aiInsightMomentumOverbought': 1,
  'aiInsightMomentumOversold': 1,
  'aiInsightMomentumNeutral': 1,
  'aiInsightVolatilityHigh': 1,
  'aiInsightVolatilityLow': 1,
  'aiInsightProjectionUp': 3,
  'aiInsightProjectionDown': 3,
  'aiInsightProjectionStable': 2,
  'aiInsightDrawdown': 1,
  'aiInsightConfidenceGood': 1,
  'aiInsightDataLimited': 1,
};

String? _insightTemplate(MyAppLocalizations localizations, String key) =>
    switch (key) {
      'aiInsightTrendUp' => localizations.aiInsightTrendUp,
      'aiInsightTrendDown' => localizations.aiInsightTrendDown,
      'aiInsightTrendSideways' => localizations.aiInsightTrendSideways,
      'aiInsightMomentumOverbought' => localizations.aiInsightMomentumOverbought,
      'aiInsightMomentumOversold' => localizations.aiInsightMomentumOversold,
      'aiInsightMomentumNeutral' => localizations.aiInsightMomentumNeutral,
      'aiInsightVolatilityHigh' => localizations.aiInsightVolatilityHigh,
      'aiInsightVolatilityLow' => localizations.aiInsightVolatilityLow,
      'aiInsightProjectionUp' => localizations.aiInsightProjectionUp,
      'aiInsightProjectionDown' => localizations.aiInsightProjectionDown,
      'aiInsightProjectionStable' => localizations.aiInsightProjectionStable,
      'aiInsightDrawdown' => localizations.aiInsightDrawdown,
      'aiInsightConfidenceGood' => localizations.aiInsightConfidenceGood,
      'aiInsightDataLimited' => localizations.aiInsightDataLimited,
      _ => null,
    };

void main() {
  group('MyAppLocalizations', () {
    test('traduz para português', () {
      var localizations = MyAppLocalizations(const Locale("pt"));

      expect(localizations.conversionPageTitle, "Conversão de Moedas");
      expect(localizations.noDataLabel, "Sem Dados");
      expect(localizations.getConfigBottomNavItemLabel, "Opções");
    });

    test('traduz para inglês', () {
      var localizations = MyAppLocalizations(const Locale("en"));

      expect(localizations.conversionPageTitle, "Currency Conversion");
      expect(localizations.noDataLabel, "No Data");
      expect(localizations.getConfigBottomNavItemLabel, "Options");
    });

    test('os dois idiomas têm todos os textos preenchidos', () {
      var portuguese = _allLabels(MyAppLocalizations(const Locale("pt")));
      var english = _allLabels(MyAppLocalizations(const Locale("en")));

      expect(portuguese, isNot(contains(null)));
      expect(english, isNot(contains(null)));
      expect(portuguese.length, english.length);
    });

    test('os dois idiomas têm o mesmo número de marcadores nos insights', () {
      for (var locale in [const Locale("pt"), const Locale("en")]) {
        var localizations = MyAppLocalizations(locale);
        _insightPlaceholderCount.forEach((key, expectedCount) {
          var template = _insightTemplate(localizations, key);

          expect(template, isNotNull, reason: "$key em ${locale.languageCode}");
          expect("%s".allMatches(template!).length, expectedCount,
              reason: "$key em ${locale.languageCode}");
        });
      }
    });

    test('homeCurrenciesSelectedCountLabel traz o marcador da quantidade', () {
      expect(
          MyAppLocalizations(const Locale("pt"))
              .homeCurrenciesSelectedCountLabel,
          contains("%s"));
      expect(
          MyAppLocalizations(const Locale("en"))
              .homeCurrenciesSelectedCountLabel,
          contains("%s"));
    });

    test('homePageHeadsUpText traz o marcador de moeda', () {
      expect(MyAppLocalizations(const Locale("pt")).homePageHeadsUpText,
          contains("%s"));
      expect(MyAppLocalizations(const Locale("en")).homePageHeadsUpText,
          contains("%s"));
    });
  });

  group('MyAppLocalizationsDelegate', () {
    var delegate = MyAppLocalizationsDelegate();

    test('suporta apenas português e inglês', () {
      expect(delegate.isSupported(const Locale("pt")), isTrue);
      expect(delegate.isSupported(const Locale("en")), isTrue);
      expect(delegate.isSupported(const Locale("es")), isFalse);
    });

    test('ignora o país ao verificar o suporte', () {
      expect(delegate.isSupported(const Locale("pt", "BR")), isTrue);
    });

    test('carrega as traduções do locale pedido', () async {
      var localizations = await delegate.load(const Locale("pt"));

      expect(localizations.locale, const Locale("pt"));
      expect(localizations.noDataLabel, "Sem Dados");
    });

    test('nunca pede recarga', () {
      expect(delegate.shouldReload(MyAppLocalizationsDelegate()), isFalse);
    });

    testWidgets('fica acessível pelo contexto do widget',
        (WidgetTester tester) async {
      MyAppLocalizations? found;

      await tester.pumpWidget(MaterialApp(
        locale: const Locale("pt"),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          MyAppLocalizationsDelegate()
        ],
        supportedLocales: const [Locale("pt"), Locale("en")],
        home: Builder(builder: (context) {
          found = MyAppLocalizations.of(context);
          return const SizedBox();
        }),
      ));

      expect(found, isNotNull);
      expect(found!.conversionPageTitle, "Conversão de Moedas");
    });
  });
}
