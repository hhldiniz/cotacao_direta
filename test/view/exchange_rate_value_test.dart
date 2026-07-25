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
