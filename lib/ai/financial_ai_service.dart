import 'dart:math';

import 'package:cotacao_direta/ai/insight_engine.dart';
import 'package:cotacao_direta/ai/local_financial_model.dart';
import 'package:cotacao_direta/ai/math/indicators.dart';
import 'package:cotacao_direta/ai/math/statistics.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';

/// Entry point of the local analysis: it takes the price series, runs the
/// indicators, trains and queries the model, and returns everything together
/// with the remarks in text form.
///
/// It all happens on the device and offline: the only thing that leaves the
/// phone is the quote request the app already made before.
class FinancialAiService {
  final LocalFinancialModel model;

  FinancialAiService({LocalFinancialModel? model})
      : model = model ?? LocalFinancialModel();

  /// Below this there is no series to analyse: not even the shortest
  /// indicators (7-day average, weekly change) would have enough points.
  static const int minimumPoints = 10;

  /// Trading days in a year, to annualise volatility. Crypto trades every day;
  /// currencies and stocks, only on trading days.
  static double _periodsPerYear(AssetKind kind) =>
      kind == AssetKind.cryptocurrency ? 365 : 252;

  /// Analyses [series] and projects [horizonInDays] days ahead.
  ///
  /// [languageCode] only affects the formatting of the numbers embedded in the
  /// remarks ("3,2%" or "3.2%").
  FinancialAnalysis analyze(
    AssetSeries series, {
    int horizonInDays = 15,
    String languageCode = "pt",
  }) {
    if (series.length < minimumPoints)
      throw ArgumentError("series with fewer than $minimumPoints points");

    final statistics = computeStatistics(series);
    final forecast = model.forecast(series, horizonInDays: horizonInDays);
    final insights = InsightEngine(languageCode: languageCode).generate(
      series: series,
      statistics: statistics,
      forecast: forecast,
    );

    return FinancialAnalysis(
      series: series,
      statistics: statistics,
      forecast: forecast,
      insights: insights,
    );
  }

  /// Statistical portrait of the series. It feeds the market summary on screen
  /// and the thresholds of the insights.
  MarketStatistics computeStatistics(AssetSeries series) {
    if (series.isEmpty)
      throw ArgumentError("computeStatistics of an empty series");

    final prices = series.prices;
    final returns = logReturns(prices);

    // The trend is fitted over the log of the price rather than the price
    // itself: in log space, constant percentage growth becomes a straight
    // line, which is what R² measures well.
    final logPrices = prices.map(log).toList(growable: false);
    final positions = List<double>.generate(
        logPrices.length, (index) => index.toDouble(),
        growable: false);
    final trend = linearFit(positions, logPrices);

    return MarketStatistics(
      lastPrice: series.lastPrice,
      weeklyChange: momentum(prices, 7),
      monthlyChange: momentum(prices, 30),
      annualizedVolatility: annualizedVolatility(returns,
          periodsPerYear: _periodsPerYear(series.kind)),
      relativeStrengthIndex: relativeStrengthIndex(prices),
      shortMovingAverage: simpleMovingAverage(prices, 7),
      longMovingAverage: simpleMovingAverage(prices, 30),
      maxDrawdown: maxDrawdown(prices),
      compoundAnnualGrowthRate: compoundAnnualGrowthRate(
        initialPrice: prices.first,
        finalPrice: prices.last,
        spanInDays: series.spanInDays,
      ),
      trendSlopePerDay: trend.slope,
      trendRSquared: trend.rSquared,
      sampleCount: series.length,
    );
  }
}
