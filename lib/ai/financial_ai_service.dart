import 'dart:math';

import 'package:cotacao_direta/ai/insight_engine.dart';
import 'package:cotacao_direta/ai/local_financial_model.dart';
import 'package:cotacao_direta/ai/math/indicators.dart';
import 'package:cotacao_direta/ai/math/statistics.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';

/// Porta de entrada da análise local: recebe a série de preços, roda os
/// indicadores, treina e consulta o modelo, e devolve tudo junto com as
/// observações em texto.
///
/// Tudo acontece no aparelho e sem rede: a única coisa que sai do celular é a
/// consulta de cotação que o app já fazia antes.
class FinancialAiService {
  final LocalFinancialModel model;

  FinancialAiService({LocalFinancialModel? model})
      : model = model ?? LocalFinancialModel();

  /// Abaixo disto não há série a analisar: nem os indicadores mais curtos
  /// (média de 7 dias, variação semanal) teriam pontos suficientes.
  static const int minimumPoints = 10;

  /// Dias de negociação num ano, para anualizar a volatilidade. Cripto negocia
  /// todo dia; moeda e ação, só em pregão.
  static double _periodsPerYear(AssetKind kind) =>
      kind == AssetKind.cryptocurrency ? 365 : 252;

  /// Analisa [series] e projeta [horizonInDays] dias à frente.
  ///
  /// [languageCode] só afeta a formatação dos números embutidos nas
  /// observações ("3,2%" ou "3.2%").
  FinancialAnalysis analyze(
    AssetSeries series, {
    int horizonInDays = 15,
    String languageCode = "pt",
  }) {
    if (series.length < minimumPoints)
      throw ArgumentError("série com menos de $minimumPoints pontos");

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

  /// Retrato estatístico da série. É o que alimenta o resumo de mercado da tela
  /// e os limiares dos insights.
  MarketStatistics computeStatistics(AssetSeries series) {
    if (series.isEmpty)
      throw ArgumentError("computeStatistics de uma série vazia");

    final prices = series.prices;
    final returns = logReturns(prices);

    // Tendência ajustada sobre o log do preço, e não sobre o preço: em log, um
    // crescimento percentual constante vira uma reta, que é o que o R² mede
    // bem.
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
