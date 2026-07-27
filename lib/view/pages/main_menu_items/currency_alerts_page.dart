import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/providers/currency_alerts_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:flutter/material.dart';

class CurrencyAlertsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _bloc = CurrencyAlertsBlocProvider.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bloc.loadAlerts());
    final _localization = MyAppLocalizations.of(context)!;
    final _scale = Responsive.scaleFactor(context);
    final _currencyList = List.generate(Currencies.values.length, (index) {
      return EnumValueAsString()
          .getEnumValue(Currencies.values.elementAt(index).toString());
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddAlertDialog(context, _bloc, _localization, _currencyList),
        label: Text(_localization.addCurrencyAlertBtnLabel!),
        icon: const Icon(Icons.add_alert),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
          child: StreamBuilder<List<CurrencyAlert>>(
            stream: _bloc.alertsStream,
            builder: (context, snapshot) {
              var alerts = snapshot.data ?? [];
              if (alerts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(24 * _scale),
                    child: Text(
                      _localization.currencyAlertEmptyListLabel!,
                      style: TextStyle(fontSize: 16 * _scale),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView(
                padding: EdgeInsets.symmetric(vertical: 16 * _scale),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24 * _scale),
                    child: Text(
                      _localization.currencyAlertsSectionLabel!,
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
                        for (var index = 0; index < alerts.length; index++) ...[
                          if (index > 0) const Divider(height: 1),
                          _AlertListTile(
                            alert: alerts[index],
                            localization: _localization,
                            scale: _scale,
                            onDelete: () => _bloc.deleteAlert(alerts[index].id!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddAlertDialog(BuildContext context, CurrencyAlertsBloc bloc,
      MyAppLocalizations localization, List<String> currencyList) {
    var selectedCurrency = currencyList.first;
    var selectedCondition = CurrencyAlertCondition.above;
    var targetValueController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(localization.addCurrencyAlertDialogTitle!),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(localization.currencyAlertCurrencyLabel!),
                      DropdownButton<String>(
                        value: selectedCurrency,
                        items: currencyList
                            .map((code) => DropdownMenuItem(
                                value: code, child: Text(code)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedCurrency = value!),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(localization.currencyAlertConditionLabel!),
                      DropdownButton<CurrencyAlertCondition>(
                        value: selectedCondition,
                        items: [
                          DropdownMenuItem(
                              value: CurrencyAlertCondition.above,
                              child:
                                  Text(localization.currencyAlertConditionAbove!)),
                          DropdownMenuItem(
                              value: CurrencyAlertCondition.below,
                              child:
                                  Text(localization.currencyAlertConditionBelow!)),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedCondition = value!),
                      ),
                    ],
                  ),
                  TextField(
                    controller: targetValueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: localization.currencyAlertTargetValueLabel,
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(localization.currencyAlertCancelBtnLabel!),
              ),
              TextButton(
                onPressed: () async {
                  var targetValue = double.tryParse(
                      targetValueController.text.replaceAll(',', '.'));
                  if (targetValue == null || targetValue <= 0) {
                    setState(() => errorText =
                        localization.currencyAlertInvalidValueError);
                    return;
                  }
                  await bloc.addAlert(
                      selectedCurrency, targetValue, selectedCondition);
                  Navigator.of(dialogContext).pop();
                },
                child: Text(localization.currencyAlertSaveBtnLabel!),
              ),
            ],
          );
        });
      },
    );
  }
}

class _AlertListTile extends StatelessWidget {
  final CurrencyAlert alert;
  final MyAppLocalizations localization;
  final double scale;
  final VoidCallback onDelete;

  const _AlertListTile({
    required this.alert,
    required this.localization,
    required this.scale,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    var conditionLabel = alert.condition == CurrencyAlertCondition.above
        ? localization.currencyAlertConditionAbove!
        : localization.currencyAlertConditionBelow!;
    var statusLabel = alert.triggered
        ? localization.currencyAlertTriggeredLabel!
        : localization.currencyAlertActiveLabel!;

    return ListTile(
      leading: Icon(
        alert.triggered ? Icons.notifications_active : Icons.notifications_none,
        color: alert.triggered ? Colors.green : null,
      ),
      title: Text(
        "${alert.currencyCode} $conditionLabel ${alert.targetValue.toStringAsFixed(4)}",
        style: TextStyle(fontSize: 16 * scale),
      ),
      subtitle: Text(statusLabel, style: TextStyle(fontSize: 12 * scale)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: localization.currencyAlertDeleteTooltip,
        onPressed: onDelete,
      ),
    );
  }
}
