import 'package:cotacao_direta/dao/currency_alert_dao.dart';
import 'package:cotacao_direta/model/currency_alert.dart';

class CurrencyAlertRepository {
  final CurrencyAlertDao _currencyAlertDao;

  CurrencyAlertRepository({CurrencyAlertDao? currencyAlertDao})
      : _currencyAlertDao = currencyAlertDao ?? CurrencyAlertDao();

  Future<int> insert(CurrencyAlert alert) => _currencyAlertDao.insert(alert);

  Future<void> update(CurrencyAlert alert) => _currencyAlertDao.update(alert);

  Future<void> delete(int id) => _currencyAlertDao.delete(id);

  Future<List<CurrencyAlert>> getAll() => _currencyAlertDao.getAll();

  Future<List<CurrencyAlert>> getActiveByCurrencyCode(String currencyCode) =>
      _currencyAlertDao.getActiveByCurrencyCode(currencyCode);
}
