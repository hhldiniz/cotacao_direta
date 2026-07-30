import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/util/currency_flag.dart';
import 'package:cotacao_direta/util/currency_name.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:flag/flag.dart';
import 'package:flutter/material.dart';

/// Abre a folha de escolha de moeda e devolve a moeda escolhida, ou nulo se o
/// usuário fechar sem escolher.
///
/// Uma lista rolável com busca no lugar do menu suspenso: são mais de trinta
/// moedas, e num menu suspenso elas viravam uma coluna de siglas de três
/// letras que o usuário tinha que percorrer até achar a certa.
Future<Currencies?> showCurrencyPicker(
  BuildContext context, {
  required Currencies selectedCurrency,
}) {
  return showModalBottomSheet<Currencies>(
    context: context,
    // A lista ocupa boa parte da tela e o teclado da busca sobe por cima: sem
    // isso a folha ficaria presa a metade da altura.
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        _CurrencyPickerSheet(selectedCurrency: selectedCurrency),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  final Currencies selectedCurrency;

  const _CurrencyPickerSheet({required this.selectedCurrency});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchController = TextEditingController();
  var _query = "";

  ScrollController? _listController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A lista abre já na moeda que está escolhida, em vez de no começo do
    // alfabeto: quem abre o seletor quer ver de onde está saindo.
    _listController ??= ScrollController(
        initialScrollOffset: _offsetOfSelectedCurrency(
            Localizations.localeOf(context), Responsive.scaleFactor(context)));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController?.dispose();
    super.dispose();
  }

  /// Deixa a moeda escolhida a duas linhas do topo, para as vizinhas de cima
  /// também aparecerem. O ScrollController corta o que passar do fim da lista.
  double _offsetOfSelectedCurrency(Locale locale, double scale) {
    var index = _matchingCurrencies(locale).indexOf(widget.selectedCurrency);
    if (index < 0) return 0;
    return ((index - 2) * _tileExtent(scale)).clamp(0, double.infinity);
  }

  /// Altura fixa de cada linha: além de deixar a rolagem mais barata, é o que
  /// permite calcular a posição da moeda escolhida sem medir a lista.
  double _tileExtent(double scale) => 72 * scale;

  List<Currencies> _matchingCurrencies(Locale locale) {
    var query = withoutAccents(_query.trim());
    var currencies = Currencies.values.toList()
      ..sort((first, second) => currencyName(first, locale)
          .compareTo(currencyName(second, locale)));
    if (query.isEmpty) return currencies;
    return currencies
        .where((currency) =>
            withoutAccents(currencyCode(currency)).contains(query) ||
            withoutAccents(currencyName(currency, locale)).contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MyAppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final scale = Responsive.scaleFactor(context);
    final textTheme = Theme.of(context).textTheme;
    final currencies = _matchingCurrencies(locale);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        // O teclado da busca cobriria as últimas linhas da lista.
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24 * scale, 0, 24 * scale, 8 * scale),
              child: Text(
                localizations.conversionCurrencyPickerTitle!,
                style: textTheme.titleMedium,
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
                onChanged: (value) {
                  setState(() => _query = value);
                  // A lista pode estar rolada na moeda escolhida; os
                  // resultados da busca começam do topo.
                  if (_listController?.hasClients ?? false) {
                    _listController!.jumpTo(0);
                  }
                },
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
                      controller: _listController,
                      itemExtent: _tileExtent(scale),
                      itemCount: currencies.length,
                      itemBuilder: (context, index) => _CurrencyOptionTile(
                        currency: currencies[index],
                        locale: locale,
                        scale: scale,
                        isSelected: currencies[index] == widget.selectedCurrency,
                        onTap: () =>
                            Navigator.of(context).pop(currencies[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyOptionTile extends StatelessWidget {
  final Currencies currency;
  final Locale locale;
  final double scale;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyOptionTile({
    required this.currency,
    required this.locale,
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      selected: isSelected,
      leading: CurrencyFlagBadge(currency: currency, scale: scale),
      title: Text(
        currencyCode(currency),
        style: TextStyle(
          fontSize: 16 * scale,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        currencyName(currency, locale),
        style: TextStyle(fontSize: 13 * scale),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: colorScheme.primary, size: 22 * scale)
          : null,
      onTap: onTap,
    );
  }
}

/// Bandeira da moeda com os cantos arredondados, no mesmo tamanho em toda a
/// tela de conversão.
class CurrencyFlagBadge extends StatelessWidget {
  final Currencies currency;
  final double scale;

  const CurrencyFlagBadge({Key? key, required this.currency, required this.scale})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4 * scale),
      child: Flag.fromCode(
        flagCodeForCurrency(currency),
        height: 24 * scale,
        width: 32 * scale,
        fit: BoxFit.cover,
      ),
    );
  }
}
