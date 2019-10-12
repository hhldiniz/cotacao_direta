import 'package:flutter/material.dart';

class ExchangeRateValue extends StatefulWidget{

  final state = _ExchangeRateValueState();

  @override
  State createState() {
    return state;
  }

}

class _ExchangeRateValueState extends State<ExchangeRateValue>{

  var _value = 0.0;

  @override
  Widget build(BuildContext context) {
    return Text(_value.toString());
  }

  setValue(newValue, currency){
    setState(() {
      _value = newValue;
    });
  }

}