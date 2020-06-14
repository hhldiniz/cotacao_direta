import 'package:cotacao_direta/view/widgets/charts.dart';
import 'package:flutter/material.dart';

class SelectedCurrencyDetails extends StatelessWidget{

  final String selectedCurrencyCode;

  SelectedCurrencyDetails({Key key, @required this.selectedCurrencyCode}) :
      super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(builder: (context, snapshot) {
        return SimpleLineChart(
          seriesList: [],
        );
      })
    );
  }

}