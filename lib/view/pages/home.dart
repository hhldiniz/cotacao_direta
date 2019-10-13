import 'package:cotacao_direta/view/widgets/dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/euro_exchange_rate.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget{

  final dollarExchangeRate = DollarExchangeRate();
  final euroExchangeRate = EuroExchangeRate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                dollarExchangeRate
              ],
            ),
            Row(
              children: <Widget>[
                euroExchangeRate
              ],
            )
          ],
        ),
      ),
    );
  }
  
}