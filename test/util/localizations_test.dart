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
      localizations.convertActionBtnLabel,
      localizations.conversionMultiplierHint,
      localizations.conversionPageExplanationText,
      localizations.mainCurrenciesBottomNavItemLabel,
      localizations.currencyHistoryBottomNavItemLabel,
      localizations.aboutBottomNavItemLabel,
      localizations.currencyHistoryFromDateLabel,
      localizations.currencyHistoryToDateLabel,
      localizations.noDataLabel,
      localizations.getCurrencyHistoryBtnLabel,
      localizations.getConfigBottomNavItemLabel,
      localizations.overrideDefaultCurrencySwitchLabel,
      localizations.appConfigurationsSectionLabel,
      localizations.aboutAppDescription,
      localizations.aboutVersionLabel,
      localizations.aboutDeveloperLabel,
      localizations.aboutSourceCodeLabel,
    ];

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
