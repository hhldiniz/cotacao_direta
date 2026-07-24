import 'dart:convert';

import 'package:cotacao_direta/repository/country_names_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<Uri> requestedUris;

  setUp(() => requestedUris = []);

  CountryNamesRepository buildRepository(String body) {
    return CountryNamesRepository(httpClient: MockClient((request) async {
      requestedUris.add(request.url);
      return http.Response.bytes(utf8.encode(body), 200,
          headers: {"content-type": "application/json; charset=utf-8"});
    }));
  }

  group('CountryNamesRepository', () {
    test('devolve o nome do primeiro país da resposta', () async {
      var name =
          await buildRepository('[{"name": "Brazil"}, {"name": "Outro país"}]')
              .getCountryNameByCurrencyCode("BRL");

      expect(name, "Brazil");
    });

    test('consulta a API com o código em minúsculas', () async {
      await buildRepository('[{"name": "United States"}]')
          .getCountryNameByCurrencyCode("USD");

      expect(requestedUris.single.toString(),
          "https://restcountries.eu/rest/v2/currency/usd");
    });

    test('devolve null quando a resposta não traz o nome', () async {
      var name = await buildRepository('[{"capital": "Brasília"}]')
          .getCountryNameByCurrencyCode("BRL");

      expect(name, isNull);
    });

    test('lança erro quando a API devolve uma lista vazia', () {
      expect(buildRepository('[]').getCountryNameByCurrencyCode("XYZ"),
          throwsA(isA<RangeError>()));
    });
  });
}
