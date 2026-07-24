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
  @override
  Future<double?> retrieveCurrencyValue(Currencies? currency) async => 0.2;
}

Widget _app(Widget home) => MaterialApp(
      locale: const Locale("pt"),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MyAppLocalizationsDelegate()
      ],
      supportedLocales: const [Locale("pt"), Locale("en")],
      home: home,
    );

void main() {
  group('ExchangeValueBlocProvider', () {
    testWidgets('entrega o mesmo bloc para os widgets abaixo dele',
        (WidgetTester tester) async {
      var blocs = <ExchangeValueBloc>[];

      await tester.pumpWidget(ExchangeValueBlocProvider(
        child: Builder(builder: (context) {
          blocs.add(ExchangeValueBlocProvider.of(context));
          return const SizedBox();
        }),
      ));
      await tester.pump();

      expect(blocs, isNotEmpty);
      expect(blocs.every((bloc) => identical(bloc, blocs.first)), isTrue);
    });

    testWidgets('descarta o bloc que ele mesmo criou ao sair da árvore',
        (WidgetTester tester) async {
      late ExchangeValueBloc bloc;

      await tester.pumpWidget(ExchangeValueBlocProvider(
        child: Builder(builder: (context) {
          bloc = ExchangeValueBlocProvider.of(context);
          bloc.getNextStreamController();
          return const SizedBox();
        }),
      ));
      expect(bloc.valueController!.isClosed, isFalse);

      await tester.pumpWidget(const SizedBox());

      expect(bloc.valueController!.isClosed, isTrue);
    });

    testWidgets('não descarta o bloc que recebeu de fora',
        (WidgetTester tester) async {
      var bloc = ExchangeValueBloc();
      bloc.getNextStreamController();

      await tester.pumpWidget(
          ExchangeValueBlocProvider(bloc: bloc, child: const SizedBox()));
      await tester.pumpWidget(const SizedBox());

      expect(bloc.valueController!.isClosed, isFalse,
          reason: "quem cria o bloc é quem descarta");
      bloc.dispose();
    });

    testWidgets('o widget de cotação não descarta o bloc do provider',
        (WidgetTester tester) async {
      var bloc = _FakeExchangeValueBloc();

      await tester.pumpWidget(_app(ExchangeValueBlocProvider(
          bloc: bloc, child: ExchangeRateValue(Currencies.USD))));
      await tester.pump();

      // Troca só o filho: o provider (e o bloc) continuam de pé.
      await tester.pumpWidget(_app(
          ExchangeValueBlocProvider(bloc: bloc, child: const SizedBox())));

      expect(bloc.valueController!.isClosed, isFalse);
      bloc.dispose();
    });
  });

  group('ExchangeValueBloc.dispose', () {
    test('não estoura quando a stream nunca foi criada', () {
      expect(() => ExchangeValueBloc().dispose(), returnsNormally);
    });

    test('fecha a stream criada', () {
      var bloc = ExchangeValueBloc();
      bloc.getNextStreamController();

      bloc.dispose();

      expect(bloc.valueController!.isClosed, isTrue);
    });
  });
}
