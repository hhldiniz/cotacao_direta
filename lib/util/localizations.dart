import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MyAppLocalizations {
  MyAppLocalizations(this.locale);

  final Locale locale;

  static MyAppLocalizations? of(BuildContext context) {
    return Localizations.of<MyAppLocalizations>(context, MyAppLocalizations);
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'conversionButtonLabel': 'Conversions',
      'conversionPageTitle': "Currency Conversion",
      'homePageHeadsUpText': 'The %s today is worth',
      'convertActionBtnLabel': 'Convert',
      'conversionMultiplierHint': 'Amount',
      'conversionPageExplanationText': 'Insert the amount value of the currency '
          'that will be converted, selected a currency to be converted and the '
          'currency that it will be converted to.',
      'mainCurrenciesBottomNavItemLabel': 'Currencies',
      'currencyHistoryBottomNavItemLabel': 'History',
      'configBottomNavItemLabel': 'Options',
      'aboutBottomNavItemLabel': 'About',
      'currencyHistoryFromDateLabel': 'From',
      'currencyHistoryToDateLabel': 'Until',
      'noDataLabel': 'No Data',
      'getCurrencyHistoryBtnLabel': 'Get history',
      'overrideDefaultCurrencySwitchLabel': 'Override default currency',
      'selectedOverrideCurrencyLabel': 'Currency',
      'appConfigurationsSectionLabel': 'App Configurations',
      'aboutAppDescription': 'A simple app that shows the exchange rate of '
          'the main currencies against the Brazilian real.',
      'aboutVersionLabel': 'Version',
      'aboutDeveloperLabel': 'Developed by',
      'aboutSourceCodeLabel': 'Source code',
      'usdCurrencyName': 'US Dollar',
      'eurCurrencyName': 'Euro',
      'cadCurrencyName': 'Canadian Dollar',
      'jpyCurrencyName': 'Japanese Yen',
    },
    'pt': {
      'conversionButtonLabel': "Conversões",
      'conversionPageTitle': "Conversão de Moedas",
      'homePageHeadsUpText': "O %s vale hoje",
      'convertActionBtnLabel': "Converter",
      'conversionMultiplierHint': 'Quantidade',
      'conversionPageExplanationText': 'Insira a quantidade da moeda que será '
          'convertida, selecionada a moeda que será convertida e a moeda para '
          'a qual será feita a conversão.',
      'mainCurrenciesBottomNavItemLabel': 'Moedas',
      'currencyHistoryBottomNavItemLabel': 'Histórico',
      'configBottomNavItemLabel': 'Opções',
      'aboutBottomNavItemLabel': 'Sobre',
      'currencyHistoryFromDateLabel': 'De',
      'currencyHistoryToDateLabel': 'Até',
      'noDataLabel': 'Sem Dados',
      'getCurrencyHistoryBtnLabel': 'Obter histórico',
      'overrideDefaultCurrencySwitchLabel': 'Sobrescrever moeda padrão',
      'selectedOverrideCurrencyLabel': 'Moeda',
      'appConfigurationsSectionLabel': 'Configurações do Aplicativo',
      'aboutAppDescription': 'Um aplicativo simples que mostra a cotação das '
          'principais moedas frente ao real.',
      'aboutVersionLabel': 'Versão',
      'aboutDeveloperLabel': 'Desenvolvido por',
      'aboutSourceCodeLabel': 'Código fonte',
      'usdCurrencyName': 'Dólar americano',
      'eurCurrencyName': 'Euro',
      'cadCurrencyName': 'Dólar canadense',
      'jpyCurrencyName': 'Iene',
    }
  };

  String? get conversionButtonLabel {
    return _localizedValues[locale.languageCode]!['conversionButtonLabel'];
  }

  String? get conversionPageTitle {
    return _localizedValues[locale.languageCode]!['conversionPageTitle'];
  }

  String? get homePageHeadsUpText {
    return _localizedValues[locale.languageCode]!['homePageHeadsUpText'];
  }

  String? get convertActionBtnLabel {
    return _localizedValues[locale.languageCode]!['convertActionBtnLabel'];
  }

  String? get conversionMultiplierHint {
    return _localizedValues[locale.languageCode]!['conversionMultiplierHint'];
  }

  String? get conversionPageExplanationText {
    return _localizedValues[locale.languageCode]!
        ['conversionPageExplanationText'];
  }

  String? get mainCurrenciesBottomNavItemLabel {
    return _localizedValues[locale.languageCode]!
        ['mainCurrenciesBottomNavItemLabel'];
  }

  String? get currencyHistoryBottomNavItemLabel {
    return _localizedValues[locale.languageCode]!
        ['currencyHistoryBottomNavItemLabel'];
  }

  String? get aboutBottomNavItemLabel {
    return _localizedValues[locale.languageCode]!['aboutBottomNavItemLabel'];
  }

  String? get currencyHistoryFromDateLabel {
    return _localizedValues[locale.languageCode]!
        ['currencyHistoryFromDateLabel'];
  }

  String? get currencyHistoryToDateLabel {
    return _localizedValues[locale.languageCode]!['currencyHistoryToDateLabel'];
  }

  String? get noDataLabel {
    return _localizedValues[locale.languageCode]!['noDataLabel'];
  }

  String? get getCurrencyHistoryBtnLabel {
    return _localizedValues[locale.languageCode]!['getCurrencyHistoryBtnLabel'];
  }

  String? get getConfigBottomNavItemLabel {
    return _localizedValues[locale.languageCode]!['configBottomNavItemLabel'];
  }

  String? get overrideDefaultCurrencySwitchLabel {
    return _localizedValues[locale.languageCode]!
        ['overrideDefaultCurrencySwitchLabel'];
  }

  String? get selectedOverrideCurrencyLabel {
    return _localizedValues[locale.languageCode]!
        ['selectedOverrideCurrencyLabel'];
  }

  String? get appConfigurationsSectionLabel {
    return _localizedValues[locale.languageCode]!
        ['appConfigurationsSectionLabel'];
  }

  String? get aboutAppDescription {
    return _localizedValues[locale.languageCode]!['aboutAppDescription'];
  }

  String? get aboutVersionLabel {
    return _localizedValues[locale.languageCode]!['aboutVersionLabel'];
  }

  String? get aboutDeveloperLabel {
    return _localizedValues[locale.languageCode]!['aboutDeveloperLabel'];
  }

  String? get aboutSourceCodeLabel {
    return _localizedValues[locale.languageCode]!['aboutSourceCodeLabel'];
  }

  String? get usdCurrencyName {
    return _localizedValues[locale.languageCode]!['usdCurrencyName'];
  }

  String? get eurCurrencyName {
    return _localizedValues[locale.languageCode]!['eurCurrencyName'];
  }

  String? get cadCurrencyName {
    return _localizedValues[locale.languageCode]!['cadCurrencyName'];
  }

  String? get jpyCurrencyName {
    return _localizedValues[locale.languageCode]!['jpyCurrencyName'];
  }
}

class MyAppLocalizationsDelegate
    extends LocalizationsDelegate<MyAppLocalizations> {
  @override
  bool isSupported(Locale locale) => ["en", "pt"].contains(locale.languageCode);

  @override
  Future<MyAppLocalizations> load(Locale locale) {
    return SynchronousFuture<MyAppLocalizations>(MyAppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<MyAppLocalizations> old) => false;
}
