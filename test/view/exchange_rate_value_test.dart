import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/exchange_value_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/view/widgets/exchange_rate_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bloc com a cotação já resolvida, para não tocar em banco nem em rede.
class _FakeExchangeValueBloc extends ExchangeValueBloc {
  final double? value;

  _FakeExchangeValueBloc(this.value);

  @override
  Future<double?> retrieveCurrencyValue(Currencies? currency) async => value;
}

void main() {
  Future<void> pumpExchangeRate(WidgetTester tester, double? value) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale("pt"),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MyAppLocalizationsDelegate()
      ],
      supportedLocales: const [Locale("pt"), Locale("en")],
      home: ExchangeValueBlocProvider(
        bloc: _FakeExchangeValueBloc(value),
        child: ExchangeRateValue(Currencies.USD),
      ),
    ));
    await tester.pump();
  }

  group('ExchangeRateValue', () {
    testWidgets('mostra Sem Dados quando não há cotação',
        (WidgetTester tester) async {
      await pumpExchangeRate(tester, null);

      expect(find.text("Sem Dados"), findsOneWidget);
    });

    testWidgets('mostra Sem Dados quando a cotação é zero',
        (WidgetTester tester) async {
      await pumpExchangeRate(tester, 0);

      expect(find.text("Sem Dados"), findsOneWidget);
    });

    testWidgets('mostra o valor convertido quando há cotação',
        (WidgetTester tester) async {
      await pumpExchangeRate(tester, 0.2);

      expect(find.text("5"), findsOneWidget);
      expect(find.text("Sem Dados"), findsNothing);
    });

    // O CurrencyRepository guarda o inverso do `bid` da AwesomeAPI justamente
    // para esta conta bater: um bid de 5,42 reais por dólar precisa aparecer
    // como 5,42 na tela.
    testWidgets('mostra a cotação da API na mesma orientação que ela publica',
        (WidgetTester tester) async {
      await pumpExchangeRate(tester, 1 / 5.42);

      expect(find.text("5.42"), findsOneWidget);
    });

    testWidgets(
        'mantém o valor após um rebuild da árvore (troca de aba e volta)',
        (WidgetTester tester) async {
      late StateSetter rebuild;

      // O StatefulBuilder por cima do ExchangeValueBlocProvider reproduz o
      // que o Home faz ao trocar de aba: chama setState, o que reconstrói a
      // subárvore inteira (novas instâncias de ExchangeValueBlocProvider e
      // ExchangeRateValue) sem que nenhum InheritedWidget do qual o widget
      // dependa realmente mude — então didChangeDependencies não é chamado
      // de novo, só build().
      await tester.pumpWidget(MaterialApp(
        locale: const Locale("pt"),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          MyAppLocalizationsDelegate()
        ],
        supportedLocales: const [Locale("pt"), Locale("en")],
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return ExchangeValueBlocProvider(
              bloc: _FakeExchangeValueBloc(0.2),
              child: ExchangeRateValue(Currencies.USD),
            );
          },
        ),
      ));
      await tester.pump();

      expect(find.text("5"), findsOneWidget);

      // Antes da correção, esse rebuild descartava o StreamController em uso
      // (getNextStreamController fechava e recriava o stream porque já
      // havia um listener) e nada mais empurrava um novo valor para ele, já
      // que nenhuma busca é refeita nesse tipo de rebuild.
      rebuild(() {});
      await tester.pump();

      expect(find.text("5"), findsOneWidget);
      expect(find.text(""), findsNothing);
      expect(find.text("Sem Dados"), findsNothing);
    });

    testWidgets('não mostra nada enquanto a cotação não chega',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale("pt"),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          MyAppLocalizationsDelegate()
        ],
        supportedLocales: const [Locale("pt"), Locale("en")],
        home: ExchangeValueBlocProvider(
          bloc: _FakeExchangeValueBloc(5.0),
          child: ExchangeRateValue(Currencies.USD),
        ),
      ));

      expect(find.text(""), findsOneWidget);
      expect(find.text("Sem Dados"), findsNothing);
    });
  });
}
