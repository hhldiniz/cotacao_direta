import 'package:cotacao_direta/model/currency.dart';

/// Nature of the analysed asset. The local model treats all three the same
/// way: what changes is the label shown on screen and the volatility
/// thresholds used by the insights, since crypto swings an order of magnitude
/// more than fiat currency.
enum AssetKind { currency, cryptocurrency, stock }

/// A single point of the series: the asset price on that day, expressed in the
/// counter currency.
class AssetPoint {
  final DateTime date;
  final double price;

  const AssetPoint({required this.date, required this.price});

  @override
  String toString() => "AssetPoint(${date.toIso8601String()}, $price)";
}

/// Price time series ready for the local model.
///
/// The app stores in [Currency.value] the inverse of the quote — how many
/// units of the currency one unit of the counter currency is worth (see
/// `CurrencyRepository`). Whoever looks at the chart thinks the other way
/// around ("how much does a dollar cost"), and that is the number the analysis
/// needs: a rise of the dollar has to show up as a rise, not as a drop. Hence
/// [AssetSeries.fromQuoteHistory] inverts the stored value while building the
/// series.
class AssetSeries {
  final String code;
  final AssetKind kind;

  /// Currency the prices are expressed in (the counterpart of the quotes).
  final String quoteCurrency;

  /// Points in chronological order, one per day, with no repeated dates.
  final List<AssetPoint> points;

  AssetSeries._(this.code, this.kind, this.quoteCurrency, this.points);

  factory AssetSeries({
    required String code,
    required AssetKind kind,
    required String quoteCurrency,
    required List<AssetPoint> points,
  }) {
    // A repeated day (the API sometimes returns today's quote alongside the
    // previous close) would become a zero return in the middle of the series
    // and drag the estimated volatility down. The last point of each day wins.
    final byDay = <DateTime, AssetPoint>{};
    for (var point in points) {
      if (!point.price.isFinite || point.price <= 0) continue;
      byDay[DateTime(point.date.year, point.date.month, point.date.day)] = point;
    }
    final ordered = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return AssetSeries._(code, kind, quoteCurrency,
        List.unmodifiable(ordered.map((entry) => entry.value)));
  }

  /// Builds the series from the history the `CurrencyRepository` returns,
  /// inverting each value into the price convention described on the class.
  factory AssetSeries.fromQuoteHistory({
    required String code,
    required AssetKind kind,
    required String quoteCurrency,
    required List<Currency> history,
  }) {
    final points = <AssetPoint>[];
    for (var currency in history) {
      final value = currency.value;
      final date = currency.historicalDate;
      if (value == null || value == 0 || !value.isFinite) continue;
      if (date == null) continue;
      final parsedDate = DateTime.tryParse(date);
      if (parsedDate == null) continue;
      points.add(AssetPoint(date: parsedDate, price: 1 / value));
    }
    return AssetSeries(
        code: code, kind: kind, quoteCurrency: quoteCurrency, points: points);
  }

  int get length => points.length;

  bool get isEmpty => points.isEmpty;

  bool get isNotEmpty => points.isNotEmpty;

  List<double> get prices =>
      points.map((point) => point.price).toList(growable: false);

  List<DateTime> get dates =>
      points.map((point) => point.date).toList(growable: false);

  double get lastPrice => points.last.price;

  DateTime get lastDate => points.last.date;

  DateTime get firstDate => points.first.date;

  /// Calendar days covered by the series, used to annualise the trend.
  int get spanInDays => lastDate.difference(firstDate).inDays;

  /// The last [count] points, so the chart does not draw a whole year of
  /// history next to two weeks of projection.
  List<AssetPoint> tail(int count) =>
      points.length <= count ? points : points.sublist(points.length - count);
}
