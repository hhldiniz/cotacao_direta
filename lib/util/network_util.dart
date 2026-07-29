import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

typedef AddressLookup = Future<List<InternetAddress>> Function(String host);

class NetworkUtils {
  final AddressLookup? _lookup;

  // Cada moeda buscada (as 4 da tela inicial, mais alertas, mais histórico)
  // checa a rede antes de tudo; sem isto, um único ciclo de atualização
  // dispara várias consultas de DNS/HTTP idênticas em sequência. O cache é
  // curto o bastante para não mascarar uma queda de conexão por muito tempo.
  static const _cacheTtl = Duration(seconds: 5);
  bool? _cachedResult;
  DateTime? _cachedAt;
  Future<bool>? _pendingCheck;

  NetworkUtils({AddressLookup? lookup}) : _lookup = lookup;

  Future<bool> isNetworkAvailable() {
    final cachedResult = _cachedResult;
    final cachedAt = _cachedAt;
    if (cachedResult != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return Future.value(cachedResult);
    }
    // Concorrência: várias chamadas quase simultâneas compartilham a mesma
    // checagem em andamento em vez de disparar uma para cada uma.
    return _pendingCheck ??= _checkNetworkAvailable().then((result) {
      _cachedResult = result;
      _cachedAt = DateTime.now();
      _pendingCheck = null;
      return result;
    });
  }

  Future<bool> _checkNetworkAvailable() async {
    if (_lookup != null) {
      try {
        final result = await _lookup("google.com");
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    }

    // O navegador não expõe resolução de DNS via dart:io (InternetAddress
    // não tem implementação na web); a checagem vira uma requisição HTTP
    // leve à mesma API de cotações usada pelo app.
    if (kIsWeb) {
      try {
        await http
            .head(Uri.https("economia.awesomeapi.com.br", "/"))
            .timeout(const Duration(seconds: 5));
        return true;
      } catch (_) {
        return false;
      }
    }

    try {
      final result = await InternetAddress.lookup("google.com");
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
