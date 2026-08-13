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
  Currencies.AUD: {
    "pt": "Dólar Australiano",
    "en": "Australian Dollar",
    "es": "Dólar australiano"
  },
  Currencies.BRL: {
    "pt": "Real Brasileiro",
    "en": "Brazilian Real",
    "es": "Real brasileño"
  },
  Currencies.CAD: {
    "pt": "Dólar Canadense",
    "en": "Canadian Dollar",
    "es": "Dólar canadiense"
  },
  Currencies.CZK: {
    "pt": "Coroa Tcheca",
    "en": "Czech Koruna",
    "es": "Corona checa"
  },
  Currencies.DKK: {
    "pt": "Coroa Dinamarquesa",
    "en": "Danish Krone",
    "es": "Corona danesa"
  },
  Currencies.EUR: {"pt": "Euro", "en": "Euro", "es": "Euro"},
  Currencies.GBP: {
    "pt": "Libra Esterlina",
    "en": "British Pound",
    "es": "Libra esterlina"
  },
  Currencies.HKD: {
    "pt": "Dólar de Hong Kong",
    "en": "Hong Kong Dollar",
    "es": "Dólar de Hong Kong"
  },
  Currencies.IDR: {
    "pt": "Rupia Indonésia",
    "en": "Indonesian Rupiah",
    "es": "Rupia indonesia"
  },
  Currencies.ILS: {
    "pt": "Novo Shekel Israelense",
    "en": "Israeli New Shekel",
    "es": "Nuevo séquel israelí"
  },
  Currencies.INR: {
    "pt": "Rupia Indiana",
    "en": "Indian Rupee",
    "es": "Rupia india"
  },
  Currencies.ISK: {
    "pt": "Coroa Islandesa",
    "en": "Icelandic Króna",
    "es": "Corona islandesa"
  },
  Currencies.JPY: {
    "pt": "Iene Japonês",
    "en": "Japanese Yen",
    "es": "Yen japonés"
  },
  Currencies.USD: {
    "pt": "Dólar Americano",
    "en": "US Dollar",
    "es": "Dólar estadounidense"
  },
  Currencies.PHP: {
    "pt": "Peso Filipino",
    "en": "Philippine Peso",
    "es": "Peso filipino"
  },
  Currencies.HUF: {
    "pt": "Florim Húngaro",
    "en": "Hungarian Forint",
    "es": "Forinto húngaro"
  },
  Currencies.RON: {
    "pt": "Leu Romeno",
    "en": "Romanian Leu",
    "es": "Leu rumano"
  },
  Currencies.SEK: {
    "pt": "Coroa Sueca",
    "en": "Swedish Krona",
    "es": "Corona sueca"
  },
  Currencies.RUB: {
    "pt": "Rublo Russo",
    "en": "Russian Ruble",
    "es": "Rublo ruso"
  },
  Currencies.HRK: {
    "pt": "Kuna Croata",
    "en": "Croatian Kuna",
    "es": "Kuna croata"
  },
  Currencies.THB: {
    "pt": "Baht Tailandês",
    "en": "Thai Baht",
    "es": "Baht tailandés"
  },
  Currencies.CHF: {
    "pt": "Franco Suíço",
    "en": "Swiss Franc",
    "es": "Franco suizo"
  },
  Currencies.MYR: {
    "pt": "Ringgit Malaio",
    "en": "Malaysian Ringgit",
    "es": "Ringgit malayo"
  },
  Currencies.BGN: {
    "pt": "Lev Búlgaro",
    "en": "Bulgarian Lev",
    "es": "Lev búlgaro"
  },
  Currencies.TRY: {
    "pt": "Lira Turca",
    "en": "Turkish Lira",
    "es": "Lira turca"
  },
  Currencies.CNY: {
    "pt": "Yuan Chinês",
    "en": "Chinese Yuan",
    "es": "Yuan chino"
  },
  Currencies.NOK: {
    "pt": "Coroa Norueguesa",
    "en": "Norwegian Krone",
    "es": "Corona noruega"
  },
  Currencies.NZD: {
    "pt": "Dólar Neozelandês",
    "en": "New Zealand Dollar",
    "es": "Dólar neozelandés"
  },
  Currencies.ZAR: {
    "pt": "Rand Sul-Africano",
    "en": "South African Rand",
    "es": "Rand sudafricano"
  },
  Currencies.MXN: {
    "pt": "Peso Mexicano",
    "en": "Mexican Peso",
    "es": "Peso mexicano"
  },
  Currencies.SGD: {
    "pt": "Dólar de Singapura",
    "en": "Singapore Dollar",
    "es": "Dólar de Singapur"
  },
  Currencies.KRW: {
    "pt": "Won Sul-Coreano",
    "en": "South Korean Won",
    "es": "Won surcoreano"
  },
  Currencies.PLN: {
    "pt": "Zloty Polonês",
    "en": "Polish Zloty",
    "es": "Esloti polaco"
  },
};

/// Nome da moeda no idioma de [locale], com o inglês como reserva para um
/// idioma que ainda não tenha tradução.
///
/// A busca é pelo código do idioma, sem a região: o nome de uma moeda é o
/// mesmo nas duas normas do espanhol que o app fala.
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
