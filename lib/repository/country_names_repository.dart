import 'dart:convert';

import 'package:http/http.dart' as http;

class CountryNamesRepository {
  final String _countryNameApi = "https://restcountries.eu/rest/v2/currency/";

  Future<String> getCountryNameByCurrencyCode(String currencyCode) async {
    var response =
        await http.get(Uri.parse(_countryNameApi + currencyCode.toLowerCase()));
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse[0]["name"];
  }
}
