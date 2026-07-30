/// Acentos e cedilha, com a letra sem acento correspondente.
const Map<String, String> _unaccentedCharacters = {
  "á": "a", "à": "a", "ã": "a", "â": "a", "ä": "a", "å": "a",
  "é": "e", "è": "e", "ê": "e", "ë": "e",
  "í": "i", "ì": "i", "î": "i", "ï": "i",
  "ó": "o", "ò": "o", "õ": "o", "ô": "o", "ö": "o",
  "ú": "u", "ù": "u", "û": "u", "ü": "u",
  "ç": "c", "ñ": "n", "ý": "y",
};

/// Texto em minúsculas e sem acentos, para comparar o que o usuário digitou
/// com um nome acentuado: quem procura "franco suico" espera achar o "Franco
/// Suíço", e ninguém digita acento em campo de busca.
String withoutAccents(String value) {
  var lowerCase = value.toLowerCase();
  var buffer = StringBuffer();
  for (var character in lowerCase.split("")) {
    buffer.write(_unaccentedCharacters[character] ?? character);
  }
  return buffer.toString();
}

class EnumValueAsString {
  static EnumValueAsString? _instance;

  factory EnumValueAsString() {
    if (_instance == null) _instance = EnumValueAsString._internalConstructor();
    return _instance!;
  }

  EnumValueAsString._internalConstructor();

  String getEnumValue(String enumValue) {
    return enumValue
        .toString()
        .substring(enumValue.toString().indexOf('.') + 1);
  }
}
