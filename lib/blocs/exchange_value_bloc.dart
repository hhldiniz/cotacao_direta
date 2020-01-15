import 'dart:async';

import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:cotacao_direta/util/string_utils.dart';

import 'base_bloc.dart';

class ExchangeValueBloc extends BaseBloc {
  final valueController = StreamController.broadcast();

  Stream get getExchangeValueStream => valueController.stream;

  final _currencyRepository = CurrencyRepository();

  void updateValue(value) {
    valueController.sink.add(value);
  }

  Future<double> retrieveRemote(Currencies currency) async {
    return (await _currencyRepository.getLatestDataByCurrencyCode(
        EnumValueAsString().getEnumValue(currency.toString())))
        .value;
  }

  @override
  void dispose() {
    valueController.close();
  }
}
