import 'package:cotacao_direta/model/base_model.dart';

class Currency extends BaseModel
{
  String? id;
  double? value;
  String? historicalDate;
  String? timestamp;
  String? friendlyName;

  /// Moeda contra a qual esta cotação foi obtida (a contrapartida do par).
  /// Faz parte da identidade do registro: "USD a 0,18" só quer dizer alguma
  /// coisa quando se sabe se é frente ao real ou ao euro.
  String? counterCurrency;

  Currency({this.id, this.value, this.historicalDate, this.timestamp, this.friendlyName, this.counterCurrency});

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'value': value,
      'historicalDate': historicalDate,
      'timestamp': timestamp,
      'friendlyName': friendlyName,
      'counterCurrency': counterCurrency
    };
  }

  @override
  String toString() {
    return "{"
        "id: $id,\n"
        "value: $value, \n"
        "historicalDate: $historicalDate, \n"
        "timestamp: $timestamp \n"
        "friendlyName: $friendlyName \n"
        "counterCurrency: $counterCurrency \n"
        "}";
  }
}
