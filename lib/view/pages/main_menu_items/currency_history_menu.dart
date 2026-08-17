import 'package:cotacao_direta/blocs/currency_history_menu_bloc.dart';
import 'package:cotacao_direta/blocs/selected_currency_details_bloc.dart';
import 'package:cotacao_direta/enums/cryptocurrency_enum.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/currency_history_menu_bloc_provider.dart';
import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/util/cryptocurrency_info.dart';
import 'package:cotacao_direta/util/currency_colors.dart';
import 'package:cotacao_direta/util/currency_flag.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/pages/selected_currency_details.dart';
import 'package:cotacao_direta/view/widgets/animated_list_entry.dart';
import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:flag/flag.dart';
import 'package:flutter/material.dart';

/// Uma linha da listagem: o título de uma seção, uma moeda fiduciária ou uma
/// criptomoeda. As três convivem na mesma lista para que a rolagem e a
/// animação de entrada continuem valendo para o conjunto todo.
sealed class _HistoryEntry {}

class _SectionEntry extends _HistoryEntry {
  final String label;

  _SectionEntry(this.label);
}

class _CurrencyEntry extends _HistoryEntry {
  final Currencies currency;

  _CurrencyEntry(this.currency);
}

class _CryptocurrencyEntry extends _HistoryEntry {
  final Cryptocurrencies cryptocurrency;

  _CryptocurrencyEntry(this.cryptocurrency);
}

/// Código a partir do valor do enum: `Currencies.USD` -> "USD",
/// `Cryptocurrencies.BTC` -> "BTC".
String _codeOf(Object enumValue) =>
    EnumValueAsString().getEnumValue(enumValue.toString());

class CurrencyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = CurrencyHistoryMenuBlocProvider.of(context);
    final localizations = MyAppLocalizations.of(context)!;
    final _scale = Responsive.scaleFactor(context);

    return FutureBuilder<String>(
      future: bloc.counterCurrencyCode,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final counterCurrency = snapshot.data!;
        // A moeda usada como contrapartida não tem série própria para
        // desenhar: CurrencyRepository.getCurrencyHistoricalData pula a
        // consulta quando a moeda pedida é a própria contrapartida, e o
        // gráfico ficaria sempre em "Sem Dados" para ela.
        final _currencies = Currencies.values
            .where((currency) => _codeOf(currency) != counterCurrency)
            .toList();

        bloc.initStreamControllers(_currencies.map(_codeOf).toList());

        final _entries = <_HistoryEntry>[
          _SectionEntry(localizations.currencyHistoryCurrenciesSectionLabel!),
          ..._currencies.map((currency) => _CurrencyEntry(currency)),
          _SectionEntry(
            localizations.currencyHistoryCryptocurrenciesSectionLabel!,
          ),
          ...Cryptocurrencies.values.map(
            (cryptocurrency) => _CryptocurrencyEntry(cryptocurrency),
          ),
        ];

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16 * _scale,
                0,
                16 * _scale,
                24 * _scale,
              ),
              itemBuilder: (BuildContext context, index) {
                final entry = _entries[index];
                return AnimatedListEntry(
                  index: index,
                  child: switch (entry) {
                    _SectionEntry() => BentoSectionTitle(entry.label),
                    _CurrencyEntry() => Padding(
                      padding: EdgeInsets.only(bottom: 10 * _scale),
                      child: _currencyTile(context, bloc, entry.currency, _scale),
                    ),
                    _CryptocurrencyEntry() => Padding(
                      padding: EdgeInsets.only(bottom: 10 * _scale),
                      child: _cryptocurrencyTile(
                        context,
                        bloc,
                        entry.cryptocurrency,
                        _scale,
                      ),
                    ),
                  },
                );
              },
              itemCount: _entries.length,
            ),
          ),
        );
      },
    );
  }

  Widget _currencyTile(
    BuildContext context,
    CurrencyHistoryMenuBloc bloc,
    Currencies currency,
    double scale,
  ) {
    final currencyCode = _codeOf(currency);
    return _quoteTile(
      context,
      bloc: bloc,
      currencyCode: currencyCode,
      scale: scale,
      accent: CurrencyColors.eur,
      badge: ClipRRect(
        borderRadius: BorderRadius.circular(6 * scale),
        child: Flag.fromCode(
          flagCodeForCurrency(currency),
          height: 24 * scale,
          width: 32 * scale,
        ),
      ),
      subtitle: StreamBuilder<String?>(
        initialData: bloc.cachedCountryName(currencyCode),
        stream: bloc.getCountryNameController(currencyCode),
        builder: (context, snapshot) {
          bloc.getCountryNameByCurrencyCode(currencyCode);
          return _subtitleText(context, snapshot.data ?? "", scale);
        },
      ),
    );
  }

  Widget _cryptocurrencyTile(
    BuildContext context,
    CurrencyHistoryMenuBloc bloc,
    Cryptocurrencies cryptocurrency,
    double scale,
  ) {
    return _quoteTile(
      context,
      bloc: bloc,
      currencyCode: _codeOf(cryptocurrency),
      scale: scale,
      accent: CurrencyColors.usd,
      badge: Icon(
        iconForCryptocurrency(cryptocurrency),
        size: 22 * scale,
        color: CurrencyColors.usd,
      ),
      subtitle: _subtitleText(
        context,
        cryptocurrencyName(cryptocurrency),
        scale,
      ),
    );
  }

  Widget _subtitleText(BuildContext context, String text, double scale) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13 * scale,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _quoteTile(
    BuildContext context, {
    required CurrencyHistoryMenuBloc bloc,
    required String currencyCode,
    required Widget badge,
    required Widget subtitle,
    required Color accent,
    required double scale,
  }) {
    return BentoCard(
      padding: EdgeInsets.all(12 * scale),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectedCurrencyDetailsBlocProvider(
              bloc: SelectedCurrencyDetailsBloc(
                  currencyRepository: bloc.currencyRepository),
              child: SelectedCurrencyDetails(
                selectedCurrencyCode: currencyCode,
              ),
            ),
          ),
        );
      },
      child: Row(
        children: [
          // Bandeira e ícone ganham a mesma moldura colorida, para os dois
          // tipos de ativo ficarem alinhados e com o mesmo peso visual.
          Container(
            width: 46 * scale,
            height: 40 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: badge,
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currencyCode,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle,
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20 * scale,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}
