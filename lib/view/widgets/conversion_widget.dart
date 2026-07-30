import 'dart:async';

import 'package:cotacao_direta/blocs/conversion_page_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/providers/conversion_page_bloc_provider.dart';
import 'package:cotacao_direta/util/currency_name.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/quote_format.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/currency_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// A tela de conversão: uma quantidade na moeda de origem em cima, o valor
/// convertido embaixo e a cotação usada logo abaixo dos dois.
///
/// A conversão acontece sozinha a cada mudança (quantidade, moeda ou troca de
/// lados), então não há botão de converter: o usuário digita e o resultado
/// acompanha.
class ConversionWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ConversionWidgetState();
  }
}

class ConversionWidgetState extends State<ConversionWidget> {
  /// Espera entre a última tecla e a conversão. Converter a cada tecla faria
  /// uma busca de cotação por caractere digitado.
  static const _typingDebounce = Duration(milliseconds: 350);

  // O bloc pertence ao ConversionPageBlocProvider, que o descarta junto com o
  // próprio State: este widget apenas o consome.
  late ConversionPageBloc bloc;

  final _amountController = TextEditingController();

  Timer? _typingTimer;
  ConversionPageBloc? _initializedBloc;
  var _amountIsInvalid = false;

  /// Meia volta a cada toque no botão de inverter, para o ícone acompanhar a
  /// troca de lugar das moedas.
  var _swapTurns = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bloc = ConversionPageBlocProvider.of(context);
    if (identical(_initializedBloc, bloc)) return;
    _initializedBloc = bloc;
    _amountController.text = _formatAmount(bloc.amount);
    // A tela já abre com uma conversão pronta em vez de um campo de resultado
    // vazio esperando a primeira interação.
    WidgetsBinding.instance.addPostFrameCallback((_) => bloc.updateResult());
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  String _localeName() => Localizations.localeOf(context).toString();

  /// Formata com casas decimais suficientes para o valor não virar "0,00":
  /// cotações de moedas fracas contra moedas fortes são números pequenos.
  String _formatNumber(double value, {int minimumDigits = 2}) {
    return NumberFormat.decimalPatternDigits(
      locale: _localeName(),
      decimalDigits: quoteDecimalDigits(value, minimumDigits: minimumDigits),
    ).format(value);
  }

  /// A quantidade digitada volta ao campo sem casas decimais quando é inteira:
  /// abrir a tela com "1" é mais convidativo do que com "1,00".
  String _formatAmount(double value) {
    if (value == value.roundToDouble() && value.abs() < 1000000000) {
      return NumberFormat.decimalPatternDigits(
              locale: _localeName(), decimalDigits: 0)
          .format(value);
    }
    return _formatNumber(value);
  }

  void _onAmountChanged(String value) {
    _typingTimer?.cancel();
    _typingTimer = Timer(_typingDebounce, () => _applyAmount(value));
  }

  void _applyAmount(String value) {
    if (!mounted) return;
    var text = value.trim();
    // Campo vazio é uma quantidade ainda por informar, não um erro: o
    // resultado vai a zero e a tela segue limpa.
    if (text.isEmpty) {
      setState(() => _amountIsInvalid = false);
      bloc.updateAmount(0);
      return;
    }
    // A vírgula é o separador decimal em português e o ponto em inglês; os
    // dois são aceitos, venham do teclado que vierem.
    var amount = double.tryParse(text.replaceAll(",", "."));
    setState(() => _amountIsInvalid = amount == null);
    if (amount != null) bloc.updateAmount(amount);
  }

  void _clearAmount() {
    _typingTimer?.cancel();
    _amountController.clear();
    setState(() => _amountIsInvalid = false);
    bloc.updateAmount(0);
  }

  Future<void> _pickCurrency({required bool forOrigin}) async {
    var selected = await showCurrencyPicker(
      context,
      selectedCurrency: forOrigin ? bloc.fromCurrency : bloc.toCurrency,
    );
    if (selected == null) return;
    if (forOrigin) {
      bloc.updateFromCurrency(selected);
    } else {
      bloc.updateToCurrency(selected);
    }
  }

  void _switchCurrencies() {
    setState(() => _swapTurns += 0.5);
    bloc.switchCurrencies();
  }

  Future<void> _copyResult(String value, MyAppLocalizations localizations) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(localizations.conversionResultCopiedLabel!),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MyAppLocalizations.of(context)!;
    final scale = Responsive.scaleFactor(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16 * scale, 16 * scale, 16 * scale, 32 * scale),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _originCard(localizations, scale),
                _swapRow(localizations, scale),
                _destinationCard(localizations, scale),
                SizedBox(height: 16 * scale),
                _rateCard(localizations, scale),
                SizedBox(height: 24 * scale),
                _explanation(localizations, scale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _originCard(MyAppLocalizations localizations, double scale) {
    return _CurrencyCard(
      label: localizations.conversionFromLabel!,
      scale: scale,
      selector: StreamBuilder<Currencies>(
        initialData: bloc.fromCurrency,
        stream: bloc.currencyFromStream,
        builder: (context, snapshot) => _CurrencySelectorButton(
          currency: snapshot.data!,
          scale: scale,
          onTap: () => _pickCurrency(forOrigin: true),
        ),
      ),
      value: TextField(
        controller: _amountController,
        textAlign: TextAlign.end,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        // Só números e separador decimal: qualquer outra tecla viraria erro de
        // valor inválido logo depois.
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        style: TextStyle(
          fontSize: 26 * scale,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: "0",
          labelText: localizations.conversionMultiplierHint,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          errorText:
              _amountIsInvalid ? localizations.conversionInvalidAmountError : null,
          errorMaxLines: 2,
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _amountController,
            builder: (context, value, child) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.backspace_outlined, size: 18 * scale),
                    tooltip: localizations.conversionClearAmountTooltip,
                    onPressed: _clearAmount,
                  ),
          ),
          suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
        ),
        onChanged: _onAmountChanged,
      ),
    );
  }

  Widget _swapRow(MyAppLocalizations localizations, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4 * scale),
      child: Row(
        children: <Widget>[
          const Expanded(child: Divider(endIndent: 12)),
          Tooltip(
            message: localizations.conversionSwapTooltip!,
            child: IconButton.filledTonal(
              onPressed: _switchCurrencies,
              icon: AnimatedRotation(
                turns: _swapTurns,
                duration: const Duration(milliseconds: 300),
                child: Icon(Icons.swap_vert, size: 24 * scale),
              ),
            ),
          ),
          const Expanded(child: Divider(indent: 12)),
        ],
      ),
    );
  }

  Widget _destinationCard(MyAppLocalizations localizations, double scale) {
    return _CurrencyCard(
      label: localizations.conversionToLabel!,
      scale: scale,
      selector: StreamBuilder<Currencies>(
        initialData: bloc.toCurrency,
        stream: bloc.currencyToStream,
        builder: (context, snapshot) => _CurrencySelectorButton(
          currency: snapshot.data!,
          scale: scale,
          onTap: () => _pickCurrency(forOrigin: false),
        ),
      ),
      value: StreamBuilder<ConversionResult>(
        initialData: bloc.result,
        stream: bloc.conversionResultStream,
        builder: (context, snapshot) =>
            _convertedAmount(snapshot.data!, localizations, scale),
      ),
    );
  }

  Widget _convertedAmount(
      ConversionResult result, MyAppLocalizations localizations, double scale) {
    final colorScheme = Theme.of(context).colorScheme;
    var converted = result.convertedAmount;
    var text =
        converted == null ? localizations.noDataLabel! : _formatNumber(converted);

    return Semantics(
      label: "$text ${currencyCode(result.to)}",
      child: AnimatedOpacity(
        // Enquanto a cotação nova não chega, o valor anterior fica esmaecido:
        // continua legível, mas avisa que ainda vai mudar.
        opacity: result.isLoading ? 0.4 : 1,
        duration: const Duration(milliseconds: 200),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontSize: 26 * scale,
              fontWeight: FontWeight.w600,
              color: converted == null
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _rateCard(MyAppLocalizations localizations, double scale) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<ConversionResult>(
      initialData: bloc.result,
      stream: bloc.conversionResultStream,
      builder: (context, snapshot) {
        var result = snapshot.data!;
        var unitRate = result.unitRate;
        var inverseUnitRate = result.inverseUnitRate;
        var fromCode = currencyCode(result.from);
        var toCode = currencyCode(result.to);

        return Card(
          margin: EdgeInsets.zero,
          color: colorScheme.surfaceContainerHighest,
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(16 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (result.isLoading && unitRate == null)
                  LinearProgressIndicator(minHeight: 2 * scale)
                else if (unitRate == null)
                  Row(
                    children: <Widget>[
                      Icon(Icons.cloud_off,
                          size: 18 * scale, color: colorScheme.onSurfaceVariant),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: Text(
                          localizations.conversionRateUnavailableLabel!,
                          style: TextStyle(
                            fontSize: 14 * scale,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.show_chart,
                          size: 18 * scale, color: colorScheme.primary),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: Text(
                          "1 $fromCode = ${_formatNumber(unitRate, minimumDigits: 4)} $toCode",
                          style: TextStyle(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (result.hasValue)
                        IconButton(
                          icon: Icon(Icons.copy_all_outlined, size: 20 * scale),
                          tooltip: localizations.conversionCopyResultTooltip,
                          onPressed: () => _copyResult(
                              _formatNumber(result.convertedAmount!),
                              localizations),
                        ),
                    ],
                  ),
                  if (inverseUnitRate != null)
                    Padding(
                      padding: EdgeInsets.only(left: 26 * scale),
                      child: Text(
                        "1 $toCode = ${_formatNumber(inverseUnitRate, minimumDigits: 4)} $fromCode",
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _explanation(MyAppLocalizations localizations, double scale) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.info_outline,
            size: 16 * scale, color: colorScheme.onSurfaceVariant),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Text(
            localizations.conversionPageExplanationText!,
            style: TextStyle(
              fontSize: 12 * scale,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Um lado da conversão: o rótulo ("De"/"Para"), a moeda escolhida e o valor
/// correspondente, com a mesma moldura dos dois lados para deixar claro que um
/// é o espelho do outro.
class _CurrencyCard extends StatelessWidget {
  final String label;
  final Widget selector;
  final Widget value;
  final double scale;

  const _CurrencyCard({
    required this.label,
    required this.selector,
    required this.value,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16 * scale),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 * scale, 12 * scale, 16 * scale, 12 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4 * scale),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // A moeda ocupa um pouco mais que o valor para caber o nome
                // por extenso sem cortar os números do outro lado.
                Expanded(flex: 5, child: selector),
                SizedBox(width: 12 * scale),
                Expanded(flex: 4, child: value),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeira, código e nome da moeda, que abre o seletor ao ser tocado.
class _CurrencySelectorButton extends StatelessWidget {
  final Currencies currency;
  final double scale;
  final VoidCallback onTap;

  const _CurrencySelectorButton({
    required this.currency,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12 * scale),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 4 * scale),
        child: Row(
          children: <Widget>[
            CurrencyFlagBadge(currency: currency, scale: scale),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    currencyCode(currency),
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    currencyName(currency, locale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11 * scale,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down,
                size: 22 * scale, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
