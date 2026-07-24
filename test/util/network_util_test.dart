import 'dart:io';

import 'package:cotacao_direta/util/network_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkUtils', () {
    test('há rede quando o lookup devolve um endereço', () async {
      var networkUtils =
          NetworkUtils(lookup: (host) async => [InternetAddress("127.0.0.1")]);

      expect(await networkUtils.isNetworkAvailable(), isTrue);
    });

    test('consulta o host esperado', () async {
      String? requestedHost;
      var networkUtils = NetworkUtils(lookup: (host) async {
        requestedHost = host;
        return [InternetAddress("127.0.0.1")];
      });

      await networkUtils.isNetworkAvailable();

      expect(requestedHost, "google.com");
    });

    test('não há rede quando o lookup não devolve endereço algum', () async {
      var networkUtils = NetworkUtils(lookup: (host) async => []);

      expect(await networkUtils.isNetworkAvailable(), isFalse);
    });

    test('não há rede quando o lookup falha', () async {
      var networkUtils = NetworkUtils(
          lookup: (host) async => throw SocketException("sem conexão"));

      expect(await networkUtils.isNetworkAvailable(), isFalse);
    });

    test('erros que não são de socket continuam subindo', () {
      var networkUtils =
          NetworkUtils(lookup: (host) async => throw StateError("inesperado"));

      expect(networkUtils.isNetworkAvailable(), throwsStateError);
    });
  });
}
