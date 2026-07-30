import 'package:cotacao_direta/blocs/ai_insights_bloc.dart';
import 'package:cotacao_direta/providers/ai_insights_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/ai_insights_page.dart';
import 'package:cotacao_direta/view/widgets/forecast_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/series_test_helper.dart';

void main() {
  late FakeCurrencyRepository repository;
  late AiInsightsBloc bloc;

  final localizations = MyAppLocalizations(const Locale("pt"));

  setUp(() {
    repository = FakeCurrencyRepository()
      ..historicalData = quoteHistoryFromPrices(
          syntheticPrices(length: 150, dailyDrift: 0.002));
    bloc = AiInsightsBloc(currencyRepository: repository);
  });

  tearDown(() => bloc.dispose());

  Future<void> pumpPage(WidgetTester tester) async {
    // Tela alta: a página é uma lista rolável e os widgets fora da área
    // visível não entram na árvore, o que esconderia o resultado do find.
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale("pt"),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MyAppLocalizationsDelegate()
      ],
      supportedLocales: const [Locale("pt"), Locale("en")],
      home: Scaffold(
        body: AiInsightsBlocProvider(bloc: bloc, child: AiInsightsPage()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('AiInsightsPage', () {
    testWidgets('abre explicando que o modelo roda no aparelho',
        (WidgetTester tester) async {
      await pumpPage(tester);

      expect(find.text(localizations.aiInsightsSectionLabel!), findsOneWidget);
      expect(find.text(localizations.aiInsightsDescription!), findsOneWidget);
      expect(find.text(localizations.aiInsightsEmptyLabel!), findsOneWidget);
      expect(find.text(localizations.aiInsightsDisclaimerLabel!),
          findsOneWidget);
    });

    testWidgets('não analisa nada antes de o usuário pedir',
        (WidgetTester tester) async {
      await pumpPage(tester);

      expect(repository.historicalDataCalls, isEmpty);
    });

    testWidgets('mostra resumo, projeção e gráfico depois da análise',
        (WidgetTester tester) async {
      await pumpPage(tester);

      await tester.tap(find.text(localizations.aiInsightsAnalyzeBtnLabel!));
      await tester.pumpAndSettle();

      expect(find.text(localizations.aiInsightsSummarySectionLabel!),
          findsOneWidget);
      // "Projeção" aparece duas vezes: no título da seção e na legenda do
      // gráfico.
      expect(find.text(localizations.aiInsightsProjectionSectionLabel!),
          findsWidgets);
      expect(find.text(localizations.aiInsightsInsightsSectionLabel!),
          findsOneWidget);
      expect(find.byType(ForecastChart), findsOneWidget);
    });

    testWidgets('a análise roda no idioma da tela', (WidgetTester tester) async {
      await pumpPage(tester);

      await tester.tap(find.text(localizations.aiInsightsAnalyzeBtnLabel!));
      await tester.pumpAndSettle();

      // Em português os números saem com vírgula decimal.
      expect(
          bloc.currentState.analysis!.insights
              .expand((insight) => insight.arguments)
              .any((argument) => argument.contains(",")),
          isTrue);
    });

    testWidgets('sem cotação nenhuma mostra o aviso de falta de dados',
        (WidgetTester tester) async {
      repository.historicalData = [];
      await pumpPage(tester);

      await tester.tap(find.text(localizations.aiInsightsAnalyzeBtnLabel!));
      await tester.pumpAndSettle();

      expect(find.text(localizations.aiInsightsNoDataError!), findsOneWidget);
    });

    testWidgets('falha na busca mostra o aviso genérico',
        (WidgetTester tester) async {
      repository.failure = Exception("sem rede");
      await pumpPage(tester);

      await tester.tap(find.text(localizations.aiInsightsAnalyzeBtnLabel!));
      await tester.pumpAndSettle();

      expect(find.text(localizations.aiInsightsFailureError!), findsOneWidget);
    });

    testWidgets('o valor digitado aparece como simulação',
        (WidgetTester tester) async {
      await pumpPage(tester);
      await tester.tap(find.text(localizations.aiInsightsAnalyzeBtnLabel!));
      await tester.pumpAndSettle();
      expect(find.text(localizations.aiInsightsAmountProjectionLabel!),
          findsNothing);

      await tester.enterText(find.byType(TextField), "1.000,00");
      await tester.pumpAndSettle();

      expect(find.text(localizations.aiInsightsAmountProjectionLabel!),
          findsOneWidget);
      expect(bloc.simulationAmount, 1000);
    });

    testWidgets('trocar o horizonte refaz a projeção',
        (WidgetTester tester) async {
      await pumpPage(tester);
      await tester.tap(find.text(localizations.aiInsightsAnalyzeBtnLabel!));
      await tester.pumpAndSettle();

      await tester.tap(find.text("30 dias"));
      await tester.pumpAndSettle();

      expect(bloc.horizonInDays, 30);
      expect(bloc.currentState.analysis!.forecast.points.length, 30);
    });

    testWidgets('a moeda de contrapartida fica fora da lista de ativos',
        (WidgetTester tester) async {
      await pumpPage(tester);

      // O campo mostra o ativo selecionado; tocar nele abre a lista.
      await tester.tap(find.text("USD").first);
      await tester.pumpAndSettle();

      // BRL é a contrapartida das cotações: não há série de BRL contra BRL.
      expect(find.text("BRL"), findsNothing);
      expect(find.text("EUR"), findsWidgets);
    });
  });
}
