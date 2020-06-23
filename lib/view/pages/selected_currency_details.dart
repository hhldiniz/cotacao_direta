import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/view/widgets/charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SelectedCurrencyDetails extends StatelessWidget {
  final String selectedCurrencyCode;

  SelectedCurrencyDetails({Key key, @required this.selectedCurrencyCode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size _screenSize = MediaQuery.of(context).size;
    final localizations = MyAppLocalizations.of(context);
    var bloc = SelectedCurrencyDetailsBlocProvider.of(context);

    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              bloc.getCurrencyHistoryData(selectedCurrencyCode);
            },
            label: Text(localizations.getCurrencyHistoryBtnLabel)),
        body: Column(
          children: [
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: _screenSize.width / 2,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: TextField(
                            controller: bloc.initialDateController,
                            onTap: () {
                              FocusScope.of(context).requestFocus(FocusNode());
                              showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1999),
                                      lastDate: DateTime.now())
                                  .then((value) {
                                if (value != null)
                                  bloc.updateInitialDate(value);
                              });
                            },
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: localizations
                                    .currencyHistoryFromDateLabel)),
                      ),
                    )
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: _screenSize.width / 2,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: TextField(
                            controller: bloc.endDateController,
                            onTap: () {
                              FocusScope.of(context).requestFocus(FocusNode());
                              showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1999),
                                      lastDate: DateTime.now())
                                  .then((value) {
                                if (value != null) bloc.updateFinalDate(value);
                              });
                            },
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText:
                                    localizations.currencyHistoryToDateLabel)),
                      ),
                    )
                  ],
                )
              ],
            ),
            Expanded(
                child: Row(
              children: [
                StreamBuilder(
                    builder: (context, snapshot) {
                      return Expanded(
                          child: Container(
                        child: snapshot.data != null
                            ? SimpleLineChart(
                                seriesList: snapshot.data,
                              )
                            : Text(
                                localizations.noDataLabel,
                                textAlign: TextAlign.center,
                              ),
                      ));
                    },
                    stream: bloc.currencyHistoryStream)
              ],
            ))
          ],
        ));
  }
}
