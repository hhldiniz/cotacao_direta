import 'dart:async';
import 'base_bloc.dart';

class HomeBloc extends BaseBloc
{
  final valueController = StreamController();

  Stream get getExchangeValue => valueController.stream;

  void updateValue(value){
    valueController.sink.add(value);
  }

  @override
  void dispose() {
    valueController.close();
  }

}