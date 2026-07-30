import 'package:cotacao_direta/blocs/currency_history_menu_bloc.dart';
import 'package:cotacao_direta/enums/cryptocurrency_enum.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/currency_history_menu_bloc_provider.dart';
import 'package:cotacao_direta/providers/selected_currency_details_bloc_provider.dart';
import 'package:cotacao_direta/util/cryptocurrency_info.dart';
import 'package:cotacao_direta/util/currency_flag.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/pages/selected_currency_details.dart';
import 'package:cotacao_direta/view/widgets/animated_list_entry.dart';
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
              localizations.currencyHistoryCryptocurrenciesSectionLabel!),
          ...Cryptocurrencies.values
              .map((cryptocurrency) => _CryptocurrencyEntry(cryptocurrency)),
        ];

        return ListView.separated(
          separatorBuilder: (BuildContext context, index) {
            // O título de seção já se separa do que vem antes pelo próprio
            // espaçamento; um divisor aí faria a seção parecer parte da lista
            // anterior.
            if (_entries[index + 1] is _SectionEntry)
              return const SizedBox.shrink();
            return const Divider(height: 1, thickness: 1);
          },
          itemBuilder: (BuildContext context, index) {
            final entry = _entries[index];
            return AnimatedListEntry(
              index: index,
              child: switch (entry) {
                _SectionEntry() => _sectionTitle(context, entry.label, _scale),
                _CurrencyEntry() =>
                  _currencyTile(context, bloc, entry.currency, _scale),
                _CryptocurrencyEntry() =>
                  _cryptocurrencyTile(context, entry.cryptocurrency, _scale),
              },
            );
          },
          itemCount: _entries.length,
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String label, double scale) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(16 * scale, 20 * scale, 16 * scale, 8 * scale),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14 * scale,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _currencyTile(BuildContext context, CurrencyHistoryMenuBloc bloc,
      Currencies currency, double scale) {
    final currencyCode = _codeOf(currency);
    return _quoteTile(
      context,
      currencyCode: currencyCode,
      scale: scale,
      badge: Flag.fromCode(
        flagCodeForCurrency(currency),
        height: 24 * scale,
        width: 32 * scale,
      ),
      subtitle: StreamBuilder<String?>(
        initialData: bloc.cachedCountryName(currencyCode),
        stream: bloc.getCountryNameController(currencyCode),
        builder: (context, snapshot) {
          bloc.getCountryNameByCurrencyCode(currencyCode);
          return Text(
            snapshot.data ?? "",
            style: TextStyle(fontSize: 14 * scale),
          );
        },
      ),
    );
  }

  Widget _cryptocurrencyTile(
      BuildContext context, Cryptocurrencies cryptocurrency, double scale) {
    return _quoteTile(
      context,
      currencyCode: _codeOf(cryptocurrency),
      scale: scale,
      // Mesmas dimensões da bandeira das moedas fiduciárias, para os códigos
      // ficarem alinhados entre as duas seções.
      badge: SizedBox(
        height: 24 * scale,
        width: 32 * scale,
        child: Icon(
          iconForCryptocurrency(cryptocurrency),
          size: 22 * scale,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      subtitle: Text(
        cryptocurrencyName(cryptocurrency),
        style: TextStyle(fontSize: 14 * scale),
      ),
    );
  }

  Widget _quoteTile(
    BuildContext context, {
    required String currencyCode,
    required Widget badge,
    required Widget subtitle,
    required double scale,
  }) {
    return GestureDetector(
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              currencyCode,
              style: TextStyle(fontSize: 16 * scale),
            ),
            badge,
          ],
        ),
        subtitle: subtitle,
        trailing: Icon(
          Icons.chevron_right,
          size: 20 * scale,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectedCurrencyDetailsBlocProvider(
              child: SelectedCurrencyDetails(
                selectedCurrencyCode: currencyCode,
              ),
            ),
          ),
        );
      },
    );
  }
}
