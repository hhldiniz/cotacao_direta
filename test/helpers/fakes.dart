import 'package:cotacao_direta/dao/configuration_dao.dart';
import 'package:cotacao_direta/dao/currency_alert_dao.dart';
import 'package:cotacao_direta/dao/currency_dao.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/repository/currency_alert_repository.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:cotacao_direta/util/network_util.dart';
import 'package:cotacao_direta/util/notification_service.dart';

/// Substitui a checagem real de rede (que faz um DNS lookup) por um valor fixo.
class FakeNetworkUtils implements NetworkUtils {
  bool available;

  FakeNetworkUtils({this.available = true});

  @override
  Future<bool> isNetworkAvailable() async => available;
}

/// DAO de moedas em memória, que registra o que foi gravado.
class FakeCurrencyDao implements CurrencyDao {
  final List<Currency> inserted = [];
  final List<List<Currency>> insertedBatches = [];
  final List<List<dynamic>> historicalDataCalls = [];

  /// Contrapartida pedida em cada consulta da última cotação, para os testes
  /// conferirem que o par certo foi procurado.
  final List<String> latestDataCounterCurrencies = [];

  Currency? latestCurrency;
  Currency? currencyByCode;
  List<Currency> historicalData = [];

  @override
  Future<void> insert(Currency currency) async => inserted.add(currency);

  @override
  Future<void> insertMany(List<Currency> currencies) async {
    insertedBatches.add(currencies);
    inserted.addAll(currencies);
  }

  @override
  Future<Currency?> getLatestDataByCurrencyCode(
      String? currencyCode, String counterCurrency) async {
    latestDataCounterCurrencies.add(counterCurrency);
    // Uma cotação salva só serve para o par que a originou: devolvê-la para
    // outra contrapartida é justamente o bug que o registro do par evita.
    if (latestCurrency?.counterCurrency != null &&
        latestCurrency!.counterCurrency != counterCurrency) {
      return null;
    }
    return latestCurrency;
  }

  @override
  Future<Currency?> getCurrencyByCode(
          String currencyCode, String counterCurrency) async =>
      currencyByCode;

  @override
  Future<List<Currency>> getHistoricalData(List<String> currencyCodeList,
      String initialDate, String finalDate, String counterCurrency) async {
    historicalDataCalls
        .add([currencyCodeList, initialDate, finalDate, counterCurrency]);
    return historicalData;
  }
}

/// Repositório de cotações em memória, para isolar quem consome o histórico
/// (a análise local) da API e do banco.
class FakeCurrencyRepository implements CurrencyRepository {
  /// Histórico devolvido por [getCurrencyHistoricalData], independentemente do
  /// período pedido.
  List<Currency> historicalData = [];

  Currency? latestCurrency;
  String counterCurrency = "BRL";

  /// Argumentos de cada chamada ao histórico, na ordem em que chegaram.
  final List<List<dynamic>> historicalDataCalls = [];

  /// Quando definido, é lançado no lugar de devolver o histórico.
  Object? failure;

  @override
  Future<List<Currency>> getCurrencyHistoricalData(
      List<String> currencyCodeList, initialDate, finalDate) async {
    historicalDataCalls.add([currencyCodeList, initialDate, finalDate]);
    if (failure != null) throw failure!;
    return historicalData;
  }

  @override
  Future<Currency?> getLatestDataByCurrencyCode(String? currencyCode) async =>
      latestCurrency;

  @override
  Future<String> resolveCounterCurrency() async => counterCurrency;
}

/// DAO de configuração em memória.
class FakeConfigurationDao implements ConfigurationDao {
  final List<Configuration> inserted = [];
  Configuration configuration = Configuration(1);

  @override
  Future<void> insert(Configuration configuration) async {
    inserted.add(configuration);
    this.configuration = configuration;
  }

  @override
  Future<Configuration> getConfiguration() async => configuration;
}

/// Repositório de configuração em memória, para isolar o CurrencyRepository.
class FakeConfigurationRepository implements ConfigurationRepository {
  final List<Configuration> inserted = [];
  Configuration configuration = Configuration(1);

  FakeConfigurationRepository({Configuration? configuration}) {
    if (configuration != null) this.configuration = configuration;
  }

  @override
  Future<void> insert(Configuration configuration) async {
    inserted.add(configuration);
    this.configuration = configuration;
  }

  @override
  Future<Configuration> getConfiguration() async => configuration;
}

/// DAO de alertas de câmbio em memória.
class FakeCurrencyAlertDao implements CurrencyAlertDao {
  final List<CurrencyAlert> alerts = [];
  int _nextId = 1;

  @override
  Future<int> insert(CurrencyAlert alert) async {
    var id = alert.id ?? _nextId++;
    alert.id = id;
    alerts.removeWhere((existing) => existing.id == id);
    alerts.add(alert);
    return id;
  }

  @override
  Future<void> update(CurrencyAlert alert) async {
    var index = alerts.indexWhere((existing) => existing.id == alert.id);
    if (index >= 0) alerts[index] = alert;
  }

  @override
  Future<void> delete(int id) async {
    alerts.removeWhere((alert) => alert.id == id);
  }

  @override
  Future<List<CurrencyAlert>> getAll() async => List.of(alerts);

  @override
  Future<List<CurrencyAlert>> getActiveByCurrencyCode(
          String currencyCode) async =>
      alerts
          .where((alert) =>
              alert.currencyCode == currencyCode &&
              alert.active &&
              !alert.triggered)
          .toList();
}

/// Repositório de alertas de câmbio em memória, para isolar o
/// CurrencyAlertsBloc.
class FakeCurrencyAlertRepository implements CurrencyAlertRepository {
  final List<CurrencyAlert> alerts;
  final List<CurrencyAlert> updated = [];
  final List<int> deletedIds = [];
  int _nextId = 1;

  FakeCurrencyAlertRepository({List<CurrencyAlert>? alerts})
      : alerts = alerts ?? [];

  @override
  Future<int> insert(CurrencyAlert alert) async {
    var id = alert.id ?? _nextId++;
    alert.id = id;
    alerts.add(alert);
    return id;
  }

  @override
  Future<void> update(CurrencyAlert alert) async {
    updated.add(alert);
    var index = alerts.indexWhere((existing) => existing.id == alert.id);
    if (index >= 0) alerts[index] = alert;
  }

  @override
  Future<void> delete(int id) async {
    deletedIds.add(id);
    alerts.removeWhere((alert) => alert.id == id);
  }

  @override
  Future<List<CurrencyAlert>> getAll() async => List.of(alerts);

  @override
  Future<List<CurrencyAlert>> getActiveByCurrencyCode(
          String currencyCode) async =>
      alerts
          .where((alert) =>
              alert.currencyCode == currencyCode &&
              alert.active &&
              !alert.triggered)
          .toList();
}

/// Serviço de notificações em memória: registra o que teria sido mostrado em
/// vez de acionar o plugin de verdade.
class FakeNotificationService implements NotificationService {
  final List<Map<String, Object>> shown = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showAlertTriggered(
      {required int id, required String title, required String body}) async {
    shown.add({'id': id, 'title': title, 'body': body});
  }
}
