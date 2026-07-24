import 'dart:convert';

import 'package:http/http.dart' as http;

class CountryNamesRepository {
  final String _countryNameApi = "https://restcountries.eu/rest/v2/currency/";
  final http.Client _httpClient;

  CountryNamesRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<String?> getCountryNameByCurrencyCode(String currencyCode) async {
    var response = await _httpClient
        .get(Uri.parse(_countryNameApi + currencyCode.toLowerCase()));
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse[0]["name"];
  }
}
