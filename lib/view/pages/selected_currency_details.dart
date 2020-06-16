import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/view/widgets/charts.dart';
import 'package:flutter/material.dart';

class SelectedCurrencyDetails extends StatelessWidget {
  final String selectedCurrencyCode;

  SelectedCurrencyDetails({Key key, @required this.selectedCurrencyCode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size _screenSize = MediaQuery.of(context).size;

    var bloc = SelectedCurrencyDetailsBlocProvider.of(context);
    return Scaffold(
        body: Column(
      children: [
        Row(
          children: [
            Column(
              children: [
                Container(
                  width: _screenSize.width / 2,
                  child: TextField(
                    controller: bloc.initialDateController,
                  ),
                )
              ],
            ),
            Column(
              children: [
                Container(
                  width: _screenSize.width / 2,
                  child: TextField(
                    controller: bloc.endDateController,
                  ),
                )
              ],
            )
          ],
        ),
        Row(
          children: [
            StreamBuilder(
                builder: (context, snapshot) {
                  return Container(
                    width: _screenSize.width,
                    height: 200,
                    child: SimpleLineChart(
                      seriesList: snapshot.data ?? [],
                    ),
                  );
                },
                stream: bloc.currencyHistoryStream)
          ],
        )
      ],
    ));
  }
}
