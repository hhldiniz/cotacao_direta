import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cotação mais recente de uma moeda frente ao real, como a AwesomeAPI
/// devolve: [bid] em reais por uma unidade da moeda — o contrário da
/// convenção que o app guarda no banco, mas é o número que a página mostra.
class Quote {
  final double bid;
  final double? high;
  final double? low;
  final double? pctChange;
  final DateTime time;

  const Quote(
      {required this.bid,
      required this.time,
      this.high,
      this.low,
      this.pctChange});
}

/// Fechamento de um dia, para a tabela e o gráfico do histórico.
class DailyClose {
  final DateTime time;
  final double bid;
  final double? pctChange;

  const DailyClose({required this.time, required this.bid, this.pctChange});
}

/// Leitura das respostas da AwesomeAPI (economia.awesomeapi.com.br) para o
/// gerador do site. Mesmo formato que o `CurrencyRepository` do app lê.
class AwesomeApi {
  static const _host = 'economia.awesomeapi.com.br';

  final http.Client _client;

  AwesomeApi([http.Client? client]) : _client = client ?? http.Client();

  /// Última cotação de cada código, frente ao real, numa requisição só.
  Future<Map<String, Quote>> latest(List<String> codes) async {
    var pairs = codes.map((code) => '$code-BRL').join(',');
    var body = await _get(Uri.https(_host, '/json/last/$pairs'));
    return parseLatest(body);
  }

  /// Os últimos [days] fechamentos diários, do mais antigo para o mais novo.
  Future<List<DailyClose>> daily(String code, int days) async {
    var body = await _get(Uri.https(_host, '/json/daily/$code-BRL/$days'));
    return parseDaily(body);
  }

  void close() => _client.close();

  /// A API às vezes recusa um pedido isolado (limite de requisições, um 5xx
  /// passageiro); três tentativas espaçadas bastam para um build de hora em
  /// hora não falhar à toa.
  Future<String> _get(Uri uri) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) await Future.delayed(Duration(seconds: 2 << attempt));
      try {
        var response = await _client.get(uri);
        if (response.statusCode == 200) return utf8.decode(response.bodyBytes);
        lastError = 'HTTP ${response.statusCode}';
      } catch (error) {
        lastError = error;
      }
    }
    throw Exception('Falha ao consultar $uri: $lastError');
  }

  /// `/json/last` devolve um objeto com o par sem hífen como chave
  /// ({"USDBRL": {...}}); a chave de retorno é só o código (USD).
  static Map<String, Quote> parseLatest(String body) {
    var decoded = jsonDecode(body);
    var result = <String, Quote>{};
    if (decoded is! Map) return result;
    for (var item in decoded.values.whereType<Map>()) {
      var code = item['code'];
      var bid = _asDouble(item['bid']);
      var time = _asTime(item['timestamp']);
      if (code is! String || bid == null || bid == 0 || time == null) continue;
      result[code] = Quote(
          bid: bid,
          time: time,
          high: _asDouble(item['high']),
          low: _asDouble(item['low']),
          pctChange: _asDouble(item['pctChange']));
    }
    return result;
  }

  /// `/json/daily` devolve uma lista do mais novo para o mais antigo; só o
  /// primeiro item traz o nome e os códigos, os demais trazem apenas valores.
  static List<DailyClose> parseDaily(String body) {
    var decoded = jsonDecode(body);
    if (decoded is! List) return [];
    var result = <DailyClose>[];
    for (var item in decoded.whereType<Map>()) {
      var bid = _asDouble(item['bid']);
      var time = _asTime(item['timestamp']);
      if (bid == null || bid == 0 || time == null) continue;
      result.add(DailyClose(
          time: time, bid: bid, pctChange: _asDouble(item['pctChange'])));
    }
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// O `timestamp` vem em segundos desde a época, às vezes como texto.
  static DateTime? _asTime(Object? value) {
    var seconds = value is num ? value.toInt() : int.tryParse('$value');
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }
}
