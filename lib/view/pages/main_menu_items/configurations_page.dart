import 'dart:ffi';

import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/configurations_page_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ConfigurationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ConfigurationsPageBloc _bloc = ConfigurationsPageBlocProvider.of(context);
    final _currencyList = List.generate(Currencies.values.length, (index) {
      return EnumValueAsString()
          .getEnumValue(Currencies.values.elementAt(index).toString());
    });
    var _localization = MyAppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                child: Row(
                  children: [
                    StreamBuilder(
                      builder: (BuildContext context, snapshot) {
                        return Switch(
                            value: snapshot.data,
                            onChanged: (bool checked) {
                              _bloc.overrideDefaultCurrencyValueSink
                                  .add(checked);
                            });
                      },
                      stream: _bloc.overrideDefaultCurrencyValueStream,
                      initialData: false,
                    ),
                    Text(_localization.overrideDefaultCurrencySwitchLabel)
                  ],
                ),
              ),
              StreamBuilder(
                builder: (BuildContext context, snapshot) {
                  return DropdownButton(
                    items: List.generate(
                        _currencyList.length,
                        (index) => DropdownMenuItem(
                            child: Text(_currencyList[index]))),
                    onChanged: snapshot.data == true ? (value){} : null,
                  );
                },
                stream: _bloc.overrideDefaultCurrencyValueStream,
                initialData: null,
              )
            ],
          ),
          flex: 1,
        )
      ],
    );
  }
}
