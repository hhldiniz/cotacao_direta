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
      localizations.homeReorderHintLabel,
      localizations.homeReorderMoveEarlierLabel,
      localizations.homeReorderMoveLaterLabel,
      localizations.homeRemoveDropZoneLabel,
      localizations.homeRemoveCardLabel,
      localizations.homeAddCurrencyCardLabel,
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
      localizations.conversionHistorySectionLabel,
      localizations.conversionHistoryUnavailableLabel,
      localizations.mainCurrenciesBottomNavItemLabel,
      localizations.currencyHistoryBottomNavItemLabel,
      localizations.aboutBottomNavItemLabel,
      localizations.currencyHistoryFromDateLabel,
      localizations.currencyHistoryToDateLabel,
      localizations.currencyHistoryCurrenciesSectionLabel,
      localizations.currencyHistoryCryptocurrenciesSectionLabel,
      localizations.noDataLabel,
      localizations.getCurrencyHistoryBtnLabel,
      localizations.currencyHistoryPeriodOptionLabel,
      localizations.getConfigBottomNavItemLabel,
      localizations.overrideDefaultCurrencySwitchLabel,
      localizations.selectedOverrideCurrencyLabel,
      localizations.homeCurrenciesPickerTitle,
      localizations.homeCurrenciesPickerDescription,
      localizations.homeCurrenciesSelectedCountLabel,
      localizations.homeCurrenciesEmptySelectionLabel,
      localizations.homeCurrenciesSaveBtnLabel,
      localizations.appLanguageSettingLabel,
      localizations.appLanguageSystemOptionLabel,
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
      localizations.notificationPermissionCardLabel,
      localizations.notificationPermissionCardDescription,
      localizations.notificationPermissionBtnLabel,
      localizations.notificationPermissionDeniedDescription,
      localizations.notificationPermissionIosDescription,
      localizations.notificationPermissionGrantedLabel,
      localizations.notificationPermissionRefusedLabel,
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

    test('traduz para o espanhol da Espanha', () {
      var localizations = MyAppLocalizations(const Locale("es", "ES"));

      expect(localizations.conversionPageTitle, "Conversión de divisas");
      expect(localizations.noDataLabel, "Sin datos");
      expect(localizations.getConfigBottomNavItemLabel, "Ajustes");
    });

    test('traduz para o espanhol da América Latina', () {
      var localizations = MyAppLocalizations(const Locale("es", "419"));

      expect(localizations.conversionPageTitle, "Conversión de monedas");
      expect(localizations.noDataLabel, "Sin datos");
      expect(localizations.getConfigBottomNavItemLabel, "Configuración");
    });

    // As duas normas do espanhol são traduções separadas justamente porque o
    // vocabulário muda; se as duas tivessem o mesmo texto em toda parte, uma
    // delas não estaria pagando o que custa.
    test('as duas normas do espanhol não são a mesma tradução', () {
      var spain = _allLabels(MyAppLocalizations(const Locale("es", "ES")));
      var latinAmerica =
          _allLabels(MyAppLocalizations(const Locale("es", "419")));

      expect(spain, isNot(latinAmerica));
    });

    test('um idioma do aparelho sem tradução cai no primeiro da build', () {
      var localizations = MyAppLocalizations(const Locale("fr"));

      expect(localizations.conversionPageTitle, "Currency Conversion");
    });

    test('todos os idiomas têm todos os textos preenchidos', () {
      var byLocale = {
        for (var locale in AppLocales.supported)
          AppLocales.tagOf(locale): _allLabels(MyAppLocalizations(locale))
      };

      byLocale.forEach((tag, labels) {
        expect(labels, isNot(contains(null)), reason: "faltam textos em $tag");
        expect(labels.length, byLocale.values.first.length, reason: tag);
      });
    });

    test('todos os idiomas têm o mesmo número de marcadores nos insights', () {
      for (var locale in AppLocales.supported) {
        var localizations = MyAppLocalizations(locale);
        var tag = AppLocales.tagOf(locale);
        _insightPlaceholderCount.forEach((key, expectedCount) {
          var template = _insightTemplate(localizations, key);

          expect(template, isNotNull, reason: "$key em $tag");
          expect("%s".allMatches(template!).length, expectedCount,
              reason: "$key em $tag");
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

    // O título do gráfico da conversão traz o número de dias que o bloc fixou;
    // sem o marcador, o texto diria um período diferente do desenhado.
    test('conversionHistorySectionLabel traz o marcador de dias', () {
      for (var locale in AppLocales.supported) {
        expect(MyAppLocalizations(locale).conversionHistorySectionLabel,
            contains("%s"),
            reason: AppLocales.tagOf(locale));
      }
    });

    // O rótulo de cada chip de período traz o número de dias que o bloc
    // calculou; sem o marcador, todo chip diria o mesmo texto.
    test('currencyHistoryPeriodOptionLabel traz o marcador de dias', () {
      for (var locale in AppLocales.supported) {
        expect(MyAppLocalizations(locale).currencyHistoryPeriodOptionLabel,
            contains("%s"),
            reason: AppLocales.tagOf(locale));
      }
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

    test('suporta apenas os idiomas da build', () {
      expect(delegate.isSupported(const Locale("pt")), isTrue);
      expect(delegate.isSupported(const Locale("en")), isTrue);
      expect(delegate.isSupported(const Locale("es")), isTrue);
      expect(delegate.isSupported(const Locale("fr")), isFalse);
    });

    test('ignora o país quando ele não separa duas traduções', () {
      expect(delegate.isSupported(const Locale("pt", "BR")), isTrue);
    });

    test('atende qualquer país de língua espanhola', () {
      expect(delegate.isSupported(const Locale("es", "MX")), isTrue);
      expect(delegate.isSupported(const Locale("es", "AR")), isTrue);
    });

    test('carrega a tradução espanhola da região pedida', () async {
      var mexico = await delegate.load(const Locale("es", "MX"));
      var spain = await delegate.load(const Locale("es", "ES"));

      expect(mexico.getConfigBottomNavItemLabel, "Configuración");
      expect(spain.getConfigBottomNavItemLabel, "Ajustes");
    });

    test('carrega as traduções do locale pedido', () async {
      var localizations = await delegate.load(const Locale("pt"));

      expect(localizations.locale, const Locale("pt"));
      expect(localizations.noDataLabel, "Sem Dados");
    });

    // A resolução do idioma do aparelho é do MaterialApp, e sem o callback do
    // AppLocales quem está no México abriria o app na tradução da Espanha.
    testWidgets('um aparelho na América Latina abre no espanhol de lá',
        (WidgetTester tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale("es", "MX")];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      MyAppLocalizations? found;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          MyAppLocalizationsDelegate()
        ],
        supportedLocales: AppLocales.supported,
        localeListResolutionCallback: AppLocales.resolveDeviceLocales,
        home: Builder(builder: (context) {
          found = MyAppLocalizations.of(context);
          return const SizedBox();
        }),
      ));

      expect(found!.locale, const Locale("es", "419"));
      expect(found!.conversionPageTitle, "Conversión de monedas");
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

  group('AppLocales', () {
    test('lista os idiomas que existem na build', () {
      expect(AppLocales.supported, const [
        Locale("en"),
        Locale("pt"),
        Locale("es", "ES"),
        Locale("es", "419")
      ]);
    });

    // A lista da tela de opções sai daqui: um idioma sem nome apareceria como
    // uma etiqueta solta para o usuário.
    test('todo idioma da build tem um nome para mostrar', () {
      for (var locale in AppLocales.supported) {
        var tag = AppLocales.tagOf(locale);
        expect(AppLocales.displayNames[tag], isNotNull,
            reason: "falta o nome de $tag");
      }
    });

    test('tagOf só traz a região quando ela separa duas traduções', () {
      expect(AppLocales.tagOf(const Locale("pt")), "pt");
      expect(AppLocales.tagOf(const Locale("es", "419")), "es-419");
    });

    test('displayNameOf devolve a própria etiqueta quando não há nome', () {
      expect(AppLocales.displayNameOf("pt"), "Português");
      expect(AppLocales.displayNameOf("es-ES"), "Español (España)");
      expect(AppLocales.displayNameOf("es-419"), "Español (Latinoamérica)");
      expect(AppLocales.displayNameOf("xx"), "xx");
    });

    test('isSupported reconhece só o que está na build', () {
      expect(AppLocales.isSupported("pt"), isTrue);
      expect(AppLocales.isSupported("en"), isTrue);
      expect(AppLocales.isSupported("es-419"), isTrue);
      expect(AppLocales.isSupported("es"), isFalse);
      expect(AppLocales.isSupported("fr"), isFalse);
      expect(AppLocales.isSupported(""), isFalse);
      expect(AppLocales.isSupported(null), isFalse);
    });

    test('localeFor converte a etiqueta gravada', () {
      expect(AppLocales.localeFor("pt"), const Locale("pt"));
      expect(AppLocales.localeFor("es-ES"), const Locale("es", "ES"));
      expect(AppLocales.localeFor("es-419"), const Locale("es", "419"));
    });

    // O banco grava em caixa baixa, e uma etiqueta montada a partir de um
    // Locale vem com "_" no lugar do "-".
    test('localeFor não se prende à caixa nem ao separador', () {
      expect(AppLocales.localeFor("es-es"), const Locale("es", "ES"));
      expect(AppLocales.localeFor("es_419"), const Locale("es", "419"));
      expect(AppLocales.localeFor(" PT "), const Locale("pt"));
    });

    // Vazio, nulo ou fora da build significam "seguir o aparelho", que é o que
    // um locale nulo faz no MaterialApp.
    test('localeFor devolve nulo quando não há idioma a fixar', () {
      expect(AppLocales.localeFor(""), isNull);
      expect(AppLocales.localeFor(null), isNull);
      expect(AppLocales.localeFor("fr"), isNull);
    });

    test('tagFor devolve a forma canônica da etiqueta gravada', () {
      expect(AppLocales.tagFor("es-es"), "es-ES");
      expect(AppLocales.tagFor("es_419"), "es-419");
      expect(AppLocales.tagFor("fr"), "");
      expect(AppLocales.tagFor(null), "");
    });

    test('resolve escolhe a tradução do país do aparelho', () {
      expect(AppLocales.resolve(const Locale("es", "MX")),
          const Locale("es", "419"));
      expect(AppLocales.resolve(const Locale("es", "AR")),
          const Locale("es", "419"));
      expect(AppLocales.resolve(const Locale("es", "US")),
          const Locale("es", "419"));
      expect(AppLocales.resolve(const Locale("es", "ES")),
          const Locale("es", "ES"));
    });

    // Sem região não dá para adivinhar o país, e a norma da Espanha é a que o
    // CLDR pendura em "es".
    test('resolve manda o espanhol sem região para a Espanha', () {
      expect(AppLocales.resolve(const Locale("es")), const Locale("es", "ES"));
      expect(AppLocales.resolve(const Locale("es", "GQ")),
          const Locale("es", "ES"));
    });

    test('resolve ignora a região dos idiomas com uma tradução só', () {
      expect(AppLocales.resolve(const Locale("pt", "BR")), const Locale("pt"));
      expect(AppLocales.resolve(const Locale("en", "GB")), const Locale("en"));
    });

    test('resolve devolve nulo para um idioma que não está na build', () {
      expect(AppLocales.resolve(const Locale("fr")), isNull);
      expect(AppLocales.resolve(null), isNull);
    });

    test('resolveDeviceLocales segue a ordem de preferência do aparelho', () {
      expect(
          AppLocales.resolveDeviceLocales(
              const [Locale("fr"), Locale("es", "CO")], AppLocales.supported),
          const Locale("es", "419"));
    });

    // O mesmo que o Flutter faz quando nenhum idioma do aparelho corresponde.
    test('resolveDeviceLocales cai no primeiro idioma da build', () {
      expect(AppLocales.resolveDeviceLocales(null, AppLocales.supported),
          const Locale("en"));
      expect(
          AppLocales.resolveDeviceLocales(
              const [Locale("fr")], AppLocales.supported),
          const Locale("en"));
    });
  });
}
