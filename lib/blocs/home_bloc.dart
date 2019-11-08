import 'dart:async';
import 'dart:convert';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:http/http.dart' as http;
import 'base_bloc.dart';
import 'package:cotacao_direta/util/string_utils.dart';

class HomeBloc extends BaseBloc
{
  final valueController = StreamController.broadcast();
  final multiplierController = StreamController();

  final String _exchangeRateApi = "https://api.exchangeratesapi.io/latest?base=BRL";

  Stream get getExchangeValueStream => valueController.stream;
  Stream get getMultiplierStream => multiplierController.stream;

  double lastMultiplierValue = 0.0;

  void updateValue(value){
    valueController.sink.add(value);
  }

  void updateMultiplier(value){
    lastMultiplierValue = value;
    multiplierController.sink.add(value);
  }

  Future<double> retrieveRemoteValue(Currencies currency) async
  {
    var response =  await http.get(_exchangeRateApi);
    return jsonDecode(response.body)["rates"][EnumValueAsString().getEnumValue(currency.toString())];
  }

  @override
  void dispose() {
    valueController.close();
    multiplierController.close();
  }

}