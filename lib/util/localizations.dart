
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
      'conversionPageTitle' : "Currency Conversion"
    },

    'pt' : {
      'conversionButtonLabel': "Conversões",
      'conversionPageTitle': "Conversão de Moedas"
    }
  };

  String get conversionButtonLabel{
    return _localizedValues[locale.languageCode]['conversionButtonLabel'];
  }

  String get conversionPageTitle {
    return _localizedValues[locale.languageCode]['conversionPageTitle'];
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