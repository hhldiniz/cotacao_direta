
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MyAppLocalizations{
  MyAppLocalizations(this.locale);

  final Locale locale;

  static MyAppLocalizations of(BuildContext context){
    return Localizations.of<MyAppLocalizations>(context, MyAppLocalizations);
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'conversionButtonLabel': 'Conversions',
      'conversionPageTitle' : "Currency Conversion",
      'homePageHeadsUpText': 'The Real today is worth',
      'convertActionBtnLabel': 'Convert',
      'conversionMultiplierHint': 'Amount',
      'conversionPageExplanationText': 'Insert the amount value of the currency '
          'that will be converted, selected a currency to be converted and the '
          'currency that it will be converted to.'
    },

    'pt' : {
      'conversionButtonLabel': "Conversões",
      'conversionPageTitle': "Conversão de Moedas",
      'homePageHeadsUpText': "O Real vale hoje",
      'convertActionBtnLabel': "Converter",
      'conversionMultiplierHint': 'Quantidade',
      'conversionPageExplanationText': 'Insira a quantidade da moeda que será '
          'convertida, selecionada a moeda que será convertida e a moeda para '
          'a qual será feita a conversão.'
    }
  };

  String get conversionButtonLabel{
    return _localizedValues[locale.languageCode]['conversionButtonLabel'];
  }

  String get conversionPageTitle {
    return _localizedValues[locale.languageCode]['conversionPageTitle'];
  }

  String get homePageHeadsUpText {
    return _localizedValues[locale.languageCode]['homePageHeadsUpText'];
  }

  String get convertActionBtnLabel {
    return _localizedValues[locale.languageCode]['convertActionBtnLabel'];
  }

  String get conversionMultiplierHint {
    return _localizedValues[locale.languageCode]['conversionMultiplierHint'];
  }

}

class MyAppLocalizationsDelegate extends LocalizationsDelegate<MyAppLocalizations>{
  @override
  bool isSupported(Locale locale) => ["en", "pt"].contains(locale.languageCode);

  @override
  Future<MyAppLocalizations> load(Locale locale) {
    return SynchronousFuture<MyAppLocalizations>(MyAppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<MyAppLocalizations> old) => false;

}