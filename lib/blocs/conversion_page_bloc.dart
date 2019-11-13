import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';

class ConversionPageBloc extends BaseBloc{

  var _multiplierStream = StreamController();
  var _currencyFromStream = StreamController();

  var _multiplierValue = 0;

  Stream get multiplierStream => _multiplierStream.stream;

  Sink get multiplierSink => _multiplierStream.sink;

  Stream get currencyFromStream => _currencyFromStream.stream;

  Sink get currencyFromSink => _currencyFromStream.sink;

  updateMultiplierValue(value){
    _multiplierValue = value;
    multiplierSink.add(_multiplierValue);
  }

  @override
  void dispose() {
    _multiplierStream.close();
    _currencyFromStream.close();
  }

}