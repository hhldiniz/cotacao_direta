import 'package:flutter/material.dart';
import 'package:cotacao_direta/view/widgets/dollar_exchange_rate.dart';

class Home extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: <Widget>[
            DollarExchangeRate()
          ],
        ),
      ),
    );
  }
  
}