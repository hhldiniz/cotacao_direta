import 'package:cotacao_direta/blocs/conversion_page_bloc.dart';
import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/conversion_page_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/view/pages/conversion_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cotações fixas no lugar da busca real, na convenção do CurrencyRepository:
/// quantas unidades da moeda valem um real. O iene fica sem cotação, para a
/// tela ter um caso de "Sem Dados".
class _FakeExchangeValueBloc extends ExchangeValueBloc {
  static const _values = {
    Currencies.BRL: 1.0,
    Currencies.USD: 0.2,
    Currencies.EUR: 0.1,
    Currencies.JPY: null,
  };

  @override
  Future<double?> retrieveCurrencyValue(Currencies? currency) async =>
      _values[currency];
}

Widget _conversionApp(ConversionPageBloc bloc) => MaterialApp(
      locale: const Locale("pt"),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MyAppLocalizationsDelegate()
      ],
      supportedLocales: const [Locale("pt"), Locale("en")],
      home: ConversionPageBlocProvider(
          bloc: bloc, child: ConversionPage("Conversão de Moedas")),
    );

void main() {
  late ConversionPageBloc bloc;

  setUp(() => bloc =
      ConversionPageBloc(exchangeValueBloc: _FakeExchangeValueBloc()));

  tearDown(() => bloc.dispose());

  Future<void> pumpConversionPage(WidgetTester tester) async {
    await tester.pumpWidget(_conversionApp(bloc));
    await tester.pumpAndSettle();
  }

  /// Espera o intervalo entre a última tecla e a conversão.
  Future<void> settleTyping(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  /// Restringe a busca à lista do seletor: a tela por baixo dele mostra os
  /// mesmos códigos e nomes das moedas já escolhidas.
  Finder inCurrencyPicker(Finder finder) =>
      find.descendant(of: find.byType(ListView), matching: finder);

  Future<void> searchInCurrencyPicker(
      WidgetTester tester, String query) async {
    await tester.enterText(find.widgetWithIcon(TextField, Icons.search), query);
    await tester.pumpAndSettle();
  }

  group('ConversionPage', () {
    testWidgets('abre já com a conversão feita, sem esperar um toque',
        (WidgetTester tester) async {
      await pumpConversionPage(tester);

      expect(find.text("BRL"), findsOneWidget);
      expect(find.text("USD"), findsOneWidget);
      expect(find.text("0,200"), findsOneWidget,
          reason: "um real convertido para dólar");
      expect(find.text("1 BRL = 0,2000 USD"), findsOneWidget);
      expect(find.text("1 USD = 5,0000 BRL"), findsOneWidget,
          reason: "a cotação de volta poupa uma segunda conversão");
    });

    testWidgets('converte enquanto o usuário digita a quantidade',
        (WidgetTester tester) async {
      await pumpConversionPage(tester);

      await tester.enterText(find.byType(TextField), "10");
      await settleTyping(tester);

      expect(find.text("2,00"), findsOneWidget);
    });

    testWidgets('avisa quando a quantidade digitada não é um número',
        (WidgetTester tester) async {
      await pumpConversionPage(tester);

      await tester.enterText(find.byType(TextField), "1,2,3");
      await settleTyping(tester);

      expect(find.text("Informe um valor válido"), findsOneWidget);
    });

    testWidgets('inverter troca as moedas de lugar',
        (WidgetTester tester) async {
      await pumpConversionPage(tester);

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();

      expect(find.text("1 USD = 5,0000 BRL"), findsOneWidget,
          reason: "o par precisa aparecer invertido depois da troca");
    });

    testWidgets('escolhe a moeda por uma lista com busca',
        (WidgetTester tester) async {
      await pumpConversionPage(tester);

      await tester.tap(find.text("BRL"));
      await tester.pumpAndSettle();

      expect(find.text("Escolha a moeda"), findsOneWidget);
      // A lista é ordenada por nome e abre rolada na moeda escolhida, e não no
      // começo do alfabeto.
      expect(inCurrencyPicker(find.text("Real Brasileiro")), findsOneWidget,
          reason: "a lista mostra o nome da moeda, não só a sigla");

      await searchInCurrencyPicker(tester, "iene");

      expect(inCurrencyPicker(find.text("JPY")), findsOneWidget);
      expect(inCurrencyPicker(find.text("AUD")), findsNothing,
          reason: "a busca precisa filtrar a lista");
    });

    testWidgets('busca sem acento acha a moeda acentuada',
        (WidgetTester tester) async {
      await pumpConversionPage(tester);
      await tester.tap(find.text("BRL"));
      await tester.pumpAndSettle();

      await searchInCurrencyPicker(tester, "franco suico");

      expect(inCurrencyPicker(find.text("CHF")), findsOneWidget);
    });

    testWidgets('mostra "Sem Dados" para a moeda sem cotação',
        (WidgetTester tester) async {
      await pumpConversionPage(tester);
      await tester.tap(find.text("BRL"));
      await tester.pumpAndSettle();

      await searchInCurrencyPicker(tester, "iene");
      await tester.tap(inCurrencyPicker(find.text("JPY")));
      await tester.pumpAndSettle();

      expect(find.text("Sem Dados"), findsOneWidget);
      expect(find.text("Cotação indisponível"), findsOneWidget);
    });

    testWidgets('o seletor abre com as moedas da tela inicial em destaque',
        (WidgetTester tester) async {
      // As bolhas da tela inicial: elas chegam aqui pelo bloc e devem abrir a
      // lista, antes das outras trinta e tantas moedas.
      bloc.dispose();
      bloc = ConversionPageBloc(
          exchangeValueBloc: _FakeExchangeValueBloc(),
          priorityCurrencies: [Currencies.EUR, Currencies.BRL]);
      await pumpConversionPage(tester);

      await tester.tap(find.text("BRL"));
      await tester.pumpAndSettle();

      expect(find.text("Suas moedas"), findsOneWidget);
      expect(find.text("Todas as moedas"), findsOneWidget);
      expect(inCurrencyPicker(find.text("EUR")), findsOneWidget,
          reason: "a moeda em destaque não se repete no resto da lista");
      expect(
          tester.getTopLeft(inCurrencyPicker(find.text("EUR"))).dy,
          lessThan(tester.getTopLeft(find.text("Todas as moedas")).dy),
          reason: "as moedas da tela inicial vêm antes do resto da lista");
    });

    testWidgets('converte com a moeda escolhida na seção de destaque',
        (WidgetTester tester) async {
      bloc.dispose();
      bloc = ConversionPageBloc(
          exchangeValueBloc: _FakeExchangeValueBloc(),
          priorityCurrencies: [Currencies.EUR, Currencies.BRL]);
      await pumpConversionPage(tester);

      await tester.tap(find.text("BRL"));
      await tester.pumpAndSettle();
      await tester.tap(inCurrencyPicker(find.text("EUR")));
      await tester.pumpAndSettle();

      expect(find.text("1 EUR = 2,0000 USD"), findsOneWidget);
    });

    testWidgets('sem moedas em destaque a lista sai sem seções',
        (WidgetTester tester) async {
      await pumpConversionPage(tester);

      await tester.tap(find.text("BRL"));
      await tester.pumpAndSettle();

      expect(find.text("Suas moedas"), findsNothing);
      expect(find.text("Todas as moedas"), findsNothing);
    });

    testWidgets('a busca que não acha nenhuma moeda em destaque tira as seções',
        (WidgetTester tester) async {
      bloc.dispose();
      bloc = ConversionPageBloc(
          exchangeValueBloc: _FakeExchangeValueBloc(),
          priorityCurrencies: [Currencies.EUR, Currencies.BRL]);
      await pumpConversionPage(tester);

      await tester.tap(find.text("BRL"));
      await tester.pumpAndSettle();
      await searchInCurrencyPicker(tester, "iene");

      expect(find.text("Suas moedas"), findsNothing,
          reason: "uma seção vazia só ocuparia espaço");
      expect(inCurrencyPicker(find.text("JPY")), findsOneWidget);
    });

    testWidgets('a tela abre no par pedido pela tela inicial',
        (WidgetTester tester) async {
      bloc.dispose();
      bloc = ConversionPageBloc(
          exchangeValueBloc: _FakeExchangeValueBloc(),
          initialFromCurrency: Currencies.USD,
          initialToCurrency: Currencies.BRL);
      await pumpConversionPage(tester);

      expect(find.text("1 USD = 5,0000 BRL"), findsOneWidget);
    });

    testWidgets('escolher no destino a moeda de origem inverte o par',
        (WidgetTester tester) async {
      await pumpConversionPage(tester);

      await tester.tap(find.text("USD"));
      await tester.pumpAndSettle();
      await searchInCurrencyPicker(tester, "real");
      await tester.tap(inCurrencyPicker(find.text("BRL")));
      await tester.pumpAndSettle();

      expect(find.text("1 USD = 5,0000 BRL"), findsOneWidget,
          reason: "as duas pontas iguais não converteriam nada");
    });
  });
}
