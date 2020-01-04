import 'package:cotacao_direta/providers/currency_history_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class CurrencyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final MyAppLocalizations _localizations = MyAppLocalizations.of(context);
    final bloc = CurrencyHistoryBlocProvider.of(context);
    final _dateFormatter = DateFormat("dd/MM/yyyy");

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    width: 200,
                    child: TextField(
                      controller: bloc.currencyHistoryFromDateController,
                      onTap: () {
                        FocusScope.of(context).requestFocus(FocusNode());
                        showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1999),
                            lastDate: DateTime.now())
                            .then((value) {
                          bloc.updateFromDateValue(value);
                          if(value != null)
                            bloc.currencyHistoryFromDateController.text =
                                _dateFormatter.format(value);
                        });
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: _localizations.currencyHistoryFromDateLabel),
                    ),
                  )
                ],
              ),
              Column(
                children: <Widget>[
                  Container(
                      width: 200,
                      child: TextField(
                        controller: bloc.currencyHistoryToDateController,
                        onTap: () {
                          FocusScope.of(context).requestFocus(FocusNode());
                          showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1999),
                              lastDate: DateTime.now())
                              .then((value) {
                            bloc.updateToDateValue(value);
                            if(value != null)
                              bloc.currencyHistoryToDateController.text =
                                  _dateFormatter.format(value);
                          });
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: _localizations.currencyHistoryToDateLabel),
                      ))
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}
