import 'package:cotacao_direta/blocs/selected_currency_details_bloc.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers/fakes.dart';

DateTime _daysAgo(int days) {
  var today = DateTime.now();
  return DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: days));
}

void main() {
  late FakeCurrencyRepository currencyRepository;
  late SelectedCurrencyDetailsBloc bloc;

  setUp(() {
    currencyRepository = FakeCurrencyRepository();
    bloc = SelectedCurrencyDetailsBloc(currencyRepository: currencyRepository);
  });

  group('SelectedCurrencyDetailsBloc', () {
    test('a data inicial aparece formatada no campo', () {
      bloc.updateInitialDate(DateTime(2024, 3, 9));

      expect(bloc.initialDateController.text, "09/03/2024");
    });

    test('a data final aparece formatada no campo', () {
      bloc.updateFinalDate(DateTime(2024, 12, 31));

      expect(bloc.endDateController.text, "31/12/2024");
    });

    test('os dois campos são independentes', () {
      bloc.updateInitialDate(DateTime(2024, 1, 1));
      bloc.updateFinalDate(DateTime(2024, 2, 2));

      expect(bloc.initialDateController.text, "01/01/2024");
      expect(bloc.endDateController.text, "02/02/2024");
    });
  });

  group('SelectedCurrencyDetailsBloc: períodos rápidos', () {
    final apiDateFormatter = DateFormat("yyyy-MM-dd");

    test('a tela abre com o período padrão de sete dias', () {
      expect(SelectedCurrencyDetailsBloc.defaultPeriodInDays, 7);
    });

    test('os chips oferecidos são sete, quinze, trinta e trezentos e '
        'sessenta dias', () {
      expect(SelectedCurrencyDetailsBloc.quickPeriodOptions,
          [7, 15, 30, 360]);
    });

    test('nenhum chip começa marcado', () {
      expect(bloc.selectedPeriodInDays, isNull);
    });

    test('escolher um período preenche as duas datas e busca o histórico',
        () async {
      await bloc.selectPeriod(7, "USD");

      expect(bloc.selectedPeriodInDays, 7);
      expect(bloc.initialDateController.text,
          DateFormat("dd/MM/yyyy").format(_daysAgo(6)));
      expect(bloc.endDateController.text,
          DateFormat("dd/MM/yyyy").format(_daysAgo(0)));
      expect(currencyRepository.historicalDataCalls.single, [
        ["USD"],
        apiDateFormatter.format(_daysAgo(6)),
        apiDateFormatter.format(_daysAgo(0)),
      ]);
    });

    test('o intervalo inclui hoje, então quinze dias começam catorze dias '
        'atrás', () async {
      await bloc.selectPeriod(15, "USD");

      expect(currencyRepository.historicalDataCalls.single[1],
          apiDateFormatter.format(_daysAgo(14)));
    });

    test('escolher outro período marca o chip novo', () async {
      await bloc.selectPeriod(7, "USD");

      await bloc.selectPeriod(30, "USD");

      expect(bloc.selectedPeriodInDays, 30);
    });

    test('editar a data à mão desmarca o chip', () async {
      await bloc.selectPeriod(7, "USD");

      bloc.updateInitialDate(DateTime(2024, 1, 1));

      expect(bloc.selectedPeriodInDays, isNull);
    });

    test('editar a data final também desmarca o chip', () async {
      await bloc.selectPeriod(7, "USD");

      bloc.updateFinalDate(DateTime(2024, 1, 1));

      expect(bloc.selectedPeriodInDays, isNull);
    });

    test('anuncia o período marcado pela stream', () async {
      var emitted = <int?>[];
      bloc.selectedPeriodStream.listen(emitted.add);

      await bloc.selectPeriod(15, "USD");
      bloc.updateInitialDate(DateTime(2024, 1, 1));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [15, null]);
    });

    test('a stream do período não repete uma desmarcação já anunciada',
        () async {
      var emitted = <int?>[];
      bloc.selectedPeriodStream.listen(emitted.add);

      // Sem chip nenhum marcado, editar a data não deveria anunciar nada.
      bloc.updateInitialDate(DateTime(2024, 1, 1));
      bloc.updateFinalDate(DateTime(2024, 1, 2));

      await Future<void>.delayed(Duration.zero);
      expect(emitted, isEmpty);
    });

    test('mostra o histórico buscado na stream', () async {
      currencyRepository.historicalData = [
        Currency(id: "USD", value: 0.2, historicalDate: "2024-01-01")
      ];

      var emittedLoading = <bool>[];
      bloc.isLoadingStream.listen(emittedLoading.add);
      var history = bloc.currencyHistoryStream.first;

      await bloc.selectPeriod(7, "USD");
      await Future<void>.delayed(Duration.zero);

      expect(await history, currencyRepository.historicalData);
      expect(emittedLoading, [true, false]);
    });
  });

  group('SelectedCurrencyDetailsBloc.dispose', () {
    test('fecha a stream do histórico', () async {
      var stream = bloc.currencyHistoryStream;

      bloc.dispose();

      expect(await stream.isEmpty, isTrue);
    });

    test('fecha a stream do período marcado', () async {
      var stream = bloc.selectedPeriodStream;

      bloc.dispose();

      expect(await stream.isEmpty, isTrue);
    });

    test('descarta os controllers dos campos de data', () {
      var initialDateController = bloc.initialDateController;
      var endDateController = bloc.endDateController;

      bloc.dispose();

      expect(() => initialDateController.text = "01/01/2024",
          throwsA(isA<FlutterError>()));
      expect(() => endDateController.text = "01/01/2024",
          throwsA(isA<FlutterError>()));
    });

    test('um listener registrado não sobrevive ao dispose', () {
      var notified = 0;
      bloc.initialDateController.addListener(() => notified++);
      bloc.updateInitialDate(DateTime(2024, 1, 1));
      expect(notified, 1);

      bloc.dispose();

      expect(() => bloc.initialDateController.addListener(() {}),
          throwsA(isA<FlutterError>()));
    });
  });
}
