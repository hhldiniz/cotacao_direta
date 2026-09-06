import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/third_party_credits.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/about_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

Widget _aboutApp({Locale locale = const Locale("pt")}) => MaterialApp(
      locale: locale,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MyAppLocalizationsDelegate()
      ],
      supportedLocales: AppLocales.supported,
      home: Scaffold(body: AboutPage()),
    );

/// Rola a tela até o widget entrar em cena. A lista de créditos é longa e o
/// teste roda em uma janela pequena: sem isto, quase tudo fica fora da árvore
/// visível.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  setUp(() {
    // A tela lê a versão do app pelo package_info_plus, que sem isto tenta
    // falar com o canal da plataforma e falha na VM de teste.
    PackageInfo.setMockInitialValues(
      appName: "cotacao_direta",
      packageName: "com.example.cotacao_direta",
      version: "1.0.0",
      buildNumber: "1",
      buildSignature: "",
    );
  });

  group('ThirdPartyCredits', () {
    final all = [
      ...ThirdPartyCredits.dataSources,
      ...ThirdPartyCredits.fontsAndIcons,
      ...ThirdPartyCredits.software,
    ];

    test('todo crédito tem nome, autor, licença e endereço', () {
      expect(all, isNotEmpty);
      for (final credit in all) {
        expect(credit.name, isNotEmpty, reason: credit.name);
        expect(credit.copyright, isNotEmpty, reason: credit.name);
        expect(credit.license, isNotEmpty, reason: credit.name);
        expect(credit.url, startsWith("https://"), reason: credit.name);
      }
    });

    test('nenhuma obra é creditada duas vezes', () {
      final names = all.map((credit) => credit.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('as dependências diretas do pubspec estão creditadas', () {
      // As obras que o app embarca e cuja licença pede o crédito. Se uma
      // dependência entrar no pubspec.yaml sem passar por aqui, este teste
      // cai — é o lembrete de atualizar a tela "Sobre" junto.
      const expected = [
        "fl_chart",
        "flag",
        "flutter_local_notifications",
        "http",
        "intl",
        "package_info_plus",
        "path",
        "sprintf",
        "url_launcher",
        "workmanager",
      ];
      final names = all.map((credit) => credit.name).toSet();
      for (final name in expected) {
        expect(names, contains(name));
      }
      // O sqflite e suas variantes de plataforma entram sob um nome só.
      expect(names, contains("sqflite"));
      expect(names, contains("Cupertino Icons"));
    });

    test('as fontes de dados consultadas pelo app estão creditadas', () {
      final names =
          ThirdPartyCredits.dataSources.map((credit) => credit.name).toSet();
      expect(names, contains("AwesomeAPI"));
      expect(names, contains("REST Countries"));
    });

    test('o flag-icons é creditado, e não só o pacote que o redistribui', () {
      // O pacote `flag` traz os desenhos do flag-icons, que é MIT e pede o
      // aviso de direito autoral, mas redistribui só a própria licença.
      final flagIcons = ThirdPartyCredits.fontsAndIcons
          .firstWhere((credit) => credit.name == "flag-icons");
      expect(flagIcons.license, "MIT");
      expect(flagIcons.copyright, contains("Panayiotis Lipiridis"));
    });
  });

  group('AboutPage', () {
    testWidgets('mostra a seção de créditos', (WidgetTester tester) async {
      await tester.pumpWidget(_aboutApp());
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text("Créditos"));
      expect(find.text("Créditos"), findsOneWidget);
      expect(find.text("Fontes de dados"), findsOneWidget);
    });

    testWidgets('credita as fontes de dados com autor e licença',
        (WidgetTester tester) async {
      await tester.pumpWidget(_aboutApp());
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text("REST Countries"));
      expect(find.text("REST Countries"), findsOneWidget);
      expect(find.text("MPL-2.0"), findsOneWidget);
      expect(find.text("AwesomeAPI"), findsOneWidget);
    });

    testWidgets('credita as obras embarcadas que exigem atribuição',
        (WidgetTester tester) async {
      await tester.pumpWidget(_aboutApp());
      await tester.pumpAndSettle();

      for (final name in const ["Roboto", "flag-icons", "fl_chart"]) {
        await _scrollTo(tester, find.text(name));
        expect(find.text(name), findsOneWidget);
      }
      expect(
        find.text("Copyright (c) 2013 Panayiotis Lipiridis"),
        findsOneWidget,
      );
    });

    testWidgets('oferece o texto integral das licenças',
        (WidgetTester tester) async {
      await tester.pumpWidget(_aboutApp());
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text("Licenças completas"));
      await tester.tap(find.text("Licenças completas"));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('a seção de créditos é traduzida',
        (WidgetTester tester) async {
      await tester.pumpWidget(_aboutApp(locale: const Locale("en")));
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text("Credits"));
      expect(find.text("Credits"), findsOneWidget);
      expect(find.text("Data sources"), findsOneWidget);
    });
  });
}
