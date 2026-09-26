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

  Map<String, Object?> toJson() => {
        'bid': bid,
        'time': time.toIso8601String(),
        'high': high,
        'low': low,
        'pctChange': pctChange,
      };

  static Quote fromJson(Map json) => Quote(
      bid: (json['bid'] as num).toDouble(),
      time: DateTime.parse(json['time'] as String),
      high: (json['high'] as num?)?.toDouble(),
      low: (json['low'] as num?)?.toDouble(),
      pctChange: (json['pctChange'] as num?)?.toDouble());
}

/// Fechamento de um dia, para a tabela e o gráfico do histórico.
class DailyClose {
  final DateTime time;
  final double bid;
  final double? pctChange;

  const DailyClose({required this.time, required this.bid, this.pctChange});

  Map<String, Object?> toJson() =>
      {'time': time.toIso8601String(), 'bid': bid, 'pctChange': pctChange};

  static DailyClose fromJson(Map json) => DailyClose(
      time: DateTime.parse(json['time'] as String),
      bid: (json['bid'] as num).toDouble(),
      pctChange: (json['pctChange'] as num?)?.toDouble());
}

/// Leitura das respostas da AwesomeAPI (economia.awesomeapi.com.br) para o
/// gerador do site. Mesmo formato que o `CurrencyRepository` do app lê.
class AwesomeApi {
  static const _host = 'economia.awesomeapi.com.br';

  final http.Client _client;

  /// Chave de API opcional. Sem ela a AwesomeAPI limita as requisições por IP,
  /// e os IPs dos runners do GitHub Actions são compartilhados: o limite pode
  /// já estar estourado antes da primeira requisição do build (HTTP 429).
  final String? _token;

  /// Espera entre as tentativas de uma requisição recusada.
  final List<Duration> _retryDelays;

  AwesomeApi(
      {http.Client? client,
      String? token,
      List<Duration> retryDelays = const [
        Duration(seconds: 5),
        Duration(seconds: 20),
        Duration(seconds: 45),
      ]})
      : _client = client ?? http.Client(),
        _token = token,
        _retryDelays = retryDelays;

  /// Última cotação de cada código, frente ao real, numa requisição só.
  Future<Map<String, Quote>> latest(List<String> codes) async {
    var pairs = codes.map((code) => '$code-BRL').join(',');
    var body = await _get(_uri('/json/last/$pairs'));
    return parseLatest(body);
  }

  /// Os últimos [days] fechamentos diários, do mais antigo para o mais novo.
  Future<List<DailyClose>> daily(String code, int days) async {
    var body = await _get(_uri('/json/daily/$code-BRL/$days'));
    return parseDaily(body);
  }

  void close() => _client.close();

  Uri _uri(String path) => Uri.https(
      _host, path, _token == null ? null : {'token': _token});

  /// A API às vezes recusa um pedido (limite de requisições, um 5xx
  /// passageiro); tenta de novo com esperas crescentes, respeitando o
  /// `Retry-After` quando ele vier.
  Future<String> _get(Uri uri) async {
    Object? lastError;
    Duration? retryAfter;
    for (var attempt = 0; attempt <= _retryDelays.length; attempt++) {
      if (attempt > 0) {
        var delay = _retryDelays[attempt - 1];
        if (retryAfter != null && retryAfter > delay) delay = retryAfter;
        await Future.delayed(delay);
      }
      retryAfter = null;
      try {
        var response = await _client.get(uri);
        if (response.statusCode == 200) return utf8.decode(response.bodyBytes);
        lastError = 'HTTP ${response.statusCode}';
        var seconds = int.tryParse(response.headers['retry-after'] ?? '');
        // Um Retry-After absurdo não pode travar o build por horas.
        if (seconds != null && seconds <= 120)
          retryAfter = Duration(seconds: seconds);
      } catch (error) {
        lastError = error;
      }
    }
    // O token não entra na mensagem, que vai parar no log público do CI.
    throw Exception(
        'Falha ao consultar ${Uri.https(uri.host, uri.path)}: $lastError');
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
