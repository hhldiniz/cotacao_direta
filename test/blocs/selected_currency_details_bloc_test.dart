import 'package:cotacao_direta/blocs/selected_currency_details_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SelectedCurrencyDetailsBloc bloc;

  setUp(() => bloc = SelectedCurrencyDetailsBloc());

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

  group('SelectedCurrencyDetailsBloc.dispose', () {
    test('fecha a stream do histórico', () async {
      var stream = bloc.currencyHistoryStream;

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
