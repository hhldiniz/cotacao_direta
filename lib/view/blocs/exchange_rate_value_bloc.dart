import 'dart:async';
import 'base_bloc.dart';

class ExchangeRateValueBloc extends BaseBloc
{
  final valueController = StreamController();

  Stream get getValue => valueController.stream;

  void updateValue(value){
    valueController.sink.add(value);
  }

  @override
  void dispose() {
    valueController.close();
  }

}