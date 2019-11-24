class Currency
{
  String id;
  double value;
  String timestamp;

  Currency({this.id, this.value, this.timestamp});

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'value': value,
      'timestamp': timestamp
    };
  }
}