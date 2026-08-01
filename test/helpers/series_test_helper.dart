import 'dart:math';

import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/currency.dart';

/// Séries sintéticas para os testes da análise local.
///
/// São determinísticas de propósito (o ruído sai de um [Random] semeado): o
/// modelo também é, e um teste que mudasse de série a cada execução não
/// conseguiria afirmar nada sobre a projeção.

/// Série de preços com tendência geométrica e ruído.
///
/// [dailyDrift] é o log-retorno médio por dia (0,002 ≈ +0,2% ao dia) e [noise],
/// o desvio padrão do ruído diário.
List<double> syntheticPrices({
  int length = 120,
  double initialPrice = 5.0,
  double dailyDrift = 0.0,
  double noise = 0.004,
  int seed = 42,
}) {
  final random = Random(seed);
  final prices = <double>[initialPrice];
  for (var day = 1; day < length; day++) {
    // Box-Muller a partir de dois uniformes, para o ruído ser normal.
    final first = random.nextDouble().clamp(1e-9, 1.0);
    final second = random.nextDouble();
    final gaussian = sqrt(-2 * log(first)) * cos(2 * pi * second);
    prices.add(prices.last * exp(dailyDrift + noise * gaussian));
  }
  return prices;
}

/// Monta uma [AssetSeries] a partir de preços, um por dia corrido.
AssetSeries seriesFromPrices(
  List<double> prices, {
  String code = "USD",
  AssetKind kind = AssetKind.currency,
  String quoteCurrency = "BRL",
  DateTime? startDate,
}) {
  final start = startDate ?? DateTime(2024, 1, 1);
  return AssetSeries(
    code: code,
    kind: kind,
    quoteCurrency: quoteCurrency,
    points: List.generate(
      prices.length,
      (index) =>
          AssetPoint(date: start.add(Duration(days: index)), price: prices[index]),
    ),
  );
}

/// Histórico no formato que o `CurrencyRepository` devolve: o valor guardado é
/// o inverso do preço (ver `AssetSeries.fromQuoteHistory`).
List<Currency> quoteHistoryFromPrices(
  List<double> prices, {
  String code = "USD",
  DateTime? startDate,
}) {
  final start = startDate ?? DateTime(2024, 1, 1);
  return List.generate(prices.length, (index) {
    final date = start.add(Duration(days: index));
    return Currency(
      id: code,
      value: 1 / prices[index],
      historicalDate: date.toIso8601String(),
      timestamp: date.toIso8601String(),
    );
  });
}
