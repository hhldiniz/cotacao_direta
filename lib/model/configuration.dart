import 'package:cotacao_direta/model/base_model.dart';

class Configuration extends BaseModel {
  /// Moedas mostradas em bolha na tela inicial enquanto o usuário não escolhe
  /// as suas: as mesmas quatro que a tela trazia fixas antes de a opção
  /// existir, para quem já usava o app não ver a tela mudar sozinha.
  static const List<String> defaultHomeCurrencyCodes = [
    "USD",
    "EUR",
    "CAD",
    "JPY"
  ];

  int id;
  bool overrideDefaultCurrency;
  String? selectedOverrideCurrencyCode;

  /// Códigos das moedas que viram bolha na tela inicial, na ordem em que
  /// aparecem — a primeira é a bolha de destaque.
  List<String> homeCurrencyCodes;

  Configuration(this.id,
      {this.overrideDefaultCurrency = false,
      this.selectedOverrideCurrencyCode = "",
      List<String>? homeCurrencyCodes})
      : homeCurrencyCodes =
            homeCurrencyCodes ?? List.of(defaultHomeCurrencyCodes);

  /// Lê a lista guardada em uma única coluna de texto, separada por vírgula.
  ///
  /// São poucos códigos de três letras e eles são sempre lidos juntos, então
  /// uma tabela só para isso não pagaria o custo. Texto vazio — o padrão da
  /// coluna, e o que os bancos já existentes recebem na migração — significa
  /// "o usuário nunca escolheu": valem as moedas padrão.
  static List<String> parseHomeCurrencyCodes(String? storedValue) {
    if (storedValue == null) return List.of(defaultHomeCurrencyCodes);
    var codes = storedValue
        .split(",")
        .map((code) => code.trim().toUpperCase())
        .where((code) => code.isNotEmpty)
        .toList();
    return codes.isEmpty ? List.of(defaultHomeCurrencyCodes) : codes;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'overrideDefaultCurrency': overrideDefaultCurrency ? 1 : 0,
      'selectedOverrideCurrencyCode': selectedOverrideCurrencyCode,
      'homeCurrencyCodes': homeCurrencyCodes.join(","),
    };
  }

  @override
  String toString() {
    return "{"
        "id: $id,\n"
        "overrideDefaultCurrency: $overrideDefaultCurrency,\n"
        "selectedOverrideCurrencyCode: $selectedOverrideCurrencyCode, \n"
        "homeCurrencyCodes: ${homeCurrencyCodes.join(",")}, \n"
        "}";
  }
}
