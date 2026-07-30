import 'package:cotacao_direta/model/currency.dart';

/// Natureza do ativo analisado. O modelo local é o mesmo para os três: o que
/// muda é o rótulo mostrado na tela e os limiares de volatilidade usados nos
/// insights, já que cripto oscila numa ordem de grandeza acima de moeda
/// fiduciária.
enum AssetKind { currency, cryptocurrency, stock }

/// Um ponto da série: o preço do ativo naquele dia, expresso na moeda de
/// contrapartida.
class AssetPoint {
  final DateTime date;
  final double price;

  const AssetPoint({required this.date, required this.price});

  @override
  String toString() => "AssetPoint(${date.toIso8601String()}, $price)";
}

/// Série temporal de preços pronta para o modelo local.
///
/// O app guarda em [Currency.value] o inverso da cotação — quantas unidades da
/// moeda valem uma unidade da contrapartida (ver `CurrencyRepository`). Quem
/// olha o gráfico raciocina no sentido oposto ("quanto custa um dólar"), e é
/// esse o número que a análise precisa: uma alta do dólar tem que aparecer como
/// alta, não como queda. Por isso [AssetSeries.fromQuoteHistory] inverte o
/// valor guardado ao montar a série.
class AssetSeries {
  final String code;
  final AssetKind kind;

  /// Moeda em que os preços estão expressos (a contrapartida das cotações).
  final String quoteCurrency;

  /// Pontos em ordem cronológica, um por dia, sem repetição de data.
  final List<AssetPoint> points;

  AssetSeries._(this.code, this.kind, this.quoteCurrency, this.points);

  factory AssetSeries({
    required String code,
    required AssetKind kind,
    required String quoteCurrency,
    required List<AssetPoint> points,
  }) {
    // Um dia repetido (a API às vezes devolve o pregão do dia junto do
    // fechamento anterior) viraria um retorno zero no meio da série e
    // rebaixaria a volatilidade estimada. Fica o último ponto de cada dia.
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

  /// Monta a série a partir do histórico que o `CurrencyRepository` devolve,
  /// invertendo cada valor para a convenção de preço descrita na classe.
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

  /// Dias corridos cobertos pela série, usado para anualizar a tendência.
  int get spanInDays => lastDate.difference(firstDate).inDays;

  /// Últimos [count] pontos, para o gráfico não desenhar um ano inteiro de
  /// histórico ao lado de duas semanas de projeção.
  List<AssetPoint> tail(int count) =>
      points.length <= count ? points : points.sublist(points.length - count);
}
