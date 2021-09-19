import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/currency_history_menu_bloc_provider.dart';
import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/pages/selected_currency_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CurrencyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = CurrencyHistoryMenuBlocProvider.of(context);

    final _currencyList = List.generate(Currencies.values.length, (index) {
      return EnumValueAsString()
          .getEnumValue(Currencies.values.elementAt(index).toString());
    });

    bloc.initStreamControllers(_currencyList);

    return Center(
      child: ListView.builder(
        itemBuilder: (BuildContext context, index) {
          return GestureDetector(
            child: ListTile(
              title: Text(_currencyList[index]),
              subtitle: StreamBuilder(
                stream: bloc.getCountryNameController(_currencyList[index]),
                builder: (context, snapshot){
                    bloc.getCountryNameByCurrencyCode(_currencyList[index]);
                    return Text((snapshot.data as String?) ?? "");
                },
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SelectedCurrencyDetailsBlocProvider(
                            child: SelectedCurrencyDetails(
                          selectedCurrencyCode: _currencyList[index],
                        ))),
              );
            },
          );
        },
        itemCount: _currencyList.length,
      ),
    );
  }
}
