import 'dart:convert';

import 'package:http/http.dart' as http;

/// Nome do país a partir do código da moeda, pela REST Countries.
///
/// O endereço antigo (restcountries.eu, v2) saiu do ar. Na v3.1 o `name` deixou
/// de ser um texto e passou a ser um objeto com `common` e `official`; o app
/// usa o nome comum.
class CountryNamesRepository {
  static const _apiHost = "restcountries.com";
  static const _currencyPath = "/v3.1/currency";

  final http.Client _httpClient;

  CountryNamesRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<String?> getCountryNameByCurrencyCode(String currencyCode) async {
    var response = await _httpClient.get(_countryNameUri(currencyCode));
    return _firstCountryName(response.body);
  }

  /// `fields` deixa de fora bandeiras, traduções e fusos horários, que são a
  /// maior parte da resposta e não têm uso aqui.
  Uri _countryNameUri(String currencyCode) => Uri.https(_apiHost,
      "$_currencyPath/${currencyCode.toLowerCase()}", {"fields": "name"});

  String? _firstCountryName(String responseBody) {
    var decoded = _tryDecode(responseBody);
    // Moeda desconhecida devolve um objeto de erro, não uma lista.
    if (decoded is! List || decoded.isEmpty) return null;
    var country = decoded.first;
    if (country is! Map) return null;
    var name = country["name"];
    if (name is Map) return name["common"] as String?;
    // A v2 devolvia o nome direto como texto.
    return name is String ? name : null;
  }

  dynamic _tryDecode(String responseBody) {
    try {
      return jsonDecode(responseBody);
    } catch (exception) {
      return null;
    }
  }
}
