class Currency
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
}