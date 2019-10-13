import 'dart:convert';

import 'package:cotacao_direta/viewmodel/home_viewmodel.dart';
import 'package:http/http.dart' as http;

class HomeViewModelImpl extends HomeViewModel{

  final String exchangeRateApi = "https://api.exchangeratesapi.io/latest?base=BRL";

  @override
  Future<double> loadDollarValue() async {
    var response = await http.get(exchangeRateApi);
    return jsonDecode(response.body)["rates"]["USD"];
  }

  @override
  Future<double> loadEuroValue() async {
    var response = await http.get(exchangeRateApi);
    return jsonDecode(response.body)["rates"]["EUR"];
  }

}