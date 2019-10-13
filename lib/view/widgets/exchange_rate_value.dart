import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExchangeRateValue extends StatefulWidget{

  final state = _ExchangeRateValueState();


  @override
  State createState() {
    return state;
  }

}

class _ExchangeRateValueState extends State<ExchangeRateValue>{

  var _value = 0.0;
  final _formatter = NumberFormat("#.###");

  @override
  Widget build(BuildContext context) {
    return Text(_value.toString(), style: TextStyle(fontSize: 18),);
  }

  setValue(newValue){
    setState(() {
      _value = double.parse(_formatter.format(newValue));
    });
  }

}