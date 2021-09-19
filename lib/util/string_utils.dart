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
