import 'package:cotacao_direta/view/widgets/base_currency_multiplier.dart';
import 'package:cotacao_direta/view/widgets/canadian_dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/euro_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/yen_exchange_rate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Home extends StatelessWidget {
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
      appBar: AppBar(
        title: Text(_pageTitle),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[baseCurrencyMultiplier],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.amber),
                      child: dollarExchangeRate,
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.blueAccent),
                      child: euroExchangeRate,
                    )
                  ],
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(60.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.deepOrange),
                      child: canadianDollarExchangeRate,
                    )
                  ],
                )
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(33.0),
                  decoration:
                  BoxDecoration(shape: BoxShape.circle, color: Colors.pink),
                  child: yenExchangeRate,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
