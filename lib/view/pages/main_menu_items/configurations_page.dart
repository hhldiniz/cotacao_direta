import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/configurations_page_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/widgets/widget_state_helpers/override_currency_state_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ConfigurationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ConfigurationsPageBloc _bloc = ConfigurationsPageBlocProvider.of(context);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _bloc.loadCurrentConfiguration());
    final _currencyList = List.generate(Currencies.values.length, (index) {
      return EnumValueAsString()
          .getEnumValue(Currencies.values.elementAt(index).toString());
    });
    var _localization = MyAppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                child: Row(
                  children: [
                    StreamBuilder<OverrideCurrencyStateHelper>(
                      builder: (BuildContext context, snapshot) {
                        return Switch(
                            value: snapshot.data!.enableCurrencyOverride,
                            onChanged: (bool checked) {
                              _bloc.updateOverrideCurrencySwitch(checked);
                            });
                      },
                      stream: _bloc.overrideDefaultCurrencyValueStream as Stream<OverrideCurrencyStateHelper>?,
                      initialData: _bloc.overrideCurrencyStateHelper,
                    ),
                    Text(_localization.overrideDefaultCurrencySwitchLabel!)
                  ],
                ),
              ),
              StreamBuilder<OverrideCurrencyStateHelper>(
                builder: (BuildContext context, switchSnapshot) {
                  return DropdownButton(
                    items: List.generate(
                        _currencyList.length,
                        (index) => DropdownMenuItem(
                            value: _currencyList[index],
                            child: Text(_currencyList[index]))),
                    onChanged:
                        switchSnapshot.data!.enableCurrencyOverride == true
                            ? (dynamic value) {
                                _bloc.updateSelectedOverrideCurrency(value);
                              }
                            : null,
                    value: switchSnapshot.data!.selectedCurrencyOverride!.isEmpty
                        ? _currencyList[0]
                        : switchSnapshot.data!.selectedCurrencyOverride,
                  );
                },
                stream: _bloc.overrideDefaultCurrencyValueStream as Stream<OverrideCurrencyStateHelper>?,
                initialData: _bloc.overrideCurrencyStateHelper,
              )
            ],
          ),
          flex: 1,
        )
      ],
    );
  }
}
