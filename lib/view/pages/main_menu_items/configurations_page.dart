import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/configurations_page_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/widgets/widget_state_helpers/override_currency_state_helper.dart';
import 'package:flutter/material.dart';

class ConfigurationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ConfigurationsPageBloc _bloc = ConfigurationsPageBlocProvider.of(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _bloc.loadCurrentConfiguration(),
    );
    final _currencyList = List.generate(Currencies.values.length, (index) {
      return EnumValueAsString().getEnumValue(
        Currencies.values.elementAt(index).toString(),
      );
    });
    var _localization = MyAppLocalizations.of(context)!;
    final _scale = Responsive.scaleFactor(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.contentMaxWidth(context),
        ),
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 16 * _scale),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * _scale),
              child: Text(
                _localization.appConfigurationsSectionLabel!,
                style: TextStyle(
                  fontSize: 14 * _scale,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 8 * _scale),
            Card(
              margin: EdgeInsets.symmetric(horizontal: 12 * _scale),
              child: Column(
                children: [
                  StreamBuilder<OverrideCurrencyStateHelper>(
                    builder: (BuildContext context, snapshot) {
                      return SwitchListTile(
                        value: snapshot.data!.enableCurrencyOverride,
                        onChanged: (bool checked) {
                          _bloc.updateOverrideCurrencySwitch(checked);
                        },
                        title: Text(
                          _localization.overrideDefaultCurrencySwitchLabel!,
                          style: TextStyle(fontSize: 16 * _scale),
                        ),
                      );
                    },
                    stream:
                        _bloc.overrideDefaultCurrencyValueStream
                            as Stream<OverrideCurrencyStateHelper>?,
                    initialData: _bloc.overrideCurrencyStateHelper,
                  ),
                  const Divider(height: 1),
                  StreamBuilder<OverrideCurrencyStateHelper>(
                    builder: (BuildContext context, switchSnapshot) {
                      final _enabled =
                          switchSnapshot.data!.enableCurrencyOverride == true;
                      return ListTile(
                        enabled: _enabled,
                        leading: const Icon(Icons.attach_money),
                        title: Text(
                          _localization.selectedOverrideCurrencyLabel!,
                          style: TextStyle(fontSize: 16 * _scale),
                        ),
                        trailing: DropdownButton(
                          items: List.generate(
                            _currencyList.length,
                            (index) => DropdownMenuItem(
                              value: _currencyList[index],
                              child: Text(
                                _currencyList[index],
                                style: TextStyle(fontSize: 16 * _scale),
                              ),
                            ),
                          ),
                          onChanged: _enabled
                              ? (dynamic value) {
                                  _bloc.updateSelectedOverrideCurrency(value);
                                }
                              : null,
                          value:
                              switchSnapshot
                                  .data!
                                  .selectedCurrencyOverride!
                                  .isEmpty
                              ? _currencyList[0]
                              : switchSnapshot.data!.selectedCurrencyOverride,
                          iconSize: 24 * _scale,
                        ),
                      );
                    },
                    stream:
                        _bloc.overrideDefaultCurrencyValueStream
                            as Stream<OverrideCurrencyStateHelper>?,
                    initialData: _bloc.overrideCurrencyStateHelper,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
