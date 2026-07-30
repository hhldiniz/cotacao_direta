import 'package:cotacao_direta/enums/cryptocurrency_enum.dart';
import 'package:flutter/material.dart';

/// Nome de cada criptomoeda, para o subtítulo da linha na listagem de
/// histórico.
///
/// Vem de um mapa local, e não da REST Countries usada pelas moedas
/// fiduciárias: criptomoeda não pertence a país nenhum, e a consulta por código
/// devolveria um erro no lugar do nome.
const Map<Cryptocurrencies, String> _nameByCryptocurrency = {
  Cryptocurrencies.BTC: "Bitcoin",
  Cryptocurrencies.ETH: "Ethereum",
  Cryptocurrencies.USDT: "Tether",
  Cryptocurrencies.XRP: "Ripple",
  Cryptocurrencies.BNB: "Binance Coin",
  Cryptocurrencies.SOL: "Solana",
  Cryptocurrencies.ADA: "Cardano",
  Cryptocurrencies.DOGE: "Dogecoin",
};

/// Nome da criptomoeda informada.
String cryptocurrencyName(Cryptocurrencies cryptocurrency) =>
    _nameByCryptocurrency[cryptocurrency]!;

/// Ícone que ocupa, na linha da criptomoeda, o lugar da bandeira das moedas
/// fiduciárias. O pacote `flag` só tem bandeiras de país e o Material Icons só
/// traz o glifo do bitcoin, então as demais ficam com o ícone genérico de
/// token.
IconData iconForCryptocurrency(Cryptocurrencies cryptocurrency) =>
    cryptocurrency == Cryptocurrencies.BTC
        ? Icons.currency_bitcoin
        : Icons.token;
