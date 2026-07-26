import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/currency_history_menu_bloc_provider.dart';
import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/util/currency_flag.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/pages/selected_currency_details.dart';
import 'package:cotacao_direta/view/widgets/animated_list_entry.dart';
import 'package:flag/flag.dart';
import 'package:flutter/material.dart';

class CurrencyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = CurrencyHistoryMenuBlocProvider.of(context);
    final _scale = Responsive.scaleFactor(context);

    final _currencyList = List.generate(Currencies.values.length, (index) {
      return EnumValueAsString().getEnumValue(
        Currencies.values.elementAt(index).toString(),
      );
    });

    bloc.initStreamControllers(_currencyList);

    return ListView.separated(
      separatorBuilder: (BuildContext context, index) {
        return const Divider(height: 1, thickness: 1);
      },
      itemBuilder: (BuildContext context, index) {
        return AnimatedListEntry(
          index: index,
          child: GestureDetector(
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _currencyList[index],
                    style: TextStyle(fontSize: 16 * _scale),
                  ),
                  Flag.fromCode(
                    flagCodeForCurrency(Currencies.values[index]),
                    height: 24 * _scale,
                    width: 32 * _scale,
                  ),
                ],
              ),
              subtitle: StreamBuilder<String?>(
                initialData: bloc.cachedCountryName(_currencyList[index]),
                stream: bloc.getCountryNameController(_currencyList[index]),
                builder: (context, snapshot) {
                  bloc.getCountryNameByCurrencyCode(_currencyList[index]);
                  return Text(
                    snapshot.data ?? "",
                    style: TextStyle(fontSize: 14 * _scale),
                  );
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
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      itemCount: _currencyList.length,
    );
  }
}
