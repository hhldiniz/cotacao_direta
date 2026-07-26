import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:flutter/material.dart';

class SelectedCurrencyDetails extends StatelessWidget {
  final String selectedCurrencyCode;

  SelectedCurrencyDetails({Key? key, required this.selectedCurrencyCode})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = MyAppLocalizations.of(context)!;
    var bloc = SelectedCurrencyDetailsBlocProvider.of(context);
    final _contentWidth = Responsive.contentMaxWidth(context);

    return Scaffold(
      appBar: AppBar(title: Text(selectedCurrencyCode)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          bloc.getCurrencyHistoryData(selectedCurrencyCode);
        },
        label: Text(localizations.getCurrencyHistoryBtnLabel!),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _contentWidth),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: _contentWidth / 2,
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
                                lastDate: DateTime.now(),
                              ).then((value) {
                                if (value != null)
                                  bloc.updateInitialDate(value);
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText:
                                  localizations.currencyHistoryFromDateLabel,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        width: _contentWidth / 2,
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
                                lastDate: DateTime.now(),
                              ).then((value) {
                                if (value != null) bloc.updateFinalDate(value);
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText:
                                  localizations.currencyHistoryToDateLabel,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    // TODO Substitute this block with the class from another chart library
                    /*StreamBuilder<List<Series<dynamic, dynamic>>>(
                    builder: (context, snapshot) {
                      return Expanded(
                          child: Container(
                        child: snapshot.data != null
                            ? SimpleLineChart(
                                seriesList: snapshot.data,
                              )
                            : Text(
                                localizations.noDataLabel!,
                                textAlign: TextAlign.center,
                              ),
                      ));
                    },
                    stream: bloc.currencyHistoryStream)*/
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
