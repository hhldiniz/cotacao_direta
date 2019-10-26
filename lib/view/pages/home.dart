import 'package:cotacao_direta/view/widgets/canadian_dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/dollar_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/euro_exchange_rate.dart';
import 'package:cotacao_direta/view/widgets/yen_exchange_rate.dart';
import 'package:cotacao_direta/viewmodel/viewmodel_impl/HomeViewModelImpl.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget{

  final dollarExchangeRate = DollarExchangeRate();
  final euroExchangeRate = EuroExchangeRate();
  final canadianDollarExchangeRate = CanadianDollarExchangeRate();
  final yenExchangeRate = YenExchangeRate();

  final String _pageTitle;
  final viewModel = HomeViewModelImpl();

  Home(this._pageTitle);


  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_){
      viewModel.loadDollarValue().then((value){
        dollarExchangeRate.exchangeRateValue.state.setValue(1/value);
      });
      viewModel.loadEuroValue().then((value){
        euroExchangeRate.exchangeRateValue.state.setValue(1/value);
      });
      viewModel.loadEuroValue().then((value){
        canadianDollarExchangeRate.exchangeRateValue.state.setValue(1/value);
      });
      viewModel.loadYen().then((value){
        yenExchangeRate.exchangeRateValue.state.setValue(1/value);
      });
    });
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
                    Container(
                      width: 24,
                      child: TextField(),
                    )
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text("Real vale hoje", style: TextStyle(fontSize: 24),)
                  ],
                )
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