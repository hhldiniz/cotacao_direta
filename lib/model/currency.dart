import 'package:cotacao_direta/model/base_model.dart';

class Currency extends BaseModel
{
  String id;
  double value;
  String historicalDate;
  String timestamp;

  Currency({this.id, this.value, this.historicalDate, this.timestamp});

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'value': value,
      'historicalDate': historicalDate,
      'timestamp': timestamp
    };
  }

  @override
  String toString() {
    return "{"
        "id: $id,\n"
        "value: $value, \n"
        "historicalDate: $historicalDate, \n"
        "timestamp: $timestamp \n"
        "}";
  }
}