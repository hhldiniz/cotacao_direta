import 'dart:async';
import 'dart:convert';

import 'package:cotacao_direta/viewmodel/home_viewmodel.dart';
import 'package:http/http.dart' as http;

class HomeViewModelImpl extends HomeViewModel{

  static HomeViewModelImpl _instance;

  factory HomeViewModelImpl(){
    _instance ??= HomeViewModelImpl._internalConstructor();
    return _instance;
  }

  HomeViewModelImpl._internalConstructor();

  final String exchangeRateApi = "https://api.exchangeratesapi.io/latest?base=BRL";
  var serverData;
  var _currencyMultiplierValueController = StreamController<int>.broadcast();

  @override
  Future<double> loadDollarValue() async {
    await loadData();
    return jsonDecode(serverData.body)["rates"]["USD"];
  }

  @override
  Future<double> loadEuroValue() async {
    await loadData();
    return jsonDecode(serverData.body)["rates"]["EUR"];
  }

  @override
  Future<double> loadCanadianDollar() async{
    await loadData();
    return jsonDecode(serverData.body)["rates"]["CAD"];
  }

  @override
  Future<double> loadYen() async{
    await loadData();
    return jsonDecode(serverData.body)["rates"]["JPY"];
  }

  @override
  loadData() async{
    if(serverData == null)
      serverData = await http.get(exchangeRateApi);
  }

  @override
  Sink get currencyMultiplierValue => _currencyMultiplierValueController;

  @override
  dispose() => _currencyMultiplierValueController.close();
}