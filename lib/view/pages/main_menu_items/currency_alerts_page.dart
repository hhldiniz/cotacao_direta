import 'package:cotacao_direta/blocs/currency_alerts_bloc.dart';
import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/providers/currency_alerts_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/widgets/animated_list_entry.dart';
import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:cotacao_direta/view/widgets/notification_permission_card.dart';
import 'package:flutter/material.dart';

class CurrencyAlertsPage extends StatefulWidget {
  @override
  State<CurrencyAlertsPage> createState() => _CurrencyAlertsPageState();
}

class _CurrencyAlertsPageState extends State<CurrencyAlertsPage> {
  var _alertsLoaded = false;

  @override
  Widget build(BuildContext context) {
    final _bloc = CurrencyAlertsBlocProvider.of(context);
    if (!_alertsLoaded) {
      _alertsLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _bloc.loadAlerts());
    }
    final _localization = MyAppLocalizations.of(context)!;
    final _scale = Responsive.scaleFactor(context);
    final _currencyList = List.generate(Currencies.values.length, (index) {
      return EnumValueAsString()
          .getEnumValue(Currencies.values.elementAt(index).toString());
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        // Ver a nota no FAB da home: as duas telas coexistem no IndexedStack.
        heroTag: "addCurrencyAlertFab",
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
                // O aviso de permissão fica acima do estado vazio, e não
                // dentro dele: é justamente quem ainda não criou nenhum alerta
                // que precisa ler isto antes de cadastrar o primeiro.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16 * _scale),
                      child: const NotificationPermissionCard(),
                    ),
                    Expanded(
                      child: _emptyState(context, _localization, _scale),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16 * _scale,
                  0,
                  16 * _scale,
                  // Espaço para o FAB não cobrir o último alerta.
                  96 * _scale,
                ),
                itemCount: alerts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BentoSectionTitle(
                          _localization.currencyAlertsSectionLabel!,
                        ),
                        const NotificationPermissionCard(),
                      ],
                    );
                  }
                  final alert = alerts[index - 1];
                  return AnimatedListEntry(
                    index: index,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10 * _scale),
                      child: _AlertCard(
                        alert: alert,
                        localization: _localization,
                        scale: _scale,
                        onDelete: () => _bloc.deleteAlert(alert.id!),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _emptyState(
    BuildContext context,
    MyAppLocalizations localization,
    double scale,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72 * scale,
              height: 72 * scale,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24 * scale),
              ),
              child: Icon(
                Icons.notifications_none,
                size: 36 * scale,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 16 * scale),
            Text(
              localization.currencyAlertEmptyListLabel!,
              style: TextStyle(
                fontSize: 16 * scale,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BentoRadius.hero),
            ),
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
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(BentoRadius.standard),
                      ),
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

class _AlertCard extends StatelessWidget {
  final CurrencyAlert alert;
  final MyAppLocalizations localization;
  final double scale;
  final VoidCallback onDelete;

  const _AlertCard({
    required this.alert,
    required this.localization,
    required this.scale,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    var conditionLabel = alert.condition == CurrencyAlertCondition.above
        ? localization.currencyAlertConditionAbove!
        : localization.currencyAlertConditionBelow!;
    var statusLabel = alert.triggered
        ? localization.currencyAlertTriggeredLabel!
        : localization.currencyAlertActiveLabel!;
    // Disparado ganha destaque em verde; aguardando fica na cor neutra do
    // tema, para o olho ir direto no que já aconteceu.
    final statusColor =
        alert.triggered ? const Color(0xFF2E9E5B) : colorScheme.outline;

    return BentoCard(
      padding: EdgeInsets.all(12 * scale),
      child: Row(
        children: [
          Container(
            width: 42 * scale,
            height: 42 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14 * scale),
            ),
            child: Icon(
              alert.triggered
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: statusColor,
              size: 22 * scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${alert.currencyCode} $conditionLabel "
                  "${alert.targetValue.toStringAsFixed(4)}",
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4 * scale),
                // Pílula de status, no lugar do subtítulo solto.
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * scale,
                    vertical: 2 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11 * scale,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: localization.currencyAlertDeleteTooltip,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
