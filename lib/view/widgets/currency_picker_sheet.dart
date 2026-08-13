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
///
/// [priorityCurrencies] são as moedas que aparecem numa seção própria antes do
/// resto da lista — as escolhidas para a tela inicial. São as moedas que o
/// usuário acompanha, então são também as que ele mais converte: deixá-las no
/// alto poupa a busca ou a rolagem pelo alfabeto a cada conversão.
Future<Currencies?> showCurrencyPicker(
  BuildContext context, {
  required Currencies selectedCurrency,
  List<Currencies> priorityCurrencies = const [],
}) {
  return showModalBottomSheet<Currencies>(
    context: context,
    // A lista ocupa boa parte da tela e o teclado da busca sobe por cima: sem
    // isso a folha ficaria presa a metade da altura.
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _CurrencyPickerSheet(
      selectedCurrency: selectedCurrency,
      priorityCurrencies: priorityCurrencies,
    ),
  );
}

/// Uma linha da lista do seletor: ou o título de uma das duas seções, ou uma
/// moeda. As duas coisas na mesma lista para a rolagem ser contínua — com uma
/// lista por seção, as moedas do topo rolariam separadas do resto.
class _PickerEntry {
  /// Título da seção, nulo nas linhas de moeda.
  final String? sectionTitle;

  /// Moeda da linha, nula nos títulos de seção.
  final Currencies? currency;

  const _PickerEntry.section(String this.sectionTitle) : currency = null;

  const _PickerEntry.currency(Currencies this.currency) : sectionTitle = null;

  bool get isSection => sectionTitle != null;
}

class _CurrencyPickerSheet extends StatefulWidget {
  final Currencies selectedCurrency;
  final List<Currencies> priorityCurrencies;

  const _CurrencyPickerSheet({
    required this.selectedCurrency,
    this.priorityCurrencies = const [],
  });

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
            _entries(Localizations.localeOf(context),
                MyAppLocalizations.of(context)!),
            Responsive.scaleFactor(context)));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController?.dispose();
    super.dispose();
  }

  /// Deixa a moeda escolhida a duas linhas do topo, para as vizinhas de cima
  /// também aparecerem. O ScrollController corta o que passar do fim da lista.
  ///
  /// Com as moedas da tela inicial no alto, a escolhida costuma estar entre
  /// elas: aí a lista abre no começo, que é onde ela está.
  double _offsetOfSelectedCurrency(List<_PickerEntry> entries, double scale) {
    var index =
        entries.indexWhere((entry) => entry.currency == widget.selectedCurrency);
    if (index < 0) return 0;
    var offset = 0.0;
    // Duas linhas a menos: as alturas variam (título de seção e moeda), então
    // a folga é a das duas linhas imediatamente acima, e não duas vezes a
    // altura de uma moeda.
    for (var before = 0; before < index - 2; before++) {
      offset += _entryExtent(entries[before], scale);
    }
    return offset;
  }

  /// Altura de cada tipo de linha. São fixas para a posição da moeda escolhida
  /// poder ser calculada sem medir a lista, que é como a rolagem inicial sabe
  /// onde parar.
  double _tileExtent(double scale) => 72 * scale;

  double _sectionExtent(double scale) => 40 * scale;

  double _entryExtent(_PickerEntry entry, double scale) =>
      entry.isSection ? _sectionExtent(scale) : _tileExtent(scale);

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

  /// A lista já montada: as moedas da tela inicial primeiro, na ordem em que
  /// aparecem lá, e o resto do alfabeto embaixo.
  ///
  /// Sem moedas em destaque — ou quando a busca não deixou nenhuma delas na
  /// lista — não há o que separar, e a lista sai sem títulos: dois títulos com
  /// uma seção vazia entre eles só ocupariam espaço.
  List<_PickerEntry> _entries(Locale locale, MyAppLocalizations localizations) {
    var matches = _matchingCurrencies(locale);
    var priority = widget.priorityCurrencies
        .where(matches.contains)
        // Uma moeda repetida na configuração viraria duas linhas iguais.
        .toSet()
        .toList();
    if (priority.isEmpty) {
      return [for (var currency in matches) _PickerEntry.currency(currency)];
    }
    return [
      _PickerEntry.section(localizations.conversionCurrencyPickerYoursLabel!),
      for (var currency in priority) _PickerEntry.currency(currency),
      _PickerEntry.section(localizations.conversionCurrencyPickerOthersLabel!),
      for (var currency in matches)
        if (!priority.contains(currency)) _PickerEntry.currency(currency),
    ];
  }

  Widget _entryTile(_PickerEntry entry, Locale locale, double scale) {
    var sectionTitle = entry.sectionTitle;
    if (sectionTitle != null) {
      return _SectionHeader(title: sectionTitle, scale: scale);
    }
    var currency = entry.currency!;
    return _CurrencyOptionTile(
      currency: currency,
      locale: locale,
      scale: scale,
      isSelected: currency == widget.selectedCurrency,
      onTap: () => Navigator.of(context).pop(currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MyAppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final scale = Responsive.scaleFactor(context);
    final textTheme = Theme.of(context).textTheme;
    final entries = _entries(locale, localizations);

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
              child: entries.isEmpty
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
                      itemCount: entries.length,
                      itemBuilder: (context, index) => SizedBox(
                        // A altura de cada linha vem do mesmo lugar que a
                        // conta da rolagem inicial: se as duas divergirem, a
                        // lista abre fora da moeda escolhida.
                        height: _entryExtent(entries[index], scale),
                        child: _entryTile(entries[index], locale, scale),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título de uma das duas seções da lista.
class _SectionHeader extends StatelessWidget {
  final String title;
  final double scale;

  const _SectionHeader({required this.title, required this.scale});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding:
          EdgeInsets.fromLTRB(16 * scale, 12 * scale, 16 * scale, 4 * scale),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: colorScheme.primary,
          ),
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
