import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:flutter/widgets.dart';

/// Nome de cada moeda nos idiomas que o aplicativo fala.
///
/// A tela de conversão mostra o nome junto do código para que o usuário não
/// precise decorar siglas ("HUF" não diz muito; "Florim Húngaro" sim) e para
/// que a busca do seletor funcione por nome.
///
/// Os nomes ficam aqui, e não na REST Countries usada pelo histórico, porque o
/// seletor precisa deles de imediato e offline: uma consulta por moeda seria
/// uma lista em branco enquanto a rede não responde — e nenhum nome quando ela
/// não responde.
const Map<Currencies, Map<String, String>> _namesByCurrency = {
  Currencies.AUD: {"pt": "Dólar Australiano", "en": "Australian Dollar"},
  Currencies.BRL: {"pt": "Real Brasileiro", "en": "Brazilian Real"},
  Currencies.CAD: {"pt": "Dólar Canadense", "en": "Canadian Dollar"},
  Currencies.CZK: {"pt": "Coroa Tcheca", "en": "Czech Koruna"},
  Currencies.DKK: {"pt": "Coroa Dinamarquesa", "en": "Danish Krone"},
  Currencies.EUR: {"pt": "Euro", "en": "Euro"},
  Currencies.GBP: {"pt": "Libra Esterlina", "en": "British Pound"},
  Currencies.HKD: {"pt": "Dólar de Hong Kong", "en": "Hong Kong Dollar"},
  Currencies.IDR: {"pt": "Rupia Indonésia", "en": "Indonesian Rupiah"},
  Currencies.ILS: {"pt": "Novo Shekel Israelense", "en": "Israeli New Shekel"},
  Currencies.INR: {"pt": "Rupia Indiana", "en": "Indian Rupee"},
  Currencies.ISK: {"pt": "Coroa Islandesa", "en": "Icelandic Króna"},
  Currencies.JPY: {"pt": "Iene Japonês", "en": "Japanese Yen"},
  Currencies.USD: {"pt": "Dólar Americano", "en": "US Dollar"},
  Currencies.PHP: {"pt": "Peso Filipino", "en": "Philippine Peso"},
  Currencies.HUF: {"pt": "Florim Húngaro", "en": "Hungarian Forint"},
  Currencies.RON: {"pt": "Leu Romeno", "en": "Romanian Leu"},
  Currencies.SEK: {"pt": "Coroa Sueca", "en": "Swedish Krona"},
  Currencies.RUB: {"pt": "Rublo Russo", "en": "Russian Ruble"},
  Currencies.HRK: {"pt": "Kuna Croata", "en": "Croatian Kuna"},
  Currencies.THB: {"pt": "Baht Tailandês", "en": "Thai Baht"},
  Currencies.CHF: {"pt": "Franco Suíço", "en": "Swiss Franc"},
  Currencies.MYR: {"pt": "Ringgit Malaio", "en": "Malaysian Ringgit"},
  Currencies.BGN: {"pt": "Lev Búlgaro", "en": "Bulgarian Lev"},
  Currencies.TRY: {"pt": "Lira Turca", "en": "Turkish Lira"},
  Currencies.CNY: {"pt": "Yuan Chinês", "en": "Chinese Yuan"},
  Currencies.NOK: {"pt": "Coroa Norueguesa", "en": "Norwegian Krone"},
  Currencies.NZD: {"pt": "Dólar Neozelandês", "en": "New Zealand Dollar"},
  Currencies.ZAR: {"pt": "Rand Sul-Africano", "en": "South African Rand"},
  Currencies.MXN: {"pt": "Peso Mexicano", "en": "Mexican Peso"},
  Currencies.SGD: {"pt": "Dólar de Singapura", "en": "Singapore Dollar"},
  Currencies.KRW: {"pt": "Won Sul-Coreano", "en": "South Korean Won"},
  Currencies.PLN: {"pt": "Zloty Polonês", "en": "Polish Zloty"},
};

/// Nome da moeda no idioma de [locale], com o inglês como reserva para um
/// idioma que ainda não tenha tradução.
String currencyName(Currencies currency, Locale locale) {
  var names = _namesByCurrency[currency];
  if (names == null) return currencyCode(currency);
  return names[locale.languageCode] ?? names["en"] ?? currencyCode(currency);
}

/// Código ISO 4217 da moeda, que é o próprio nome do valor do enum.
String currencyCode(Currencies currency) => currency.name;

/// Moeda correspondente a um código ISO 4217, ou nulo para um código que o app
/// não conhece.
Currencies? currencyForCode(String? code) {
  if (code == null || code.isEmpty) return null;
  var upperCaseCode = code.toUpperCase();
  for (var currency in Currencies.values) {
    if (currency.name == upperCaseCode) return currency;
  }
  return null;
}

/// Nome da moeda de [code] no idioma de [locale]. Um código desconhecido fica
/// com o próprio código como nome: é o que o app tem para mostrar, e ainda
/// identifica a moeda.
String currencyNameForCode(String? code, Locale locale) {
  var currency = currencyForCode(code);
  return currency == null ? (code ?? "") : currencyName(currency, locale);
}
