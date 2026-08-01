import 'package:cotacao_direta/blocs/ai_insights_bloc.dart';
import 'package:cotacao_direta/enums/cryptocurrency_enum.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:cotacao_direta/providers/ai_insights_bloc_provider.dart';
import 'package:cotacao_direta/util/cryptocurrency_info.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/quote_format.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:cotacao_direta/view/widgets/ai_insight_text.dart';
import 'package:cotacao_direta/view/widgets/forecast_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

/// An asset offered in the screen's list.
class _AssetOption {
  final String code;
  final AssetKind kind;
  final String name;

  const _AssetOption({required this.code, required this.kind, required this.name});

  // DropdownButtonFormField compares the selected value against the list items
  // by equality, and the list is rebuilt on every build.
  @override
  bool operator ==(Object other) =>
      other is _AssetOption && other.code == code && other.kind == kind;

  @override
  int get hashCode => Object.hash(code, kind);
}

/// Screen for the insights produced by the AI model that runs on the device
/// itself.
///
/// The flow is: pick the asset and the horizon, tap analyse, and the screen
/// shows the market summary, the projection with its confidence band, the
/// chart and the remarks in text form. None of these computations leave the
/// phone.
class AiInsightsPage extends StatefulWidget {
  AiInsightsPage({Key? key}) : super(key: key);

  @override
  State<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage> {
  static String _codeOf(Object enumValue) =>
      EnumValueAsString().getEnumValue(enumValue.toString());

  List<_AssetOption> _assetOptions(String counterCurrency) => [
        // The counter currency has no series of its own: quoted against
        // itself it would always be 1, and the repository skips the query.
        ...Currencies.values
            .where((currency) => _codeOf(currency) != counterCurrency)
            .map((currency) => _AssetOption(
                code: _codeOf(currency),
                kind: AssetKind.currency,
                name: _codeOf(currency))),
        ...Cryptocurrencies.values.map((cryptocurrency) => _AssetOption(
            code: _codeOf(cryptocurrency),
            kind: AssetKind.cryptocurrency,
            name: cryptocurrencyName(cryptocurrency))),
      ];

  @override
  Widget build(BuildContext context) {
    final bloc = AiInsightsBlocProvider.of(context);
    final localizations = MyAppLocalizations.of(context)!;
    final scale = Responsive.scaleFactor(context);
    final contentWidth = Responsive.contentMaxWidth(context);

    return FutureBuilder<String>(
      future: bloc.counterCurrencyCode,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final options = _assetOptions(snapshot.data!);
        final selected = options.firstWhere(
          (option) =>
              option.code == bloc.selectedAssetCode &&
              option.kind == bloc.selectedAssetKind,
          orElse: () => options.first,
        );
        // The counter currency may have changed in the settings, leaving the
        // selected asset out of the list.
        if (selected.code != bloc.selectedAssetCode)
          bloc.selectAsset(selected.code, selected.kind);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: ListView(
              padding: EdgeInsets.all(16 * scale),
              children: [
                _header(context, localizations, scale),
                SizedBox(height: 16 * scale),
                _assetField(context, bloc, localizations, options, selected),
                SizedBox(height: 16 * scale),
                _horizonField(context, bloc, localizations, scale),
                SizedBox(height: 16 * scale),
                _amountField(bloc, localizations),
                SizedBox(height: 16 * scale),
                _analyzeButton(bloc, localizations),
                SizedBox(height: 8 * scale),
                StreamBuilder<AiInsightsState>(
                  stream: bloc.stateStream,
                  initialData: bloc.currentState,
                  builder: (context, stateSnapshot) => _result(
                    context,
                    bloc,
                    localizations,
                    stateSnapshot.data ?? const AiInsightsState.idle(),
                    scale,
                  ),
                ),
                SizedBox(height: 24 * scale),
                Text(
                  localizations.aiInsightsDisclaimerLabel!,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, MyAppLocalizations localizations,
      double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome,
                size: 20 * scale, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Text(
                localizations.aiInsightsSectionLabel!,
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * scale),
        Text(
          localizations.aiInsightsDescription!,
          style: TextStyle(
            fontSize: 13 * scale,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _assetField(
    BuildContext context,
    AiInsightsBloc bloc,
    MyAppLocalizations localizations,
    List<_AssetOption> options,
    _AssetOption selected,
  ) {
    return DropdownButtonFormField<_AssetOption>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: localizations.aiInsightsAssetLabel,
      ),
      items: options
          .map((option) => DropdownMenuItem<_AssetOption>(
                value: option,
                child: Text(option.code == option.name
                    ? option.code
                    : "${option.code} — ${option.name}"),
              ))
          .toList(),
      onChanged: (option) {
        if (option == null) return;
        setState(() => bloc.selectAsset(option.code, option.kind));
      },
    );
  }

  Widget _horizonField(BuildContext context, AiInsightsBloc bloc,
      MyAppLocalizations localizations, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.aiInsightsHorizonLabel!,
          style: TextStyle(fontSize: 13 * scale),
        ),
        SizedBox(height: 8 * scale),
        SegmentedButton<int>(
          segments: AiInsightsBloc.horizonOptions
              .map((days) => ButtonSegment<int>(
                    value: days,
                    label: Text(sprintf(
                        localizations.aiInsightsHorizonOptionLabel!, ["$days"])),
                  ))
              .toList(),
          selected: {bloc.horizonInDays},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              setState(() => bloc.selectHorizon(selection.first)),
        ),
      ],
    );
  }

  Widget _amountField(AiInsightsBloc bloc, MyAppLocalizations localizations) {
    return TextField(
      controller: bloc.amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: localizations.aiInsightsAmountLabel,
        prefixIcon: const Icon(Icons.savings_outlined),
      ),
      // The simulated amount is a rule of three over the projection already
      // computed: it is enough to redraw, with no retraining.
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _analyzeButton(AiInsightsBloc bloc, MyAppLocalizations localizations) {
    return StreamBuilder<AiInsightsState>(
      stream: bloc.stateStream,
      initialData: bloc.currentState,
      builder: (context, snapshot) {
        final loading = snapshot.data?.loading == true;
        return FilledButton.icon(
          onPressed: loading
              ? null
              : () => bloc.analyze(
                  languageCode: localizations.locale.languageCode),
          icon: const Icon(Icons.psychology_alt),
          label: Text(localizations.aiInsightsAnalyzeBtnLabel!),
        );
      },
    );
  }

  Widget _result(
    BuildContext context,
    AiInsightsBloc bloc,
    MyAppLocalizations localizations,
    AiInsightsState state,
    double scale,
  ) {
    if (state.loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32 * scale),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 12 * scale),
            Text(localizations.aiInsightsRunningLabel!),
          ],
        ),
      );
    }

    final error = state.error;
    if (error != null) {
      return _message(
        context,
        Icons.error_outline,
        switch (error) {
          AiInsightsError.noData => localizations.aiInsightsNoDataError!,
          AiInsightsError.insufficientData =>
            localizations.aiInsightsInsufficientDataError!,
          AiInsightsError.failure => localizations.aiInsightsFailureError!,
        },
        scale,
      );
    }

    final analysis = state.analysis;
    if (analysis == null) {
      return _message(context, Icons.auto_graph,
          localizations.aiInsightsEmptyLabel!, scale);
    }

    final formatter = _NumberFormatter(localizations.locale.languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 16 * scale),
        _sectionTitle(context, localizations.aiInsightsSummarySectionLabel!,
            scale),
        _summary(context, localizations, analysis, formatter, scale),
        SizedBox(height: 16 * scale),
        _sectionTitle(context, localizations.aiInsightsProjectionSectionLabel!,
            scale),
        _projection(context, bloc, localizations, analysis, formatter, scale),
        SizedBox(height: 16 * scale),
        SizedBox(
          height: 220 * scale,
          child: Padding(
            padding: EdgeInsets.only(right: 8 * scale, top: 8 * scale),
            child: ForecastChart(
              // A quarter of history gives the projection enough context
              // without squeezing the two weeks that matter.
              history: analysis.series.tail(60),
              forecast: analysis.forecast.points,
            ),
          ),
        ),
        SizedBox(height: 8 * scale),
        _chartLegend(context, localizations, scale),
        SizedBox(height: 16 * scale),
        _sectionTitle(
            context, localizations.aiInsightsInsightsSectionLabel!, scale),
        ...analysis.insights.map(
            (insight) => _insightTile(context, localizations, insight, scale)),
        SizedBox(height: 16 * scale),
        _sectionTitle(context, localizations.aiInsightsModelSectionLabel!, scale),
        _diagnostics(context, localizations, analysis.forecast.diagnostics,
            formatter, scale),
      ],
    );
  }

  Widget _message(
      BuildContext context, IconData icon, String text, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32 * scale),
      child: Column(
        children: [
          Icon(icon,
              size: 40 * scale, color: Theme.of(context).colorScheme.outline),
          SizedBox(height: 12 * scale),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String label, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
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

  Widget _summary(
    BuildContext context,
    MyAppLocalizations localizations,
    FinancialAnalysis analysis,
    _NumberFormatter formatter,
    double scale,
  ) {
    final statistics = analysis.statistics;
    final quoteCurrency = analysis.series.quoteCurrency;
    return _metricCard(context, scale, [
      _metric(context, localizations.aiInsightsLastPriceLabel!,
          "${formatter.price(statistics.lastPrice)} $quoteCurrency", scale),
      if (statistics.weeklyChange != null)
        _metric(context, localizations.aiInsightsWeeklyChangeLabel!,
            formatter.signedPercent(statistics.weeklyChange!), scale),
      if (statistics.monthlyChange != null)
        _metric(context, localizations.aiInsightsMonthlyChangeLabel!,
            formatter.signedPercent(statistics.monthlyChange!), scale),
      _metric(context, localizations.aiInsightsVolatilityLabel!,
          formatter.percent(statistics.annualizedVolatility), scale),
      if (statistics.relativeStrengthIndex != null)
        _metric(context, localizations.aiInsightsRsiLabel!,
            formatter.decimal(statistics.relativeStrengthIndex!, digits: 0),
            scale),
      _metric(context, localizations.aiInsightsDrawdownLabel!,
          formatter.percent(statistics.maxDrawdown), scale),
      _metric(context, localizations.aiInsightsTrendLabel!,
          formatter.signedPercent(statistics.compoundAnnualGrowthRate), scale),
      _metric(context, localizations.aiInsightsTrendFitLabel!,
          formatter.decimal(statistics.trendRSquared, digits: 2), scale),
    ]);
  }

  Widget _projection(
    BuildContext context,
    AiInsightsBloc bloc,
    MyAppLocalizations localizations,
    FinancialAnalysis analysis,
    _NumberFormatter formatter,
    double scale,
  ) {
    final forecast = analysis.forecast;
    final quoteCurrency = analysis.series.quoteCurrency;
    final amount = bloc.simulationAmount;
    return _metricCard(context, scale, [
      _metric(
          context,
          sprintf(localizations.aiInsightsProjectedPriceLabel!,
              ["${forecast.horizonInDays}"]),
          "${formatter.price(forecast.projectedPrice)} $quoteCurrency",
          scale),
      _metric(context, localizations.aiInsightsProjectedChangeLabel!,
          formatter.signedPercent(forecast.projectedChange), scale),
      _metric(
          context,
          sprintf(localizations.aiInsightsConfidenceBandLabel!,
              [formatter.percent(forecast.confidenceLevel, digits: 0)]),
          "${formatter.price(forecast.projectedLowerBound)} – "
              "${formatter.price(forecast.projectedUpperBound)}",
          scale),
      if (amount != null)
        _metric(
          context,
          localizations.aiInsightsAmountProjectionLabel!,
          "${formatter.money(forecast.projectAmount(amount).expected)} "
              "$quoteCurrency",
          scale,
          hint: sprintf(localizations.aiInsightsAmountProjectionHint!,
              ["${formatter.money(amount)} $quoteCurrency"]),
        ),
    ]);
  }

  Widget _metricCard(BuildContext context, double scale, List<Widget> metrics) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(12 * scale),
        child: Wrap(
          spacing: 24 * scale,
          runSpacing: 12 * scale,
          children: metrics,
        ),
      ),
    );
  }

  Widget _metric(
      BuildContext context, String label, String value, double scale,
      {String? hint}) {
    return SizedBox(
      width: 150 * scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11 * scale,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          SizedBox(height: 2 * scale),
          Text(
            value,
            style: TextStyle(
                fontSize: 15 * scale, fontWeight: FontWeight.w600),
          ),
          if (hint != null)
            Text(
              hint,
              style: TextStyle(
                fontSize: 10 * scale,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chartLegend(
      BuildContext context, MyAppLocalizations localizations, double scale) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget entry(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16 * scale, height: 3, color: color),
            SizedBox(width: 6 * scale),
            Text(label, style: TextStyle(fontSize: 11 * scale)),
          ],
        );
    return Wrap(
      spacing: 16 * scale,
      alignment: WrapAlignment.center,
      children: [
        entry(colorScheme.primary, localizations.aiInsightsChartHistoryLabel!),
        entry(colorScheme.tertiary,
            localizations.aiInsightsChartProjectionLabel!),
      ],
    );
  }

  Widget _insightTile(BuildContext context, MyAppLocalizations localizations,
      FinancialInsight insight, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            insightIcon(insight.sentiment),
            size: 18 * scale,
            color: insightColor(context, insight.sentiment),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Text(
              insightText(localizations, insight),
              style: TextStyle(fontSize: 13 * scale),
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagnostics(
    BuildContext context,
    MyAppLocalizations localizations,
    ModelDiagnostics diagnostics,
    _NumberFormatter formatter,
    double scale,
  ) {
    if (!diagnostics.trained) {
      return Text(
        localizations.aiInsightsModelUntrainedLabel!,
        style: TextStyle(
          fontSize: 12 * scale,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }
    return _metricCard(context, scale, [
      _metric(context, localizations.aiInsightsModelSamplesLabel!,
          "${diagnostics.trainingSamples}", scale),
      _metric(context, localizations.aiInsightsModelSkillLabel!,
          formatter.percent(diagnostics.skill), scale),
      _metric(context, localizations.aiInsightsModelEpochsLabel!,
          "${diagnostics.epochs}", scale),
    ]);
  }
}

/// Formatting of the screen's numbers in the current language.
class _NumberFormatter {
  final String languageCode;

  const _NumberFormatter(this.languageCode);

  String decimal(double value, {int digits = 2}) =>
      NumberFormat.decimalPatternDigits(
              locale: languageCode, decimalDigits: digits)
          .format(value);

  String percent(double fraction, {int digits = 1}) =>
      NumberFormat.decimalPercentPattern(
              locale: languageCode, decimalDigits: digits)
          .format(fraction);

  /// Percentage with an explicit sign: on a change, "+1.2%" and "-1.2%" are
  /// told apart at a glance, and the "+" does not show up by mistake on
  /// zero.
  String signedPercent(double fraction, {int digits = 1}) {
    final formatted = percent(fraction, digits: digits);
    return fraction > 0 ? "+$formatted" : formatted;
  }

  /// Quote, with decimal places following the order of magnitude (crypto in
  /// reais runs in the thousands; some pairs, in the hundredths).
  String price(double value) => decimal(value,
      digits: quoteDecimalDigits(value, minimumDigits: 2, significantDigits: 4));

  /// Simulated monetary amount: two places are enough, it is money.
  String money(double value) => decimal(value, digits: 2);
}
