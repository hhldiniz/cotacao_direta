import 'dart:convert';

import 'package:cotacao_direta/blocs/currency_history_menu_bloc.dart';
import 'package:cotacao_direta/enums/cryptocurrency_enum.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/providers/currency_history_menu_bloc_provider.dart';
import 'package:cotacao_direta/repository/country_names_repository.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/view/pages/main_menu_items/currency_history_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fakes.dart';

// Na aplicação a lista fica dentro do Scaffold da home; o ListTile precisa
// desse Material acima dele. Os títulos de seção vêm das localizações, que na
// aplicação são registradas no MaterialApp raiz.
Widget _menuApp(CurrencyHistoryMenuBloc bloc) => MaterialApp(
    locale: const Locale("pt"),
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      MyAppLocalizationsDelegate()
    ],
    supportedLocales: const [Locale("pt"), Locale("en")],
    home: Scaffold(
        body: CurrencyHistoryMenuBlocProvider(
            bloc: bloc, child: CurrencyHistory())));

void main() {
  late int requests;

  setUp(() => requests = 0);

  CurrencyHistoryMenuBloc buildBloc({Configuration? configuration}) {
    return CurrencyHistoryMenuBloc(
        countryNamesRepository:
            CountryNamesRepository(httpClient: MockClient((request) async {
          requests++;
          return http.Response.bytes(utf8.encode('[{"name": "Brazil"}]'), 200,
              headers: {"content-type": "application/json; charset=utf-8"});
        })),
        // Sem isto, resolveCounterCurrency() cairia no CurrencyRepository
        // real e tentaria abrir o banco de configuração de verdade. O DAO e a
        // rede fakes evitam o mesmo problema ao abrir o histórico de uma
        // moeda, que agora busca sozinho ao abrir a tela.
        currencyRepository: CurrencyRepository.withDependencies(
            configurationRepository:
                FakeConfigurationRepository(configuration: configuration),
            currencyDao: FakeCurrencyDao(),
            networkUtils: FakeNetworkUtils(available: false)));
  }

  Future<CurrencyHistoryMenuBloc> pumpMenu(WidgetTester tester,
      {Configuration? configuration}) async {
    var bloc = buildBloc(configuration: configuration);
    await tester.pumpWidget(_menuApp(bloc));
    return bloc;
  }

  /// A seção de criptomoedas fica no fim da lista, fora da tela: a
  /// `ListView.separated` só monta o que está visível.
  ///
  /// A rolagem é feita com [ScrollPosition.jumpTo], e não com um arraste: cada
  /// linha nova agenda sua animação de entrada com `Future.delayed` (ver
  /// [AnimatedListEntry]), e o arraste continua montando linhas enquanto
  /// desacelera, deixando timers pendentes que fazem o teste falhar ao
  /// terminar. Com o salto, cada passo monta as linhas de uma vez e o pump
  /// seguinte vence os atrasos.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    var position =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    for (var steps = 0;
        finder.evaluate().isEmpty && position.pixels < position.maxScrollExtent;
        steps++) {
      expect(steps, lessThan(50), reason: "não achou $finder rolando a lista");
      position.jumpTo(
          (position.pixels + 300).clamp(0.0, position.maxScrollExtent));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
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

    testWidgets('não lista a moeda usada como contrapartida (BRL por padrão)',
        (WidgetTester tester) async {
      await pumpMenu(tester);
      await tester.pumpAndSettle();

      expect(find.text("BRL"), findsNothing,
          reason:
              "BRL contra ela mesma não tem série para o gráfico de histórico");
    });

    testWidgets(
        'BRL volta a aparecer quando outra moeda vira a contrapartida',
        (WidgetTester tester) async {
      await pumpMenu(tester,
          configuration: Configuration(1,
              overrideDefaultCurrency: true,
              selectedOverrideCurrencyCode: "USD"));
      await tester.pumpAndSettle();

      expect(find.text("BRL"), findsOneWidget,
          reason: "BRL contra USD tem série normalmente");
      expect(find.text("USD"), findsNothing,
          reason: "agora é USD quem virou a própria contrapartida");
    });

    testWidgets('separa a listagem em seções de moeda e de criptomoeda',
        (WidgetTester tester) async {
      await pumpMenu(tester);
      await tester.pumpAndSettle();

      expect(find.text("Moedas"), findsOneWidget,
          reason: "o título da primeira seção abre a lista");

      await scrollTo(tester, find.text("Criptomoedas"));

      expect(find.text("Criptomoedas"), findsOneWidget);
    });

    testWidgets('lista as criptomoedas mais comuns com seus nomes',
        (WidgetTester tester) async {
      await pumpMenu(tester);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text("BTC"));

      expect(find.text("Bitcoin"), findsOneWidget,
          reason: "o nome vem do mapa local, não da REST Countries");

      // A lista segue a ordem do enum, então rolar código por código chega ao
      // fim sem voltar atrás.
      for (var cryptocurrency in Cryptocurrencies.values) {
        await scrollTo(tester, find.text(cryptocurrency.name));

        expect(find.text(cryptocurrency.name), findsOneWidget,
            reason: "${cryptocurrency.name} precisa aparecer na listagem");
      }

      expect(find.text("Dogecoin"), findsOneWidget);
    });

    testWidgets('não consulta a REST Countries para criptomoeda',
        (WidgetTester tester) async {
      await pumpMenu(tester);
      await tester.pumpAndSettle();

      // Rola até o fim, para que toda linha da lista tenha sido montada.
      await scrollTo(tester, find.text("DOGE"));

      expect(requests, Currencies.values.length - 1,
          reason: "uma consulta por moeda fiduciária (BRL fora) e nenhuma "
              "por criptomoeda, que não tem país");
    });

    testWidgets('abre o histórico da criptomoeda escolhida',
        (WidgetTester tester) async {
      await pumpMenu(tester);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text("BTC"));

      await tester.tap(find.text("BTC"));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, "BTC"), findsOneWidget,
          reason: "a tela de detalhes usa o código como título");
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
