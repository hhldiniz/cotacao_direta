import 'dart:convert';

import 'package:cotacao_direta/dao/currency_dao.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/util/network_util.dart';
import 'package:cotacao_direta/util/string_utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Cotações vindas da AwesomeAPI (economia.awesomeapi.com.br).
///
/// A API trabalha com pares MOEDA-CONTRAPARTIDA (USD-BRL) e devolve o valor no
/// campo `bid`, em unidades da contrapartida por uma unidade da moeda cotada:
/// para USD-BRL, quantos reais vale um dólar.
///
/// O app guarda o inverso disso em [Currency.value] — quantas unidades da moeda
/// valem uma unidade da contrapartida. É a convenção que a tela inicial
/// (que mostra `1 / value`) e a conversão (que divide um valor pelo outro) já
/// usavam, então a inversão feita aqui mantém o resto do app funcionando sem
/// alteração.
class CurrencyRepository {
  static CurrencyRepository? _instance;

  final CurrencyDao _currencyDao;
  final ConfigurationRepository _configurationRepository;
  final NetworkUtils _networkUtils;
  final http.Client _httpClient;

  static const _apiHost = "economia.awesomeapi.com.br";

  /// Teto de registros por consulta ao histórico, imposto pela API.
  static const _maxHistoryRecords = 360;

  final _enumValueAsStringUtil = EnumValueAsString();
  final _apiDateFormatter = DateFormat("yyyyMMdd");

  factory CurrencyRepository() {
    if (_instance == null)
      _instance = CurrencyRepository._internalConstructor();
    return _instance!;
  }

  /// Cria uma instância isolada (fora do singleton) com as dependências
  /// fornecidas pelo chamador. Usado pelos testes.
  factory CurrencyRepository.withDependencies(
          {CurrencyDao? currencyDao,
          ConfigurationRepository? configurationRepository,
          NetworkUtils? networkUtils,
          http.Client? httpClient}) =>
      CurrencyRepository._internalConstructor(
          currencyDao: currencyDao,
          configurationRepository: configurationRepository,
          networkUtils: networkUtils,
          httpClient: httpClient);

  CurrencyRepository._internalConstructor(
      {CurrencyDao? currencyDao,
      ConfigurationRepository? configurationRepository,
      NetworkUtils? networkUtils,
      http.Client? httpClient})
      : _currencyDao = currencyDao ?? CurrencyDao(),
        _configurationRepository =
            configurationRepository ?? ConfigurationRepository(),
        _networkUtils = networkUtils ?? NetworkUtils(),
        _httpClient = httpClient ?? http.Client();

  /// Descarta o singleton para que um teste não vaze estado para o seguinte.
  static void resetInstance() => _instance = null;

  /// Moeda contra a qual as cotações são expressas quando o usuário não
  /// escolheu outra nas configurações: o app cota "frente ao real".
  String get _defaultCounterCurrency =>
      _enumValueAsStringUtil.getEnumValue(Currencies.BRL.toString());

  /// Moeda usada hoje como contrapartida das cotações: a escolhida nas
  /// configurações, ou BRL por padrão. Exposta publicamente porque a tela de
  /// histórico precisa saber qual moeda excluir da lista — uma moeda cotada
  /// contra ela mesma não tem série para desenhar (ver
  /// [getCurrencyHistoricalData]).
  Future<String> resolveCounterCurrency() async {
    final configuration = await _configurationRepository.getConfiguration();
    final selected = configuration.selectedOverrideCurrencyCode;
    if (configuration.overrideDefaultCurrency &&
        selected != null &&
        selected.isNotEmpty) {
      return selected;
    }
    return _defaultCounterCurrency;
  }

  Uri _lastQuoteUri(String currencyCode, String counterCurrency) =>
      Uri.https(_apiHost, "/json/last/$currencyCode-$counterCurrency");

  Uri _availableCurrenciesUri() => Uri.https(_apiHost, "/json/available/uniq");

  Uri _historyUri(String currencyCode, String counterCurrency,
      DateTime? initialDate, DateTime? finalDate) {
    var records = _maxHistoryRecords;
    if (initialDate != null && finalDate != null) {
      records = finalDate.difference(initialDate).inDays + 1;
      if (records < 1) records = 1;
      if (records > _maxHistoryRecords) records = _maxHistoryRecords;
    }
    var query = <String, String>{};
    if (initialDate != null)
      query["start_date"] = _apiDateFormatter.format(initialDate);
    if (finalDate != null)
      query["end_date"] = _apiDateFormatter.format(finalDate);
    // Mapa vazio deixaria a URL terminada em "?".
    return Uri.https(
        _apiHost,
        "/json/daily/$currencyCode-$counterCurrency/$records",
        query.isEmpty ? null : query);
  }

  /// Nomes amigáveis das moedas, no formato {"USD-BRL": "Dólar Americano/Real
  /// Brasileiro"}. Só é consultada quando um registro salvo está sem nome: nas
  /// consultas de cotação o nome já vem junto do valor.
  Future<Map<String?, String?>> _friendlyCurrencyCodeNameList() async {
    var response = await _httpClient.get(_availableCurrenciesUri());
    var friendlyCurrencyNamesMap = Map<String?, String?>();
    var decoded = _tryDecode(response.body);
    if (decoded is! Map) return friendlyCurrencyNamesMap;
    decoded.forEach((pair, name) {
      if (pair is! String || name is! String) return;
      friendlyCurrencyNamesMap[pair.split("-").first] =
          _quotedCurrencyName(name);
    });
    return friendlyCurrencyNamesMap;
  }

  Future<Currency?> getLatestDataByCurrencyCode(String? currencyCode) async {
    var networkAvailable = await _networkUtils.isNetworkAvailable();
    var counterCurrency = await resolveCounterCurrency();
    // A busca é pelo par, e não só pela moeda cotada: trocar a contrapartida
    // nas configurações precisa provocar uma consulta nova, mesmo que exista
    // uma cotação recente da mesma moeda frente à contrapartida anterior.
    var savedCurrency = await _currencyDao.getLatestDataByCurrencyCode(
        currencyCode, counterCurrency);
    if (networkAvailable &&
        (savedCurrency == null ||
            !_isCurrencyTimestampValid(savedCurrency.timestamp))) {
      var newCurrency = await _fetchLatestQuote(currencyCode);
      // Sem cotação nova (resposta inesperada, par inexistente), o que já está
      // salvo continua valendo: gravar um registro sem valor esconderia a
      // última cotação boa pela hora seguinte.
      if (newCurrency == null) return savedCurrency;
      await _currencyDao.insert(newCurrency);
      return newCurrency;
    } else {
      // Sem rede e sem nada salvo não há o que devolver: é o primeiro uso do
      // aplicativo offline.
      if (savedCurrency == null) return null;
      if (savedCurrency.friendlyName?.isNotEmpty != true) {
        savedCurrency.friendlyName =
            (await _friendlyCurrencyCodeNameList())[currencyCode];
        await _currencyDao.insert(savedCurrency);
      }
      return savedCurrency;
    }
  }

  Future<Currency?> _fetchLatestQuote(String? currencyCode) async {
    if (currencyCode == null || currencyCode.isEmpty) return null;
    var counterCurrency = await resolveCounterCurrency();
    // Uma moeda cotada contra ela mesma vale exatamente uma unidade; a API não
    // tem esse par.
    if (currencyCode == counterCurrency) {
      var now = DateTime.now();
      return Currency(
          id: currencyCode,
          value: 1,
          historicalDate: now.toIso8601String(),
          timestamp: now.toIso8601String(),
          counterCurrency: counterCurrency);
    }
    var response =
        await _httpClient.get(_lastQuoteUri(currencyCode, counterCurrency));
    var quote = _parseLastQuote(response.body, currencyCode, counterCurrency);
    return quote == null
        ? null
        : _currencyFromQuote(quote, currencyCode, counterCurrency);
  }

  Future<List<Currency>> getCurrencyHistoricalData(
      List<String> currencyCodeList, initialDate, finalDate) async {
    if (await _networkUtils.isNetworkAvailable()) {
      var counterCurrency = await resolveCounterCurrency();
      var start = _parseAppDate(initialDate);
      var end = _parseAppDate(finalDate);
      var currencyListToSave = <Currency>[];
      // A API atende um par por consulta; o app costuma pedir uma moeda só.
      for (var currencyCode in currencyCodeList) {
        if (currencyCode == counterCurrency) continue;
        var response = await _httpClient
            .get(_historyUri(currencyCode, counterCurrency, start, end));
        currencyListToSave.addAll(
            _parseHistory(response.body, currencyCode, counterCurrency));
      }

      // Cada registro carrega sua data já convertida uma única vez, em vez de
      // reparsear a mesma string repetidamente no filtro e no comparador do
      // sort.
      var dated = currencyListToSave
          .map((currency) =>
              (currency: currency, date: DateTime.parse(currency.historicalDate!)))
          .toList();

      await _currencyDao.insertMany(dated
          .where((entry) => (DateTime.now().year - entry.date.year) < 10)
          .map((entry) => entry.currency)
          .toList());

      dated.sort((a, b) => a.date.compareTo(b.date));
      return dated.map((entry) => entry.currency).toList();
    } else
      return await _currencyDao.getHistoricalData(currencyCodeList, initialDate,
          finalDate, await resolveCounterCurrency());
  }

  /// A resposta de `/json/last` é um objeto com o par sem o hífen como chave:
  /// USD-BRL vira USDBRL.
  Map? _parseLastQuote(
      String responseBody, String currencyCode, String counterCurrency) {
    var decoded = _tryDecode(responseBody);
    if (decoded is! Map) return null;
    var item = decoded["$currencyCode$counterCurrency"];
    if (item is Map) return item;
    // Pedimos um par só: se a chave vier em outro formato, o único item da
    // resposta ainda é o que queremos. Respostas de erro não têm objetos
    // aninhados e caem fora daqui.
    var items = decoded.values.whereType<Map>().toList();
    return items.length == 1 ? items.first : null;
  }

  /// A resposta de `/json/daily` é uma lista de itens no mesmo formato do
  /// `/json/last`, um por dia.
  List<Currency> _parseHistory(
      String responseBody, String currencyCode, String counterCurrency) {
    var decoded = _tryDecode(responseBody);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => _currencyFromQuote(item, currencyCode, counterCurrency))
        .whereType<Currency>()
        .toList();
  }

  /// Converte um item da API no [Currency] que o app guarda, invertendo o
  /// `bid` para a convenção descrita na documentação da classe.
  Currency? _currencyFromQuote(
      Map item, String currencyCode, String counterCurrency) {
    var bid = _asDouble(item["bid"]) ?? _asDouble(item["ask"]);
    if (bid == null || bid == 0) return null;
    var quoteDate = _quoteDate(item) ?? DateTime.now();
    return Currency(
        id: currencyCode,
        value: 1 / bid,
        historicalDate: quoteDate.toIso8601String(),
        timestamp: DateTime.now().toIso8601String(),
        friendlyName: _quotedCurrencyName(item["name"]),
        counterCurrency: counterCurrency);
  }

  /// O `timestamp` vem em segundos desde a época; o `create_date`, como
  /// "yyyy-MM-dd HH:mm:ss".
  DateTime? _quoteDate(Map item) {
    var timestamp = item["timestamp"];
    var seconds =
        timestamp is num ? timestamp.toInt() : int.tryParse("$timestamp");
    if (seconds != null)
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    var createDate = item["create_date"];
    return createDate is String ? DateTime.tryParse(createDate) : null;
  }

  /// O `name` vem como "Dólar Americano/Real Brasileiro": a parte antes da
  /// barra é o nome da moeda cotada.
  String? _quotedCurrencyName(dynamic name) {
    if (name is! String || name.isEmpty) return null;
    var separator = name.indexOf("/");
    return separator < 0 ? name : name.substring(0, separator);
  }

  DateTime? _parseAppDate(dynamic date) {
    if (date is DateTime) return date;
    if (date is String && date.isNotEmpty) return DateTime.tryParse(date);
    return null;
  }

  dynamic _tryDecode(String responseBody) {
    try {
      return jsonDecode(responseBody);
    } catch (exception) {
      return null;
    }
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool _isCurrencyTimestampValid(String? timeStamp) {
    if (timeStamp == null) return false;
    try {
      var timeStampDate = DateTime.parse(timeStamp);
      return DateTime.now().difference(timeStampDate).inHours < 1;
    } catch (exception) {
      return false;
    }
  }
}
