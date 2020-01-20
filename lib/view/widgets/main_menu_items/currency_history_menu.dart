import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/currency_history_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/widgets/charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class CurrencyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final MyAppLocalizations _localizations = MyAppLocalizations.of(context);
    final bloc = CurrencyHistoryBlocProvider.of(context);
    final _dateFormatter = DateFormat("dd/MM/yyyy");
    final _currencyList = List.generate(Currencies.values.length, (index) {
      return EnumValueAsString()
          .getEnumValue(Currencies.values.elementAt(index).toString());
    });
    final _screenWidth = MediaQuery.of(context).size.width;
    final _currencyChipsPressState = Map.fromIterable(_currencyList,
        key: (element) => element, value: (element) => false);

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Container(
                            width: _screenWidth / 2,
                            child: TextField(
                              controller:
                              bloc.currencyHistoryFromDateController,
                              onTap: () {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1999),
                                    lastDate: DateTime.now())
                                    .then((value) {
                                  bloc.updateFromDateValue(value);
                                  if (value != null)
                                    bloc.currencyHistoryFromDateController
                                        .text = _dateFormatter.format(value);
                                });
                              },
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: _localizations
                                      .currencyHistoryFromDateLabel),
                            ),
                          )
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                              width: _screenWidth / 2,
                              child: TextField(
                                controller:
                                bloc.currencyHistoryToDateController,
                                onTap: () {
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
                                  showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1999),
                                      lastDate: DateTime.now())
                                      .then((value) {
                                    bloc.updateToDateValue(value);
                                    if (value != null)
                                      bloc.currencyHistoryToDateController
                                          .text = _dateFormatter.format(value);
                                  });
                                },
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: _localizations
                                        .currencyHistoryToDateLabel),
                              ))
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                width: _screenWidth,
                height: 40,
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: StreamBuilder(
                          initialData: _currencyChipsPressState[
                          _currencyList.elementAt(index)],
                          stream: bloc
                              .getCurrencySteam(_currencyList.elementAt(index)),
                          builder: (context, snapshot) {
                            return RawChip(
                              showCheckmark: true,
                              selected: _currencyChipsPressState[
                              _currencyList.elementAt(index)],
                              onPressed: () {
                                _currencyChipsPressState[
                                _currencyList.elementAt(index)] =
                                !_currencyChipsPressState[
                                _currencyList.elementAt(index)];
                                bloc.updateCurrencyState(
                                    _currencyList.elementAt(index),
                                    !_currencyChipsPressState[
                                    _currencyList.elementAt(index)]);
                              },
                              label: Text(_currencyList.elementAt(index)),
                            );
                          },
                        ));
                  },
                  itemCount: _currencyList.length,
                  scrollDirection: Axis.horizontal,
                ),
              ),
            )
          ],
        ),
        Row(
          children: <Widget>[
            StreamBuilder(
              builder: (context, snapshot) => SimpleLineChart(
                seriesList: snapshot.data,
                animate: true,
              ),
            )
          ],
        )
      ],
    );
  }
}
