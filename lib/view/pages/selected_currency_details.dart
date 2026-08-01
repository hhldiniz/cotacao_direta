import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/charts.dart';
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
                child: Stack(
                  children: [
                    StreamBuilder<List<Currency>>(
                      stream: bloc.currencyHistoryStream,
                      builder: (context, snapshot) {
                        final currencyList = snapshot.data;
                        if (currencyList == null || currencyList.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.show_chart,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    localizations.noDataLabel!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(8, 24, 24, 8),
                          child: SimpleLineChart(currencyList: currencyList),
                        );
                      },
                    ),
                    StreamBuilder<bool>(
                      stream: bloc.isLoadingStream,
                      initialData: false,
                      builder: (context, loadingSnapshot) {
                        if (loadingSnapshot.data == true) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
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
