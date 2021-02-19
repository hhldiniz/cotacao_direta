import 'package:cotacao_direta/blocs/configurations_page_bloc.dart';
import 'package:cotacao_direta/providers/configurations_page_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ConfigurationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ConfigurationsPageBloc _bloc = ConfigurationsPageBlocProvider.of(context);
    var _localization = MyAppLocalizations.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              child: Row(
                children: [
                  Switch(value: false, onChanged: (bool checked) {}),
                  Text(_localization.overrideDefaultCurrencySwitchLabel)
                ],
              ),
            ),
            DropdownButton(items: null, onChanged: null)
          ],
        )
      ],
    );
  }
}
