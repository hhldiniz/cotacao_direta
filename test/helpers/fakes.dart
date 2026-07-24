import 'package:cotacao_direta/dao/configuration_dao.dart';
import 'package:cotacao_direta/dao/currency_dao.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/util/network_util.dart';

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
  Future<Currency?> getLatestDataByCurrencyCode(String? currencyCode) async =>
      latestCurrency;

  @override
  Future<Currency?> getCurrencyByCode(String currencyCode) async =>
      currencyByCode;

  @override
  Future<List<Currency>> getHistoricalData(List<String> currencyCodeList,
      String initialDate, String finalDate) async {
    historicalDataCalls.add([currencyCodeList, initialDate, finalDate]);
    return historicalData;
  }
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
