import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:flag/flag.dart';

/// Código de bandeira (ISO 3166-1 alpha-2) usado pelo pacote `flag` para cada
/// moeda. A maior parte das moedas usa as duas primeiras letras do próprio
/// código ISO 4217 (ex.: BRL -> BR); o Euro é a exceção, mapeado para a
/// bandeira da União Europeia.
///
/// Usamos imagens de bandeira em vez do emoji Unicode porque a maioria das
/// distribuições Linux não tem fonte com suporte aos glifos de bandeira,
/// mostrando um ícone genérico no lugar.
const Map<Currencies, FlagsCode> _flagCodeByCurrency = {
  Currencies.AUD: FlagsCode.AU,
  Currencies.BRL: FlagsCode.BR,
  Currencies.CAD: FlagsCode.CA,
  Currencies.CZK: FlagsCode.CZ,
  Currencies.DKK: FlagsCode.DK,
  Currencies.EUR: FlagsCode.EU,
  Currencies.GBP: FlagsCode.GB,
  Currencies.HKD: FlagsCode.HK,
  Currencies.IDR: FlagsCode.ID,
  Currencies.ILS: FlagsCode.IL,
  Currencies.INR: FlagsCode.IN,
  Currencies.ISK: FlagsCode.IS,
  Currencies.JPY: FlagsCode.JP,
  Currencies.USD: FlagsCode.US,
  Currencies.PHP: FlagsCode.PH,
  Currencies.HUF: FlagsCode.HU,
  Currencies.RON: FlagsCode.RO,
  Currencies.SEK: FlagsCode.SE,
  Currencies.RUB: FlagsCode.RU,
  Currencies.HRK: FlagsCode.HR,
  Currencies.THB: FlagsCode.TH,
  Currencies.CHF: FlagsCode.CH,
  Currencies.MYR: FlagsCode.MY,
  Currencies.BGN: FlagsCode.BG,
  Currencies.TRY: FlagsCode.TR,
  Currencies.CNY: FlagsCode.CN,
  Currencies.NOK: FlagsCode.NO,
  Currencies.NZD: FlagsCode.NZ,
  Currencies.ZAR: FlagsCode.ZA,
  Currencies.MXN: FlagsCode.MX,
  Currencies.SGD: FlagsCode.SG,
  Currencies.KRW: FlagsCode.KR,
  Currencies.PLN: FlagsCode.PL,
};

/// Código de bandeira correspondente à moeda informada, para uso com o
/// widget `Flag.fromCode` do pacote `flag`.
FlagsCode flagCodeForCurrency(Currencies currency) {
  return _flagCodeByCurrency[currency]!;
}
