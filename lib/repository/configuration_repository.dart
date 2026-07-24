import 'package:cotacao_direta/dao/configuration_dao.dart';
import 'package:cotacao_direta/model/configuration.dart';

class ConfigurationRepository {
  final ConfigurationDao _configurationDao;

  ConfigurationRepository({ConfigurationDao? configurationDao})
      : _configurationDao = configurationDao ?? ConfigurationDao();

  Future<void> insert(Configuration configuration) async {
    return _configurationDao.insert(configuration);
  }

  Future<Configuration> getConfiguration() async {
    return _configurationDao.getConfiguration();
  }
}
