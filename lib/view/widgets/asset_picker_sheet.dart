import 'package:cotacao_direta/enums/cryptocurrency_enum.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/util/cryptocurrency_info.dart';
import 'package:cotacao_direta/util/currency_flag.dart';
import 'package:cotacao_direta/util/currency_name.dart';
import 'package:cotacao_direta/util/currency_visuals.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:flag/flag.dart';
import 'package:flutter/material.dart';

/// Um ativo que o usuário pode escolher: uma moeda fiduciária ou uma
/// criptomoeda.
///
/// Guarda o próprio valor do enum, e não só o código, para que o nome por
/// extenso, a bandeira e a cor de destaque saiam daqui em vez de serem
/// procurados de novo em cada tela.
class AssetOption {
  /// Preenchida apenas quando o ativo é moeda fiduciária.
  final Currencies? currency;

  /// Preenchida apenas quando o ativo é criptomoeda.
  final Cryptocurrencies? cryptocurrency;

  const AssetOption.currency(Currencies this.currency) : cryptocurrency = null;

  const AssetOption.cryptocurrency(Cryptocurrencies this.cryptocurrency)
      : currency = null;

  AssetKind get kind =>
      currency != null ? AssetKind.currency : AssetKind.cryptocurrency;

  bool get isCryptocurrency => currency == null;

  /// Código do ativo: ISO 4217 nas moedas ("USD"), sigla de mercado nas
  /// criptomoedas ("BTC").
  String get code => currency?.name ?? cryptocurrency!.name;

  /// Nome por extenso no idioma de [locale]. As criptomoedas têm um nome só,
  /// que não se traduz.
  String name(Locale locale) => currency != null
      ? currencyName(currency!, locale)
      : cryptocurrencyName(cryptocurrency!);

  Color get accentColor => currency != null
      ? currencyAccentColor(currency!)
      : cryptocurrencyAccentColor(cryptocurrency!);

  @override
  bool operator ==(Object other) =>
      other is AssetOption &&
      other.currency == currency &&
      other.cryptocurrency == cryptocurrency;

  @override
  int get hashCode => Object.hash(currency, cryptocurrency);
}

/// Selo do ativo: a bandeira da moeda ou o ícone da criptomoeda dentro da
/// mesma moldura colorida, para que os dois tipos fiquem alinhados e com o
/// mesmo peso visual na lista — como já acontece na listagem de histórico.
class AssetBadge extends StatelessWidget {
  final AssetOption asset;
  final double scale;

  const AssetBadge({super.key, required this.asset, required this.scale});

  @override
  Widget build(BuildContext context) {
    final accent = asset.accentColor;
    final currency = asset.currency;

    return Container(
      width: 46 * scale,
      height: 40 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: currency != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6 * scale),
              child: Flag.fromCode(
                flagCodeForCurrency(currency),
                height: 24 * scale,
                width: 32 * scale,
                fit: BoxFit.cover,
              ),
            )
          : Icon(
              iconForCryptocurrency(asset.cryptocurrency!),
              size: 22 * scale,
              color: accent,
            ),
    );
  }
}

/// Abre a folha de escolha de ativo e devolve o ativo escolhido, ou nulo se o
/// usuário fechar sem escolher.
///
/// É a mesma lista rolável com busca do seletor de moeda da conversão, só que
/// separada em moedas e criptomoedas: são mais de quarenta ativos, e num menu
/// suspenso eles viravam uma coluna de siglas que o usuário tinha que
/// percorrer até achar a certa.
Future<AssetOption?> showAssetPicker(
  BuildContext context, {
  required List<AssetOption> assets,
  required AssetOption selectedAsset,
}) {
  return showModalBottomSheet<AssetOption>(
    context: context,
    // A lista ocupa boa parte da tela e o teclado da busca sobe por cima: sem
    // isso a folha ficaria presa a metade da altura.
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        _AssetPickerSheet(assets: assets, selectedAsset: selectedAsset),
  );
}

/// Uma linha da folha: o título de uma seção ou um ativo. As duas convivem na
/// mesma lista para que a rolagem valha para o conjunto todo.
sealed class _PickerEntry {}

class _SectionEntry extends _PickerEntry {
  final String label;

  _SectionEntry(this.label);
}

class _AssetEntry extends _PickerEntry {
  final AssetOption asset;

  _AssetEntry(this.asset);
}

class _AssetPickerSheet extends StatefulWidget {
  final List<AssetOption> assets;
  final AssetOption selectedAsset;

  const _AssetPickerSheet({required this.assets, required this.selectedAsset});

  @override
  State<_AssetPickerSheet> createState() => _AssetPickerSheetState();
}

class _AssetPickerSheetState extends State<_AssetPickerSheet> {
  final _searchController = TextEditingController();
  var _query = "";

  ScrollController? _listController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A lista abre já no ativo que está escolhido, em vez de no começo do
    // alfabeto: quem abre o seletor quer ver de onde está saindo.
    _listController ??= ScrollController(
        initialScrollOffset: _offsetOfSelectedAsset(
            _entries(context), Responsive.scaleFactor(context)));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController?.dispose();
    super.dispose();
  }

  /// Altura fixa de cada linha: além de deixar a rolagem mais barata, é o que
  /// permite calcular a posição do ativo escolhido sem medir a lista.
  double _tileExtent(double scale) => 72 * scale;

  double _sectionExtent(double scale) => 48 * scale;

  double _extentOf(_PickerEntry entry, double scale) => switch (entry) {
        _SectionEntry() => _sectionExtent(scale),
        _AssetEntry() => _tileExtent(scale),
      };

  /// Deixa o ativo escolhido a duas linhas do topo, para os vizinhos de cima
  /// também aparecerem. O ScrollController corta o que passar do fim da lista.
  double _offsetOfSelectedAsset(List<_PickerEntry> entries, double scale) {
    final index = entries.indexWhere((entry) =>
        entry is _AssetEntry && entry.asset == widget.selectedAsset);
    if (index < 0) return 0;
    var offset = 0.0;
    for (var position = 0; position < index; position++) {
      offset += _extentOf(entries[position], scale);
    }
    return (offset - 2 * _tileExtent(scale)).clamp(0, double.infinity);
  }

  bool _matchesQuery(AssetOption asset, Locale locale) {
    final query = withoutAccents(_query.trim());
    if (query.isEmpty) return true;
    return withoutAccents(asset.code).contains(query) ||
        withoutAccents(asset.name(locale)).contains(query);
  }

  /// As linhas da folha, na ordem em que aparecem: as moedas e, depois, as
  /// criptomoedas, cada grupo em ordem alfabética de nome e com o próprio
  /// título — um título só aparece quando sobrou algum ativo do grupo na
  /// busca.
  List<_PickerEntry> _entries(BuildContext context) {
    final localizations = MyAppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    List<_PickerEntry> group(String label, bool cryptocurrencies) {
      final assets = widget.assets
          .where((asset) => asset.isCryptocurrency == cryptocurrencies)
          .where((asset) => _matchesQuery(asset, locale))
          .toList()
        ..sort((first, second) =>
            first.name(locale).compareTo(second.name(locale)));
      if (assets.isEmpty) return const [];
      return [_SectionEntry(label), ...assets.map(_AssetEntry.new)];
    }

    return [
      ...group(localizations.currencyHistoryCurrenciesSectionLabel!, false),
      ...group(
          localizations.currencyHistoryCryptocurrenciesSectionLabel!, true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MyAppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final scale = Responsive.scaleFactor(context);
    final textTheme = Theme.of(context).textTheme;
    final entries = _entries(context);

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
                  EdgeInsets.fromLTRB(24 * scale, 0, 24 * scale, 8 * scale),
              child: Text(
                localizations.aiInsightsAssetPickerTitle!,
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
                  // A lista pode estar rolada no ativo escolhido; os
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
                          localizations.aiInsightsAssetNotFoundLabel!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _listController,
                      // Altura conhecida linha a linha: a rolagem não precisa
                      // medir nada e a posição do ativo escolhido bate.
                      itemExtentBuilder: (index, _) =>
                          _extentOf(entries[index], scale),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return switch (entry) {
                          _SectionEntry() => BentoSectionTitle(entry.label),
                          _AssetEntry() => _AssetOptionTile(
                              asset: entry.asset,
                              locale: locale,
                              scale: scale,
                              isSelected: entry.asset == widget.selectedAsset,
                              onTap: () =>
                                  Navigator.of(context).pop(entry.asset),
                            ),
                        };
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetOptionTile extends StatelessWidget {
  final AssetOption asset;
  final Locale locale;
  final double scale;
  final bool isSelected;
  final VoidCallback onTap;

  const _AssetOptionTile({
    required this.asset,
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
      leading: AssetBadge(asset: asset, scale: scale),
      title: Text(
        asset.code,
        style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        asset.name(locale),
        style: TextStyle(fontSize: 13 * scale),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: colorScheme.primary, size: 22 * scale)
          : null,
      onTap: onTap,
    );
  }
}
