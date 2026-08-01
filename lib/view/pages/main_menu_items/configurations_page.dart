import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/configurations_page_bloc_provider.dart';
import 'package:cotacao_direta/util/currency_colors.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/widgets/animated_list_entry.dart';
import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:flutter/material.dart';

import 'package:cotacao_direta/view/widgets/widget_state_helpers/override_currency_state_helper.dart';

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
    final _stream =
        _bloc.overrideDefaultCurrencyValueStream
            as Stream<OverrideCurrencyStateHelper>?;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.contentMaxWidth(context),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16 * _scale,
            0,
            16 * _scale,
            24 * _scale,
          ),
          children: [
            BentoSectionTitle(_localization.appConfigurationsSectionLabel!),

            // Cada opção vira um tile próprio, como na grade da tela inicial,
            // em vez de linhas dentro de um cartão único.
            AnimatedListEntry(
              index: 0,
              child: StreamBuilder<OverrideCurrencyStateHelper>(
                stream: _stream,
                initialData: _bloc.overrideCurrencyStateHelper,
                builder: (BuildContext context, snapshot) {
                  final enabled = snapshot.data!.enableCurrencyOverride;
                  return BentoCard(
                    padding: EdgeInsets.all(12 * _scale),
                    // Tocar o cartão inteiro alterna a opção, como fazia o
                    // SwitchListTile que estava aqui antes.
                    onTap: () => _bloc.updateOverrideCurrencySwitch(!enabled),
                    child: Row(
                      children: [
                        _SettingBadge(
                          icon: Icons.swap_horiz,
                          color: CurrencyColors.eur,
                          scale: _scale,
                        ),
                        SizedBox(width: 14 * _scale),
                        Expanded(
                          child: Text(
                            _localization.overrideDefaultCurrencySwitchLabel!,
                            style: TextStyle(fontSize: 16 * _scale),
                          ),
                        ),
                        Switch(
                          value: enabled,
                          onChanged: (bool checked) {
                            _bloc.updateOverrideCurrencySwitch(checked);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12 * _scale),

            AnimatedListEntry(
              index: 1,
              child: StreamBuilder<OverrideCurrencyStateHelper>(
                stream: _stream,
                initialData: _bloc.overrideCurrencyStateHelper,
                builder: (BuildContext context, switchSnapshot) {
                  final _enabled =
                      switchSnapshot.data!.enableCurrencyOverride == true;
                  final selected =
                      switchSnapshot.data!.selectedCurrencyOverride!.isEmpty
                      ? _currencyList[0]
                      : switchSnapshot.data!.selectedCurrencyOverride;
                  // Sem o override ligado o seletor não faz nada; deixá-lo
                  // esmaecido comunica isso antes do toque.
                  return Opacity(
                    opacity: _enabled ? 1.0 : 0.45,
                    child: BentoCard(
                      padding: EdgeInsets.all(12 * _scale),
                      child: Row(
                        children: [
                          _SettingBadge(
                            icon: Icons.attach_money,
                            color: CurrencyColors.usd,
                            scale: _scale,
                          ),
                          SizedBox(width: 14 * _scale),
                          Expanded(
                            child: Text(
                              _localization.selectedOverrideCurrencyLabel!,
                              style: TextStyle(fontSize: 16 * _scale),
                            ),
                          ),
                          DropdownButton(
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
                            value: selected,
                            iconSize: 24 * _scale,
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(
                              BentoRadius.standard,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quadradinho colorido com o ícone da opção, o mesmo recurso visual que dá
/// identidade aos cartões de moeda da tela inicial.
class _SettingBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double scale;

  const _SettingBadge({
    required this.icon,
    required this.color,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final size = 42.0 * scale;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      child: Icon(icon, color: color, size: 22 * scale),
    );
  }
}
