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
  ///
  /// A comparação e o valor avisado usam a cotação na mesma convenção que o
  /// usuário vê no app — quantas unidades da contrapartida valem uma unidade
  /// da moeda ("um dólar a 5,50 reais") —, que é o inverso do que
  /// `Currency.value` guarda (ver [CurrencyRepository]). É nessa convenção que
  /// o alvo do alerta é digitado, então comparar direto com o valor guardado
  /// invertia a relação: um alerta de "USD acima de 5,00" nunca disparava, e o
  /// aviso reportaria 0,1818 no lugar de 5,50.
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
        return MapEntry(code, _quotedRate(currency?.value));
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

  /// Converte o valor guardado em `Currency.value` na cotação exibida pelo
  /// app. Valor ausente ou zerado não vira cotação nenhuma: dividir por zero
  /// daria infinito, que atenderia qualquer alerta de "acima de".
  double? _quotedRate(double? storedValue) =>
      storedValue == null || storedValue == 0 ? null : 1 / storedValue;

  @override
  void dispose() {
    _alertsStreamController.close();
  }
}
