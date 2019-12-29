import 'package:cotacao_direta/providers/currency_history_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CurrencyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final MyAppLocalizations _localizations = MyAppLocalizations.of(context);
    final bloc = CurrencyHistoryBlocProvider.of(context);

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  width: 200,
                  child: StreamBuilder(
                      stream: bloc.currencyHistoryFromDateStream,
                      builder: (context, snapshot) {
                        return TextField(
                          onTap: () {
                            showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1999),
                                    lastDate: DateTime.now())
                                .then((value) {
                                  bloc.updateFromDateValue(value);
                            });
                          },
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText:
                                  _localizations.currencyHistoryFromDateLabel),
                        );
                      }),
                )
              ],
            ),
            Column(
              children: <Widget>[
                Container(
                  width: 200,
                  child: StreamBuilder(
                    stream: bloc.currencyHistoryToDateStream,
                    builder: (context, snapshot) {
                      return TextField(
                        onTap: () {
                          showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1999),
                                  lastDate: DateTime.now())
                              .then((value) {
                                bloc.updateToDateValue(value);
                          });
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText:
                                _localizations.currencyHistoryToDateLabel),
                      );
                    },
                  ),
                )
              ],
            )
          ],
        )
      ],
    );
  }
}
