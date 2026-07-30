import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:cotacao_direta/util/quote_format.dart';
import 'package:intl/intl.dart';

/// Turns the numbers of the analysis into short remarks.
///
/// The language layer of the feature lives here: the model produces statistics
/// and a projection, and this class decides what is worth saying and in what
/// tone. The final text does not come from here — it comes from the
/// translations file, which the screen fills in with
/// [FinancialInsight.arguments]. That keeps the engine in pure Dart, free of
/// Flutter, while both app languages are served by the same code.
class InsightEngine {
  /// Language the numbers are formatted in ("pt" or "en"): it changes the
  /// decimal comma and the thousands separator.
  final String languageCode;

  const InsightEngine({this.languageCode = "pt"});

  /// Above this the period's change stops being noise and becomes a trend.
  static const double _trendThreshold = 0.025;

  /// Range within which the projection counts as stable.
  static const double _projectionThreshold = 0.01;

  static const double _overboughtLevel = 70;
  static const double _oversoldLevel = 30;

  /// From here on the drop from the peak deserves a warning.
  static const double _drawdownThreshold = 0.15;

  /// Minimum edge over the random walk for the network to be worth mentioning.
  static const double _meaningfulSkill = 0.05;

  List<FinancialInsight> generate({
    required AssetSeries series,
    required MarketStatistics statistics,
    required AssetForecast forecast,
  }) {
    return [
      _projectionInsight(forecast),
      ..._trendInsights(statistics),
      ..._momentumInsights(statistics),
      ..._volatilityInsights(series.kind, statistics),
      ..._riskInsights(statistics),
      _confidenceInsight(forecast.diagnostics),
    ];
  }

  FinancialInsight _projectionInsight(AssetForecast forecast) {
    final change = forecast.projectedChange;
    final days = "${forecast.horizonInDays}";
    final price = _price(forecast.projectedPrice);
    if (change > _projectionThreshold) {
      return FinancialInsight(
          code: InsightCode.projectionUp,
          sentiment: InsightSentiment.positive,
          arguments: [_percent(change.abs()), days, price]);
    }
    if (change < -_projectionThreshold) {
      return FinancialInsight(
          code: InsightCode.projectionDown,
          sentiment: InsightSentiment.negative,
          arguments: [_percent(change.abs()), days, price]);
    }
    return FinancialInsight(
        code: InsightCode.projectionStable,
        sentiment: InsightSentiment.neutral,
        arguments: [days, price]);
  }

  List<FinancialInsight> _trendInsights(MarketStatistics statistics) {
    final change = statistics.referenceChange;
    if (change == null) return const [];
    // The reference change is the 30-day one when it exists; otherwise the
    // 7-day one.
    final days = statistics.monthlyChange != null ? "30" : "7";
    final arguments = [_percent(change.abs()), days];
    if (change > _trendThreshold) {
      return [
        FinancialInsight(
            code: InsightCode.trendUp,
            sentiment: InsightSentiment.positive,
            arguments: arguments)
      ];
    }
    if (change < -_trendThreshold) {
      return [
        FinancialInsight(
            code: InsightCode.trendDown,
            sentiment: InsightSentiment.negative,
            arguments: arguments)
      ];
    }
    return [
      FinancialInsight(
          code: InsightCode.trendSideways,
          sentiment: InsightSentiment.neutral,
          arguments: arguments)
    ];
  }

  List<FinancialInsight> _momentumInsights(MarketStatistics statistics) {
    final rsi = statistics.relativeStrengthIndex;
    if (rsi == null) return const [];
    final arguments = [_number(rsi, decimalDigits: 0)];
    if (rsi >= _overboughtLevel) {
      return [
        FinancialInsight(
            code: InsightCode.momentumOverbought,
            sentiment: InsightSentiment.caution,
            arguments: arguments)
      ];
    }
    if (rsi <= _oversoldLevel) {
      return [
        FinancialInsight(
            code: InsightCode.momentumOversold,
            sentiment: InsightSentiment.caution,
            arguments: arguments)
      ];
    }
    return [
      FinancialInsight(
          code: InsightCode.momentumNeutral,
          sentiment: InsightSentiment.neutral,
          arguments: arguments)
    ];
  }

  List<FinancialInsight> _volatilityInsights(
      AssetKind kind, MarketStatistics statistics) {
    final volatility = statistics.annualizedVolatility;
    if (volatility <= 0) return const [];
    final arguments = [_percent(volatility)];
    if (volatility >= _highVolatilityLevel(kind)) {
      return [
        FinancialInsight(
            code: InsightCode.volatilityHigh,
            sentiment: InsightSentiment.caution,
            arguments: arguments)
      ];
    }
    if (volatility <= _lowVolatilityLevel(kind)) {
      return [
        FinancialInsight(
            code: InsightCode.volatilityLow,
            sentiment: InsightSentiment.positive,
            arguments: arguments)
      ];
    }
    return const [];
  }

  /// Crypto swings an order of magnitude more than fiat currency: 40% a year
  /// is routine for bitcoin and would be alarming for the euro. Hence the
  /// thresholds depend on the kind of asset.
  double _highVolatilityLevel(AssetKind kind) => switch (kind) {
        AssetKind.currency => 0.15,
        AssetKind.stock => 0.35,
        AssetKind.cryptocurrency => 0.60,
      };

  double _lowVolatilityLevel(AssetKind kind) => switch (kind) {
        AssetKind.currency => 0.05,
        AssetKind.stock => 0.12,
        AssetKind.cryptocurrency => 0.25,
      };

  List<FinancialInsight> _riskInsights(MarketStatistics statistics) {
    if (statistics.maxDrawdown < _drawdownThreshold) return const [];
    return [
      FinancialInsight(
          code: InsightCode.drawdown,
          sentiment: InsightSentiment.caution,
          arguments: [_percent(statistics.maxDrawdown)])
    ];
  }

  FinancialInsight _confidenceInsight(ModelDiagnostics diagnostics) {
    if (!diagnostics.trained) {
      return FinancialInsight(
          code: InsightCode.dataLimited,
          sentiment: InsightSentiment.caution,
          arguments: ["${diagnostics.trainingSamples}"]);
    }
    if (diagnostics.skill >= _meaningfulSkill) {
      return FinancialInsight(
          code: InsightCode.confidenceGood,
          sentiment: InsightSentiment.positive,
          arguments: [_percent(diagnostics.skill)]);
    }
    return const FinancialInsight(
        code: InsightCode.confidenceLow, sentiment: InsightSentiment.caution);
  }

  String _percent(double fraction) =>
      NumberFormat.decimalPercentPattern(locale: languageCode, decimalDigits: 1)
          .format(fraction);

  String _number(double value, {int decimalDigits = 2}) =>
      NumberFormat.decimalPatternDigits(
              locale: languageCode, decimalDigits: decimalDigits)
          .format(value);

  /// Quote with enough decimal places for the price not to turn into "0.00":
  /// crypto quoted in reais runs in the hundreds of thousands, and the same
  /// screen shows currency pairs in the units.
  String _price(double value) => _number(value,
      decimalDigits:
          quoteDecimalDigits(value, minimumDigits: 2, significantDigits: 4));
}
