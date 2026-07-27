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

    return FutureBuilder<String>(
      future: bloc.counterCurrencyCode,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final counterCurrency = snapshot.data!;
        // A moeda usada como contrapartida não tem série própria para
        // desenhar: CurrencyRepository.getCurrencyHistoricalData pula a
        // consulta quando a moeda pedida é a própria contrapartida, e o
        // gráfico ficaria sempre em "Sem Dados" para ela.
        final _currencies = Currencies.values
            .where((currency) =>
                EnumValueAsString().getEnumValue(currency.toString()) !=
                counterCurrency)
            .toList();
        final _currencyList = _currencies
            .map((currency) =>
                EnumValueAsString().getEnumValue(currency.toString()))
            .toList();

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
                        flagCodeForCurrency(_currencies[index]),
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
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 20 * _scale,
                    color: Theme.of(context).colorScheme.outline,
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
      },
    );
  }
}
