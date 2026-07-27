import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/model/base_model.dart';

class CurrencyAlert extends BaseModel {
  int? id;
  String currencyCode;
  double targetValue;
  CurrencyAlertCondition condition;
  bool triggered;
  bool active;

  CurrencyAlert(
      {this.id,
      required this.currencyCode,
      required this.targetValue,
      required this.condition,
      this.triggered = false,
      this.active = true});

  /// Verifica se um valor de cotação já cumpre a condição do alerta.
  bool isMetBy(double currentValue) {
    return condition == CurrencyAlertCondition.above
        ? currentValue >= targetValue
        : currentValue <= targetValue;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'currencyCode': currencyCode,
      'targetValue': targetValue,
      'condition': condition.name,
      'triggered': triggered ? 1 : 0,
      'active': active ? 1 : 0,
    };
  }

  @override
  String toString() {
    return "{"
        "id: $id,\n"
        "currencyCode: $currencyCode,\n"
        "targetValue: $targetValue,\n"
        "condition: $condition,\n"
        "triggered: $triggered,\n"
        "active: $active,\n"
        "}";
  }
}
