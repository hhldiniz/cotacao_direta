import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/model/currency_alert.dart';
import 'package:cotacao_direta/repository/currency_alert_repository.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:cotacao_direta/util/notification_service.dart';

class CurrencyAlertsBloc extends BaseBloc {
  final CurrencyAlertRepository _currencyAlertRepository;
  final CurrencyRepository _currencyRepository;
  final NotificationService _notificationService;

  final StreamController<List<CurrencyAlert>> _alertsStreamController =
      StreamController<List<CurrencyAlert>>.broadcast();

  CurrencyAlertsBloc(
      {CurrencyAlertRepository? currencyAlertRepository,
      CurrencyRepository? currencyRepository,
      NotificationService? notificationService})
      : _currencyAlertRepository =
            currencyAlertRepository ?? CurrencyAlertRepository(),
        _currencyRepository = currencyRepository ?? CurrencyRepository(),
        _notificationService = notificationService ?? NotificationService();

  Stream<List<CurrencyAlert>> get alertsStream => _alertsStreamController.stream;

  Future<void> loadAlerts() async {
    _alertsStreamController.sink.add(await _currencyAlertRepository.getAll());
  }

  Future<void> addAlert(String currencyCode, double targetValue,
      CurrencyAlertCondition condition) async {
    await _currencyAlertRepository.insert(CurrencyAlert(
        currencyCode: currencyCode,
        targetValue: targetValue,
        condition: condition));
    await loadAlerts();
  }

  Future<void> deleteAlert(int id) async {
    await _currencyAlertRepository.delete(id);
    await loadAlerts();
  }

  /// Confere os alertas ativos ainda não disparados: busca a cotação mais
  /// recente da moeda de cada um e, se a condição já for atendida, notifica o
  /// usuário e marca o alerta como disparado para não repetir o aviso.
  Future<void> checkAlerts(
      {required String notificationTitle,
      required String Function(CurrencyAlert alert, double value)
          notificationBody}) async {
    var alerts = await _currencyAlertRepository.getAll();
    var pendingAlerts =
        alerts.where((alert) => alert.active && !alert.triggered).toList();
    if (pendingAlerts.isEmpty) return;

    // Vários alertas costumam ser da mesma moeda: busca cada código uma única
    // vez, e em paralelo, em vez de uma consulta sequencial por alerta.
    var currencyCodes = pendingAlerts.map((alert) => alert.currencyCode).toSet();
    var latestValueByCode = Map.fromEntries(
      await Future.wait(currencyCodes.map((code) async {
        var currency = await _currencyRepository.getLatestDataByCurrencyCode(code);
        return MapEntry(code, currency?.value);
      })),
    );

    var triggeredAny = false;
    for (var alert in pendingAlerts) {
      var value = latestValueByCode[alert.currencyCode];
      if (value == null || !alert.isMetBy(value)) continue;
      alert.triggered = true;
      await _currencyAlertRepository.update(alert);
      await _notificationService.showAlertTriggered(
          id: alert.id!,
          title: notificationTitle,
          body: notificationBody(alert, value));
      triggeredAny = true;
    }
    if (triggeredAny) await loadAlerts();
  }

  @override
  void dispose() {
    _alertsStreamController.close();
  }
}
