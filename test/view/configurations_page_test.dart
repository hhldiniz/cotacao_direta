import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/providers/configurations_page_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/configurations_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

// Na aplicação a tela fica dentro do Scaffold da home, e as localizações são
// registradas no MaterialApp raiz.
Widget _configurationsApp(ConfigurationsPageBloc bloc) => MaterialApp(
    locale: const Locale("pt"),
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      MyAppLocalizationsDelegate()
    ],
    supportedLocales: const [Locale("pt"), Locale("en")],
    home: Scaffold(
        body: ConfigurationsPageBlocProvider(
            bloc: bloc, child: ConfigurationsPage())));

void main() {
  // Um repositório em memória no lugar do banco: em teste de widget o relógio
  // é simulado, e esperar por E/S de verdade travaria o teste.
  late FakeConfigurationRepository repository;
  late ConfigurationsPageBloc bloc;

  setUp(() {
    repository = FakeConfigurationRepository();
    bloc = ConfigurationsPageBloc(configurationRepository: repository);
  });

  tearDown(() => bloc.dispose());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(_configurationsApp(bloc));
    await tester.pumpAndSettle();
  }

  /// Abre a folha de escolha das moedas da tela inicial.
  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.text("Cotações na tela inicial"));
    await tester.pumpAndSettle();
  }

  /// Filtra a lista pelo código e marca (ou desmarca) a moeda encontrada.
  Future<void> toggleCurrency(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextField), code);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, code));
    await tester.pumpAndSettle();
  }

  group('ConfigurationsPage e as moedas da tela inicial', () {
    testWidgets('mostra as moedas gravadas', (WidgetTester tester) async {
      repository.configuration =
          Configuration(1, homeCurrencyCodes: ["GBP", "CHF"]);

      await pumpPage(tester);

      expect(find.text("Cotações na tela inicial"), findsOneWidget);
      expect(find.text("GBP · CHF"), findsOneWidget);
    });

    testWidgets('abre a folha de escolha ao tocar na opção',
        (WidgetTester tester) async {
      await pumpPage(tester);

      await openPicker(tester);

      expect(find.text("Cotações mostradas em bolhas"), findsOneWidget);
      expect(find.text("Salvar"), findsOneWidget);
    });

    testWidgets('acrescenta a moeda escolhida às bolhas',
        (WidgetTester tester) async {
      await pumpPage(tester);
      await openPicker(tester);

      await toggleCurrency(tester, "CHF");
      await tester.tap(find.text("Salvar"));
      await tester.pumpAndSettle();

      expect(bloc.homeCurrencyCodes,
          [...Configuration.defaultHomeCurrencyCodes, "CHF"]);
      expect(repository.configuration.homeCurrencyCodes,
          [...Configuration.defaultHomeCurrencyCodes, "CHF"]);
    });

    testWidgets('desmarcar tira a moeda das bolhas',
        (WidgetTester tester) async {
      await pumpPage(tester);
      await openPicker(tester);

      await toggleCurrency(tester, "JPY");
      await tester.tap(find.text("Salvar"));
      await tester.pumpAndSettle();

      expect(bloc.homeCurrencyCodes, ["USD", "EUR", "CAD"]);
      expect(find.text("USD · EUR · CAD"), findsOneWidget);
    });

    // Sem nenhuma moeda a tela inicial ficaria sem cotação nenhuma.
    testWidgets('não deixa gravar uma escolha vazia',
        (WidgetTester tester) async {
      await pumpPage(tester);
      await openPicker(tester);

      for (var code in Configuration.defaultHomeCurrencyCodes) {
        await toggleCurrency(tester, code);
      }

      expect(find.text("Escolha pelo menos uma moeda"), findsOneWidget);
      expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
          reason: "o botão de salvar fica desabilitado sem nenhuma moeda");
    });

    testWidgets('fechar sem confirmar não muda nada',
        (WidgetTester tester) async {
      await pumpPage(tester);
      await openPicker(tester);

      await toggleCurrency(tester, "CHF");
      // Fecha a folha como o toque fora dela faria.
      Navigator.of(tester.element(find.byType(FilledButton))).pop();
      await tester.pumpAndSettle();

      expect(bloc.homeCurrencyCodes, Configuration.defaultHomeCurrencyCodes);
    });
  });
}
