import 'package:cotacao_direta/dao/configuration_dao.dart';
import 'package:cotacao_direta/model/configuration.dart';

class ConfigurationRepository {
  final ConfigurationDao _configurationDao;

  // A configuração é lida do banco várias vezes no mesmo ciclo de atualização
  // (uma por moeda na tela inicial, mais alertas, mais histórico); um cache
  // curto evita essas leituras repetidas sem arriscar ficar desatualizado por
  // muito tempo caso o usuário altere as configurações.
  static const _cacheTtl = Duration(seconds: 2);
  Configuration? _cachedConfiguration;
  DateTime? _cachedAt;

  ConfigurationRepository({ConfigurationDao? configurationDao})
      : _configurationDao = configurationDao ?? ConfigurationDao();

  Future<void> insert(Configuration configuration) async {
    await _configurationDao.insert(configuration);
    _cachedConfiguration = configuration;
    _cachedAt = DateTime.now();
  }

  Future<Configuration> getConfiguration() async {
    final cached = _cachedConfiguration;
    final cachedAt = _cachedAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }
    final configuration = await _configurationDao.getConfiguration();
    _cachedConfiguration = configuration;
    _cachedAt = DateTime.now();
    return configuration;
  }
}
