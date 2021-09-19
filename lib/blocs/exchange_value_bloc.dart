import 'dart:async';

import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:cotacao_direta/util/string_utils.dart';

import 'base_bloc.dart';

class ExchangeValueBloc extends BaseBloc {
  StreamController<num>? valueController;

  Stream<num> get getExchangeValueStream => valueController!.stream;

  final _currencyRepository = CurrencyRepository();

  Stream<num> getNextStreamController() {
    if (valueController == null) {
      valueController = StreamController();
      return valueController!.stream;
    } else if (!valueController!.hasListener) {
      return valueController!.stream;
    } else {
      valueController!.close();
      valueController = StreamController();
      return valueController!.stream;
    }
  }

  void updateValue(value) {
    valueController!.sink.add(value);
  }

  Future<double?> retrieveCurrencyValue(Currencies? currency) async {
    return (await _currencyRepository.getLatestDataByCurrencyCode(
        EnumValueAsString().getEnumValue(currency.toString())))!
        .value;
  }

  @override
  void dispose() {
    valueController!.close();
  }
}
