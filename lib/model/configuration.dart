import 'package:cotacao_direta/model/base_model.dart';

class Configuration extends BaseModel {
  int id;
  bool overrideDefaultCurrency;
  String selectedOverrideCurrencyCode;

  Configuration(this.id,
      {this.overrideDefaultCurrency, this.selectedOverrideCurrencyCode});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'overrideDefaultCurrency': overrideDefaultCurrency ? 1 : 0,
      'selectedOverrideCurrencyCode': selectedOverrideCurrencyCode,
    };
  }

  @override
  String toString() {
    return "{"
        "id: $id,\n"
        "overrideDefaultCurrency: $overrideDefaultCurrency,\n"
        "selectedOverrideCurrencyCode: $selectedOverrideCurrencyCode, \n"
        "}";
  }
}
