import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

typedef AddressLookup = Future<List<InternetAddress>> Function(String host);

class NetworkUtils {
  final AddressLookup? _lookup;

  NetworkUtils({AddressLookup? lookup}) : _lookup = lookup;

  Future<bool> isNetworkAvailable() async {
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
