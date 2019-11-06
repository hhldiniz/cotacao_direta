import 'package:cotacao_direta/view/widgets/base_currency_multiplier.dart';
import 'package:cotacao_direta/view/widgets/canadian_dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/euro_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/yen_exchange_rate.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget{

  final dollarExchangeRate = DollarExchangeRate();
  final euroExchangeRate = EuroExchangeRate();
  final canadianDollarExchangeRate = CanadianDollarExchangeRate();
  final yenExchangeRate = YenExchangeRate();
  final baseCurrencyMultiplier = BaseCurrencyMultiplier();

  final String _pageTitle;

  Home(this._pageTitle);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle),),
      body: Center(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    baseCurrencyMultiplier
                  ],
                ),
              ],
            ),
            Row(
              children: <Widget>[
                dollarExchangeRate
              ],
            ),
            Row(
              children: <Widget>[
                euroExchangeRate
              ],
            ),
            Row(
              children: <Widget>[
                canadianDollarExchangeRate
              ],
            ),
            Row(
              children: <Widget>[
                yenExchangeRate
              ],
            )
          ],
        ),
      ),
    );
  }
  
}