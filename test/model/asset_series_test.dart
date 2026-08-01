import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:flutter_test/flutter_test.dart';

AssetSeries _series(List<AssetPoint> points) => AssetSeries(
      code: "USD",
      kind: AssetKind.currency,
      quoteCurrency: "BRL",
      points: points,
    );

AssetPoint _point(int day, double price) =>
    AssetPoint(date: DateTime(2024, 1, day), price: price);

void main() {
  group('AssetSeries', () {
    test('ordena os pontos por data', () {
      final series = _series([_point(3, 5.3), _point(1, 5.1), _point(2, 5.2)]);

      expect(series.prices, [5.1, 5.2, 5.3]);
      expect(series.firstDate, DateTime(2024, 1, 1));
      expect(series.lastDate, DateTime(2024, 1, 3));
      expect(series.lastPrice, 5.3);
    });

    test('mantém um ponto por dia, o último de cada data', () {
      final series = _series([
        AssetPoint(date: DateTime(2024, 1, 1, 10), price: 5.0),
        AssetPoint(date: DateTime(2024, 1, 1, 18), price: 5.4),
        _point(2, 5.5),
      ]);

      expect(series.length, 2);
      expect(series.prices, [5.4, 5.5]);
    });

    test('descarta preço não positivo ou não finito', () {
      final series = _series([
        _point(1, 5.0),
        _point(2, 0),
        _point(3, -1),
        _point(4, double.nan),
        _point(5, 5.5),
      ]);

      expect(series.prices, [5.0, 5.5]);
    });

    test('conta o intervalo coberto em dias corridos', () {
      final series = _series([_point(1, 5.0), _point(11, 5.5)]);

      expect(series.spanInDays, 10);
    });

    test('a cauda devolve os últimos pontos', () {
      final series = _series(
          List.generate(10, (index) => _point(index + 1, 5.0 + index)));

      expect(series.tail(3).map((point) => point.price), [12.0, 13.0, 14.0]);
    });

    test('a cauda de uma série curta é a série inteira', () {
      final series = _series([_point(1, 5.0), _point(2, 5.1)]);

      expect(series.tail(10).length, 2);
    });

    test('série sem pontos válidos fica vazia', () {
      final series = _series([_point(1, 0)]);

      expect(series.isEmpty, isTrue);
      expect(series.isNotEmpty, isFalse);
      expect(series.length, 0);
    });
  });

  group('AssetSeries.fromQuoteHistory', () {
    test('inverte o valor guardado para virar preço', () {
      // O app guarda 1/cotação: 0,2 dólar por real equivale a R$ 5 por dólar.
      final history = [
        Currency(
            id: "USD",
            value: 0.2,
            historicalDate: DateTime(2024, 1, 1).toIso8601String()),
      ];

      final series = AssetSeries.fromQuoteHistory(
          code: "USD",
          kind: AssetKind.currency,
          quoteCurrency: "BRL",
          history: history);

      expect(series.lastPrice, closeTo(5, 1e-12));
    });

    test('uma alta da moeda aparece como alta do preço', () {
      final history = [
        Currency(
            id: "USD",
            value: 0.2,
            historicalDate: DateTime(2024, 1, 1).toIso8601String()),
        Currency(
            id: "USD",
            value: 0.1,
            historicalDate: DateTime(2024, 1, 2).toIso8601String()),
      ];

      final series = AssetSeries.fromQuoteHistory(
          code: "USD",
          kind: AssetKind.currency,
          quoteCurrency: "BRL",
          history: history);

      expect(series.prices.last, greaterThan(series.prices.first));
    });

    test('ignora registros sem valor, sem data ou com data inválida', () {
      final history = [
        Currency(
            id: "USD",
            value: null,
            historicalDate: DateTime(2024, 1, 1).toIso8601String()),
        Currency(id: "USD", value: 0.2, historicalDate: null),
        Currency(id: "USD", value: 0.2, historicalDate: "não é data"),
        Currency(id: "USD", value: 0, historicalDate: "2024-01-04"),
        Currency(id: "USD", value: 0.25, historicalDate: "2024-01-05"),
      ];

      final series = AssetSeries.fromQuoteHistory(
          code: "USD",
          kind: AssetKind.currency,
          quoteCurrency: "BRL",
          history: history);

      expect(series.length, 1);
      expect(series.lastPrice, closeTo(4, 1e-12));
    });

    test('histórico vazio devolve série vazia', () {
      final series = AssetSeries.fromQuoteHistory(
          code: "USD",
          kind: AssetKind.currency,
          quoteCurrency: "BRL",
          history: []);

      expect(series.isEmpty, isTrue);
    });

    test('guarda o código, o tipo e a moeda de contrapartida', () {
      final series = AssetSeries.fromQuoteHistory(
          code: "BTC",
          kind: AssetKind.cryptocurrency,
          quoteCurrency: "EUR",
          history: [
            Currency(
                id: "BTC", value: 0.000002, historicalDate: "2024-01-01")
          ]);

      expect(series.code, "BTC");
      expect(series.kind, AssetKind.cryptocurrency);
      expect(series.quoteCurrency, "EUR");
    });
  });
}
