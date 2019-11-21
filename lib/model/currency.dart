class Currency
{
  int id;
  double value;

  Currency({this.id, this.value});

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'value': value
    };
  }
}