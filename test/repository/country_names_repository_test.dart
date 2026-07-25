import 'dart:convert';

import 'package:cotacao_direta/repository/country_names_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// País no formato da REST Countries v3.1, em que o nome é um objeto.
Map<String, dynamic> _country(String common, {String? official}) => {
      "name": {"common": common, "official": official ?? "República d$common"}
    };

void main() {
  late List<Uri> requestedUris;

  setUp(() => requestedUris = []);

  CountryNamesRepository buildRepository(String body, {int status = 200}) {
    return CountryNamesRepository(httpClient: MockClient((request) async {
      requestedUris.add(request.url);
      return http.Response.bytes(utf8.encode(body), status,
          headers: {"content-type": "application/json; charset=utf-8"});
    }));
  }

  group('CountryNamesRepository: montagem da URL', () {
    test('consulta a v3.1 com o código em minúsculas', () async {
      await buildRepository(jsonEncode([_country("Brazil")]))
          .getCountryNameByCurrencyCode("BRL");

      expect(requestedUris.single.host, "restcountries.com");
      expect(requestedUris.single.path, "/v3.1/currency/brl");
    });

    test('pede só o campo do nome', () async {
      await buildRepository(jsonEncode([_country("Brazil")]))
          .getCountryNameByCurrencyCode("BRL");

      expect(requestedUris.single.queryParameters["fields"], "name");
    });
  });

  group('CountryNamesRepository.getCountryNameByCurrencyCode', () {
    test('devolve o nome comum do primeiro país', () async {
      var name = await buildRepository(
              jsonEncode([_country("Brazil"), _country("Outro país")]))
          .getCountryNameByCurrencyCode("BRL");

      expect(name, "Brazil");
    });

    test('prefere o nome comum ao oficial', () async {
      var name = await buildRepository(jsonEncode(
              [_country("Brazil", official: "Federative Republic of Brazil")]))
          .getCountryNameByCurrencyCode("BRL");

      expect(name, "Brazil");
    });

    test('ainda aceita o formato antigo, com o nome em texto', () async {
      var name = await buildRepository(jsonEncode([
        {"name": "Brazil"}
      ])).getCountryNameByCurrencyCode("BRL");

      expect(name, "Brazil");
    });

    test('devolve null quando a moeda não existe', () async {
      var name = await buildRepository(
              jsonEncode({"status": 404, "message": "Not Found"}),
              status: 404)
          .getCountryNameByCurrencyCode("XYZ");

      expect(name, isNull);
    });

    test('devolve null para uma lista vazia', () async {
      var name =
          await buildRepository("[]").getCountryNameByCurrencyCode("XYZ");

      expect(name, isNull);
    });

    test('devolve null quando o país não traz nome', () async {
      var name = await buildRepository(jsonEncode([
        {"cca2": "BR"}
      ])).getCountryNameByCurrencyCode("BRL");

      expect(name, isNull);
    });

    test('devolve null quando a resposta não é JSON', () async {
      var name = await buildRepository("<html>erro</html>")
          .getCountryNameByCurrencyCode("BRL");

      expect(name, isNull);
    });

    test('não lança para o chamador em nenhum desses casos', () async {
      await expectLater(
          buildRepository("[]").getCountryNameByCurrencyCode("XYZ"), completes);
    });
  });
}
