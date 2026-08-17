import 'package:cotacao_direta/blocs/selected_currency_details_bloc.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/view/pages/selected_currency_details.dart';
import 'package:cotacao_direta/view/widgets/charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers/fakes.dart';

DateTime _daysAgo(int days) {
  var today = DateTime.now();
  return DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: days));
}

/// Uma cotação de um dia, na convenção do CurrencyRepository.
Currency _quote(int daysAgo, double value) => Currency(
    id: "USD", value: value, historicalDate: _daysAgo(daysAgo).toIso8601String());

Widget _detailsApp(SelectedCurrencyDetailsBloc bloc) => MaterialApp(
      locale: const Locale("pt"),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MyAppLocalizationsDelegate()
      ],
      supportedLocales: const [Locale("pt"), Locale("en")],
      home: SelectedCurrencyDetailsBlocProvider(
        bloc: bloc,
        child: SelectedCurrencyDetails(selectedCurrencyCode: "USD"),
      ),
    );

void main() {
  late FakeCurrencyRepository currencyRepository;
  late SelectedCurrencyDetailsBloc bloc;

  setUp(() {
    currencyRepository = FakeCurrencyRepository();
    currencyRepository.historicalData = [
      _quote(6, 0.19),
      _quote(3, 0.2),
      _quote(0, 0.21),
    ];
    bloc = SelectedCurrencyDetailsBloc(currencyRepository: currencyRepository);
  });

  tearDown(() => bloc.dispose());

  Future<void> pumpDetails(WidgetTester tester) async {
    await tester.pumpWidget(_detailsApp(bloc));
    await tester.pumpAndSettle();
  }

  group('SelectedCurrencyDetails', () {
    testWidgets('abre já buscando os últimos sete dias',
        (WidgetTester tester) async {
      await pumpDetails(tester);

      var dateFormatter = DateFormat("dd/MM/yyyy");
      expect(currencyRepository.historicalDataCalls.single.first, ["USD"]);
      expect(bloc.initialDateController.text,
          dateFormatter.format(_daysAgo(6)));
      expect(bloc.endDateController.text, dateFormatter.format(_daysAgo(0)));
      expect(find.byType(SimpleLineChart), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, "7 dias"), findsOneWidget);
    });

    testWidgets('o chip de sete dias começa marcado',
        (WidgetTester tester) async {
      await pumpDetails(tester);

      var chip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, "7 dias"));
      expect(chip.selected, isTrue);
    });

    testWidgets('mostra um chip para cada período rápido',
        (WidgetTester tester) async {
      await pumpDetails(tester);

      for (var days in SelectedCurrencyDetailsBloc.quickPeriodOptions) {
        expect(find.widgetWithText(ChoiceChip, "$days dias"), findsOneWidget,
            reason: "faltou o chip de $days dias");
      }
    });

    testWidgets('tocar em outro chip busca o período correspondente',
        (WidgetTester tester) async {
      await pumpDetails(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, "30 dias"));
      await tester.pumpAndSettle();

      var dateFormatter = DateFormat("dd/MM/yyyy");
      expect(bloc.initialDateController.text,
          dateFormatter.format(_daysAgo(29)));
      expect(bloc.endDateController.text, dateFormatter.format(_daysAgo(0)));
      expect(currencyRepository.historicalDataCalls, hasLength(2),
          reason: "a busca automática mais o toque no chip");

      var sevenDaysChip =
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, "7 dias"));
      var thirtyDaysChip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, "30 dias"));
      expect(sevenDaysChip.selected, isFalse);
      expect(thirtyDaysChip.selected, isTrue);
    });

    testWidgets('sem histórico no período mostra o aviso de sem dados',
        (WidgetTester tester) async {
      currencyRepository.historicalData = [];

      await pumpDetails(tester);

      expect(find.text("Sem Dados"), findsOneWidget);
      expect(find.byType(SimpleLineChart), findsNothing);
    });

    testWidgets('o botão de buscar refaz a consulta com as datas atuais',
        (WidgetTester tester) async {
      await pumpDetails(tester);

      await tester.tap(find.text("Obter histórico"));
      await tester.pumpAndSettle();

      expect(currencyRepository.historicalDataCalls, hasLength(2));
    });
  });
}
