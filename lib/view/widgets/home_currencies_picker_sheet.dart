import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/util/currency_name.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/widgets/currency_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

/// Abre a folha de escolha das moedas que viram bolha na tela inicial e devolve
/// os códigos escolhidos, na ordem em que foram marcados — a primeira é a
/// bolha de destaque. Devolve nulo se o usuário fechar sem confirmar.
///
/// Quem a abre é o cartão de acrescentar, no fim da própria grade de bolhas.
///
/// É a mesma lista rolável com busca do seletor de moeda da conversão, só que
/// com marcação múltipla: são mais de trinta moedas, e escolher várias em um
/// menu suspenso não funcionaria.
Future<List<String>?> showHomeCurrenciesPicker(
  BuildContext context, {
  required List<String> selectedCurrencyCodes,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    // A lista ocupa boa parte da tela e o teclado da busca sobe por cima.
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _HomeCurrenciesPickerSheet(
      selectedCurrencyCodes: selectedCurrencyCodes,
    ),
  );
}

class _HomeCurrenciesPickerSheet extends StatefulWidget {
  final List<String> selectedCurrencyCodes;

  const _HomeCurrenciesPickerSheet({required this.selectedCurrencyCodes});

  @override
  State<_HomeCurrenciesPickerSheet> createState() =>
      _HomeCurrenciesPickerSheetState();
}

class _HomeCurrenciesPickerSheetState
    extends State<_HomeCurrenciesPickerSheet> {
  final _searchController = TextEditingController();
  var _query = "";

  /// Ordem de escolha, e não ordem alfabética: é ela que decide qual moeda
  /// fica na bolha de destaque e em que sequência as outras aparecem.
  late final List<Currencies> _selected = widget.selectedCurrencyCodes
      .map(currencyForCode)
      .whereType<Currencies>()
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Currencies> _matchingCurrencies(Locale locale) {
    var query = withoutAccents(_query.trim());
    var currencies = Currencies.values.toList()
      ..sort((first, second) =>
          currencyName(first, locale).compareTo(currencyName(second, locale)));
    if (query.isEmpty) return currencies;
    return currencies
        .where((currency) =>
            withoutAccents(currencyCode(currency)).contains(query) ||
            withoutAccents(currencyName(currency, locale)).contains(query))
        .toList();
  }

  void _toggle(Currencies currency) {
    setState(() {
      if (!_selected.remove(currency)) _selected.add(currency);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MyAppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final scale = Responsive.scaleFactor(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final currencies = _matchingCurrencies(locale);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        // O teclado da busca cobriria as últimas linhas da lista.
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  EdgeInsets.fromLTRB(24 * scale, 0, 24 * scale, 4 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.homeCurrenciesPickerTitle!,
                    style: textTheme.titleMedium,
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    localizations.homeCurrenciesPickerDescription!,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: localizations.conversionCurrencySearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = "");
                          },
                        ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28 * scale)),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            SizedBox(height: 8 * scale),
            Expanded(
              child: currencies.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24 * scale),
                        child: Text(
                          localizations.conversionCurrencyNotFoundLabel!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemExtent: 72 * scale,
                      itemCount: currencies.length,
                      itemBuilder: (context, index) {
                        final currency = currencies[index];
                        return _CurrencyCheckTile(
                          currency: currency,
                          locale: locale,
                          scale: scale,
                          isSelected: _selected.contains(currency),
                          onTap: () => _toggle(currency),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16 * scale, 8 * scale, 16 * scale, 16 * scale),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selected.isEmpty
                          ? localizations.homeCurrenciesEmptySelectionLabel!
                          : sprintf(
                              localizations.homeCurrenciesSelectedCountLabel!,
                              ["${_selected.length}"]),
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: _selected.isEmpty
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  FilledButton(
                    // Sem nenhuma moeda marcada não há o que gravar: a tela
                    // inicial ficaria sem cotação nenhuma.
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(context)
                            .pop(_selected.map(currencyCode).toList()),
                    child: Text(localizations.homeCurrenciesSaveBtnLabel!),
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

class _CurrencyCheckTile extends StatelessWidget {
  final Currencies currency;
  final Locale locale;
  final double scale;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyCheckTile({
    required this.currency,
    required this.locale,
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      leading: CurrencyFlagBadge(currency: currency, scale: scale),
      title: Text(
        currencyCode(currency),
        style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        currencyName(currency, locale),
        style: TextStyle(fontSize: 13 * scale),
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (_) => onTap(),
      ),
      onTap: onTap,
    );
  }
}
