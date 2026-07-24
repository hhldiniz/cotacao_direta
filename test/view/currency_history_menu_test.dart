import 'dart:convert';

import 'package:cotacao_direta/blocs/currency_history_menu_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/currency_history_menu_bloc_provider.dart';
import 'package:cotacao_direta/repository/country_names_repository.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/currency_history_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Na aplicação a lista fica dentro do Scaffold da home; o ListTile precisa
// desse Material acima dele.
Widget _menuApp(CurrencyHistoryMenuBloc bloc) => MaterialApp(
    home: Scaffold(
        body: CurrencyHistoryMenuBlocProvider(
            bloc: bloc, child: CurrencyHistory())));

void main() {
  late int requests;

  setUp(() => requests = 0);

  CurrencyHistoryMenuBloc buildBloc() {
    return CurrencyHistoryMenuBloc(countryNamesRepository:
        CountryNamesRepository(httpClient: MockClient((request) async {
      requests++;
      return http.Response.bytes(utf8.encode('[{"name": "Brazil"}]'), 200,
          headers: {"content-type": "application/json; charset=utf-8"});
    })));
  }

  Future<CurrencyHistoryMenuBloc> pumpMenu(WidgetTester tester) async {
    var bloc = buildBloc();
    await tester.pumpWidget(_menuApp(bloc));
    return bloc;
  }

  group('CurrencyHistory', () {
    testWidgets('mostra o nome do país de cada moeda',
        (WidgetTester tester) async {
      await pumpMenu(tester);

      // pumpAndSettle não terminaria se cada resposta provocasse um rebuild
      // que dispara outra requisição.
      await tester.pumpAndSettle();

      expect(find.text("AUD"), findsOneWidget,
          reason: "a primeira moeda da lista precisa aparecer");
      expect(find.text("Brazil"), findsWidgets);
    });

    testWidgets('consulta a API uma vez por moeda visível',
        (WidgetTester tester) async {
      await pumpMenu(tester);
      await tester.pumpAndSettle();
      var afterFirstFrame = requests;

      await tester.pump(const Duration(seconds: 1));

      expect(requests, afterFirstFrame,
          reason: "a lista não pode buscar de novo a cada rebuild");
      expect(afterFirstFrame, lessThanOrEqualTo(Currencies.values.length),
          reason: "no máximo uma consulta por moeda");
    });

    testWidgets('reaproveita os controllers quando a lista é reconstruída',
        (WidgetTester tester) async {
      var bloc = await pumpMenu(tester);
      await tester.pumpAndSettle();
      var stream = bloc.getCountryNameController("USD");

      await tester.pumpWidget(_menuApp(bloc));
      await tester.pumpAndSettle();

      expect(bloc.getCountryNameController("USD"), stream);
      expect(find.text("Brazil"), findsWidgets,
          reason: "o nome guardado precisa reaparecer sem nova consulta");
    });
  });
}
