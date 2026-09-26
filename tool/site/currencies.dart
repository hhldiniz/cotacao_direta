/// Moedas que ganham página própria no site público (`/cotacao/<slug>/`).
///
/// São as mais buscadas frente ao real. A lista fica separada dos enums do app
/// ([Currencies], [Cryptocurrencies]) porque aqui cada moeda precisa de mais do
/// que o código: o endereço da página e o nome, com artigo e gênero, que entra
/// nos títulos ("Cotação *do* dólar", "Cotação *da* libra").
class SiteCurrency {
  /// Código na AwesomeAPI (USD, EUR, BTC...).
  final String code;

  /// Trecho do endereço da página, em português e sem acento: é o que as
  /// pessoas digitam na busca ("cotação dolar").
  final String slug;

  /// Nome em minúsculas, para o meio da frase: "dólar americano".
  final String namePt;

  /// Nome curto, o que as pessoas buscam: "dólar", "euro", "libra".
  final String shortNamePt;

  /// Contração de "de" com o artigo do nome curto: "do" ou "da".
  final String ofPt;

  final String nameEn;
  final String nameEs;

  /// Símbolo usado nas tabelas de conversão (US$, €, £...).
  final String symbol;

  final bool isCrypto;

  const SiteCurrency({
    required this.code,
    required this.slug,
    required this.namePt,
    required this.shortNamePt,
    required this.ofPt,
    required this.nameEn,
    required this.nameEs,
    required this.symbol,
    this.isCrypto = false,
  });
}

const siteCurrencies = <SiteCurrency>[
  SiteCurrency(
      code: 'USD',
      slug: 'dolar',
      namePt: 'dólar americano',
      shortNamePt: 'dólar',
      ofPt: 'do',
      nameEn: 'US dollar',
      nameEs: 'dólar estadounidense',
      symbol: 'US\$'),
  SiteCurrency(
      code: 'EUR',
      slug: 'euro',
      namePt: 'euro',
      shortNamePt: 'euro',
      ofPt: 'do',
      nameEn: 'Euro',
      nameEs: 'euro',
      symbol: '€'),
  SiteCurrency(
      code: 'GBP',
      slug: 'libra',
      namePt: 'libra esterlina',
      shortNamePt: 'libra',
      ofPt: 'da',
      nameEn: 'British pound',
      nameEs: 'libra esterlina',
      symbol: '£'),
  SiteCurrency(
      code: 'CAD',
      slug: 'dolar-canadense',
      namePt: 'dólar canadense',
      shortNamePt: 'dólar canadense',
      ofPt: 'do',
      nameEn: 'Canadian dollar',
      nameEs: 'dólar canadiense',
      symbol: 'C\$'),
  SiteCurrency(
      code: 'AUD',
      slug: 'dolar-australiano',
      namePt: 'dólar australiano',
      shortNamePt: 'dólar australiano',
      ofPt: 'do',
      nameEn: 'Australian dollar',
      nameEs: 'dólar australiano',
      symbol: 'A\$'),
  SiteCurrency(
      code: 'JPY',
      slug: 'iene',
      namePt: 'iene japonês',
      shortNamePt: 'iene',
      ofPt: 'do',
      nameEn: 'Japanese yen',
      nameEs: 'yen japonés',
      symbol: '¥'),
  SiteCurrency(
      code: 'CHF',
      slug: 'franco-suico',
      namePt: 'franco suíço',
      shortNamePt: 'franco suíço',
      ofPt: 'do',
      nameEn: 'Swiss franc',
      nameEs: 'franco suizo',
      symbol: 'CHF'),
  SiteCurrency(
      code: 'CNY',
      slug: 'yuan',
      namePt: 'yuan chinês',
      shortNamePt: 'yuan',
      ofPt: 'do',
      nameEn: 'Chinese yuan',
      nameEs: 'yuan chino',
      symbol: '¥'),
  SiteCurrency(
      code: 'BTC',
      slug: 'bitcoin',
      namePt: 'bitcoin',
      shortNamePt: 'bitcoin',
      ofPt: 'do',
      nameEn: 'Bitcoin',
      nameEs: 'bitcoin',
      symbol: '₿',
      isCrypto: true),
  SiteCurrency(
      code: 'ETH',
      slug: 'ethereum',
      namePt: 'ethereum',
      shortNamePt: 'ethereum',
      ofPt: 'do',
      nameEn: 'Ethereum',
      nameEs: 'ethereum',
      symbol: 'ETH',
      isCrypto: true),
];
