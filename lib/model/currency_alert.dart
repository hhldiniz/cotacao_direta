import 'package:cotacao_direta/enums/currency_alert_condition.dart';
import 'package:cotacao_direta/model/base_model.dart';

class CurrencyAlert extends BaseModel {
  int? id;
  String currencyCode;
  double targetValue;
  CurrencyAlertCondition condition;
  bool triggered;
  bool active;

  /// Moeda em que [targetValue] está expresso: a contrapartida do par cotado.
  /// "USD acima de 5,00" só quer dizer alguma coisa junto dela — cinco reais e
  /// cinco euros são alvos diferentes.
  ///
  /// Fica gravada no alerta, e não lida das configurações na hora da checagem,
  /// para que trocar a moeda de referência não mude por baixo do pano o que um
  /// alerta já cadastrado significa.
  String counterCurrency;

  CurrencyAlert(
      {this.id,
      required this.currencyCode,
      required this.targetValue,
      required this.condition,
      required this.counterCurrency,
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
      'counterCurrency': counterCurrency,
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
        "counterCurrency: $counterCurrency,\n"
        "triggered: $triggered,\n"
        "active: $active,\n"
        "}";
  }
}
