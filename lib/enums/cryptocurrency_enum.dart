/// Criptomoedas acompanhadas na listagem de histórico: as mais negociadas.
///
/// Ficam fora de [Currencies] de propósito. Aquele enum alimenta também a
/// conversão, os alertas e a escolha da moeda padrão nas configurações, que
/// tratam de moeda fiduciária; aqui interessa apenas a lista de histórico.
///
/// A AwesomeAPI cota criptomoeda no mesmo formato das demais moedas
/// (`/json/daily/BTC-BRL/...`), então o repositório e o gráfico funcionam sem
/// alteração. Um código que a API não cotar apenas aparece como "Sem Dados" no
/// gráfico, sem quebrar a tela.
enum Cryptocurrencies { BTC, ETH, USDT, XRP, BNB, SOL, ADA, DOGE }
