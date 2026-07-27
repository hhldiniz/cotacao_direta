import 'dart:convert';

import 'package:cotacao_direta/blocs/currency_history_menu_bloc.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/country_names_repository.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fakes.dart';

void main() {
  late List<Uri> requestedUris;

  setUp(() => requestedUris = []);

  CurrencyHistoryMenuBloc buildBloc(
      {String body = '[{"name": "Brazil"}]',
      int status = 200,
      Configuration? configuration}) {
    return CurrencyHistoryMenuBloc(
        countryNamesRepository:
            CountryNamesRepository(httpClient: MockClient((request) async {
          requestedUris.add(request.url);
          return http.Response.bytes(utf8.encode(body), status,
              headers: {"content-type": "application/json; charset=utf-8"});
        })),
        // Sem isto, resolveCounterCurrency() cairia no CurrencyRepository
        // real e tentaria abrir o banco de configuração de verdade.
        currencyRepository: CurrencyRepository.withDependencies(
            configurationRepository:
                FakeConfigurationRepository(configuration: configuration)));
  }

  group('CurrencyHistoryMenuBloc.counterCurrencyCode', () {
    test('BRL por padrão, sem configuração de override', () async {
      var bloc = buildBloc();

      expect(await bloc.counterCurrencyCode, "BRL");
    });

    test('a moeda escolhida nas configurações, quando o override está ligado',
        () async {
      var bloc = buildBloc(
          configuration: Configuration(1,
              overrideDefaultCurrency: true,
              selectedOverrideCurrencyCode: "USD"));

      expect(await bloc.counterCurrencyCode, "USD");
    });

    test('resolve uma única vez e mantém em cache', () async {
      var bloc = buildBloc();

      await bloc.counterCurrencyCode;
      var second = bloc.counterCurrencyCode;

      expect(identical(bloc.counterCurrencyCode, second), isTrue,
          reason: "a mesma Future precisa voltar sem consultar de novo");
    });
  });

  group('CurrencyHistoryMenuBloc.initStreamControllers', () {
    test('cria um controller por moeda', () {
      var bloc = buildBloc();

      bloc.initStreamControllers(["USD", "EUR"]);

      expect(bloc.getCountryNameController("USD"), isNotNull);
      expect(bloc.getCountryNameController("EUR"), isNotNull);
    });

    test('reaproveita os controllers em chamadas seguintes', () {
      var bloc = buildBloc();

      bloc.initStreamControllers(["USD"]);
      var stream = bloc.getCountryNameController("USD");
      bloc.initStreamControllers(["USD"]);

      // Streams de um mesmo StreamController são iguais entre si, mesmo sem
      // serem o mesmo objeto; um controller novo daria uma stream diferente.
      expect(bloc.getCountryNameController("USD"), stream,
          reason: "recriar o controller abandonaria o anterior aberto");
    });

    test('acrescenta moedas novas sem descartar as antigas', () {
      var bloc = buildBloc();

      bloc.initStreamControllers(["USD"]);
      var stream = bloc.getCountryNameController("USD");
      bloc.initStreamControllers(["USD", "EUR"]);

      expect(bloc.getCountryNameController("USD"), stream);
      expect(bloc.getCountryNameController("EUR"), isNotNull);
    });

    test('devolve null para uma moeda sem controller', () {
      expect(buildBloc().getCountryNameController("USD"), isNull);
    });
  });

  group('CurrencyHistoryMenuBloc.getCountryNameByCurrencyCode', () {
    test('publica o nome do país na stream da moeda', () async {
      var bloc = buildBloc();
      bloc.initStreamControllers(["BRL"]);
      var received = bloc.getCountryNameController("BRL")!.first;

      await bloc.getCountryNameByCurrencyCode("BRL");

      expect(await received, "Brazil");
    });

    test('guarda o nome para as próximas leituras', () async {
      var bloc = buildBloc();
      bloc.initStreamControllers(["BRL"]);

      await bloc.getCountryNameByCurrencyCode("BRL");

      expect(bloc.cachedCountryName("BRL"), "Brazil");
    });

    test('consulta a API uma única vez por moeda', () async {
      var bloc = buildBloc();
      bloc.initStreamControllers(["BRL"]);

      await bloc.getCountryNameByCurrencyCode("BRL");
      await bloc.getCountryNameByCurrencyCode("BRL");
      await bloc.getCountryNameByCurrencyCode("BRL");

      expect(requestedUris, hasLength(1),
          reason: "a chamada sai do builder da lista, uma por rebuild");
    });

    test('não dispara chamadas paralelas para a mesma moeda', () async {
      var bloc = buildBloc();
      bloc.initStreamControllers(["BRL"]);

      await Future.wait([
        bloc.getCountryNameByCurrencyCode("BRL"),
        bloc.getCountryNameByCurrencyCode("BRL"),
      ]);

      expect(requestedUris, hasLength(1));
    });

    test('não repete a chamada depois de uma falha', () async {
      var bloc = buildBloc(body: '[]');
      bloc.initStreamControllers(["XYZ"]);

      await bloc.getCountryNameByCurrencyCode("XYZ");
      await bloc.getCountryNameByCurrencyCode("XYZ");

      expect(requestedUris, hasLength(1));
      expect(bloc.cachedCountryName("XYZ"), isNull);
    });

    test('a falha não escapa para quem chamou', () async {
      var bloc = buildBloc(body: '[]');
      bloc.initStreamControllers(["XYZ"]);

      await expectLater(bloc.getCountryNameByCurrencyCode("XYZ"), completes);
    });

    test('não estoura para uma moeda sem controller', () async {
      var bloc = buildBloc();

      await expectLater(bloc.getCountryNameByCurrencyCode("BRL"), completes);
      expect(bloc.cachedCountryName("BRL"), "Brazil");
    });
  });

  group('CurrencyHistoryMenuBloc.dispose', () {
    test('fecha as streams de todas as moedas', () async {
      var bloc = buildBloc();
      bloc.initStreamControllers(["USD", "EUR"]);
      var usdStream = bloc.getCountryNameController("USD")!;
      var eurStream = bloc.getCountryNameController("EUR")!;

      bloc.dispose();

      expect(await usdStream.isEmpty, isTrue);
      expect(await eurStream.isEmpty, isTrue);
    });

    test('esvazia o mapa de controllers', () {
      var bloc = buildBloc();
      bloc.initStreamControllers(["USD"]);

      bloc.dispose();

      expect(bloc.getCountryNameController("USD"), isNull);
    });

    test('não estoura quando nenhum controller foi criado', () {
      expect(() => buildBloc().dispose(), returnsNormally);
    });
  });
}
