/// Textos das páginas iniciais do site público, um conjunto por idioma.
///
/// As páginas de cada moeda (`/cotacao/...`) são só em português: são elas que
/// disputam buscas como "cotação do dólar hoje", e o público do app é
/// brasileiro. As iniciais existem nos três idiomas que o app traduz (ver
/// lib/util/localizations.dart), ligadas entre si por `hreflang`.
class SiteStrings {
  /// Código do idioma no `<html lang>` e no `hreflang`.
  final String lang;

  /// Caminho da página inicial deste idioma, relativo à raiz do site.
  final String homePath;

  /// Locale do `og:locale` (com sublinhado, como o Open Graph pede).
  final String ogLocale;

  /// Locale do `intl` para formatar números.
  final String numberLocale;

  final String appName;
  final String title;
  final String description;
  final String headline;
  final String lead;
  final String openApp;
  final String seeRates;
  final String featuresTitle;
  final List<(String, String)> features;
  final String ratesTitle;
  final String currencyHeader;
  final String rateHeader;
  final String changeHeader;
  final String updatedAt;
  final String brasiliaTime;
  final String screenshotsTitle;
  final List<(String, String)> screenshots;
  final String platformsTitle;
  final String platformsText;
  final List<(String, String)> platforms;
  final String sourceCode;
  final String dataSource;
  final String disclaimer;
  final String allRates;
  final String home;
  final String notFoundTitle;
  final String notFoundText;

  const SiteStrings({
    required this.lang,
    required this.homePath,
    required this.ogLocale,
    required this.numberLocale,
    required this.appName,
    required this.title,
    required this.description,
    required this.headline,
    required this.lead,
    required this.openApp,
    required this.seeRates,
    required this.featuresTitle,
    required this.features,
    required this.ratesTitle,
    required this.currencyHeader,
    required this.rateHeader,
    required this.changeHeader,
    required this.updatedAt,
    required this.brasiliaTime,
    required this.screenshotsTitle,
    required this.screenshots,
    required this.platformsTitle,
    required this.platformsText,
    required this.platforms,
    required this.sourceCode,
    required this.dataSource,
    required this.disclaimer,
    required this.allRates,
    required this.home,
    required this.notFoundTitle,
    required this.notFoundText,
  });
}

const stringsPt = SiteStrings(
  lang: 'pt-BR',
  homePath: '',
  ogLocale: 'pt_BR',
  numberLocale: 'pt_BR',
  appName: 'Cotação Direta',
  title: 'Cotação do dólar, euro e bitcoin hoje | Cotação Direta',
  description:
      'Cotação do dólar, euro, libra, bitcoin e mais de 30 moedas frente ao '
      'real. Conversor, histórico, alertas de preço e funciona sem internet. '
      'Grátis.',
  headline: 'Cotação do dólar, euro e outras moedas, direto no seu bolso',
  lead: 'Acompanhe mais de 30 moedas e criptomoedas frente ao real, converta '
      'valores, veja o histórico em gráfico e receba um alerta quando a cotação '
      'chegar onde você quer. Gratuito, sem anúncios e de código aberto.',
  openApp: 'Abrir o app',
  seeRates: 'Ver cotações de hoje',
  featuresTitle: 'O que o Cotação Direta faz',
  features: [
    (
      'Cotações atualizadas',
      'Dólar, euro, libra, iene, bitcoin e mais de 30 moedas frente ao real, '
          'com a variação do dia.'
    ),
    (
      'Conversor de moedas',
      'Converta qualquer valor entre as moedas acompanhadas, com a cotação '
          'mais recente.'
    ),
    (
      'Histórico em gráfico',
      'Veja como cada moeda se comportou nos últimos dias, meses ou anos.'
    ),
    (
      'Alertas de preço',
      'Receba uma notificação quando a moeda passar do valor que você '
          'definiu.'
    ),
    (
      'Tendências calculadas no aparelho',
      'Indicadores e projeções estatísticas feitos localmente, sem enviar '
          'seus dados a ninguém.'
    ),
    (
      'Funciona sem internet',
      'Instale como aplicativo e consulte as últimas cotações mesmo offline.'
    ),
  ],
  ratesTitle: 'Cotações de hoje frente ao real',
  currencyHeader: 'Moeda',
  rateHeader: 'Cotação',
  changeHeader: 'Variação',
  updatedAt: 'Atualizado em',
  brasiliaTime: 'horário de Brasília',
  screenshotsTitle: 'Veja o app',
  screenshots: [
    ('home', 'Tela inicial com as cotações acompanhadas'),
    ('conversion', 'Conversor de moedas'),
    ('history', 'Histórico da cotação em gráfico'),
    ('alerts', 'Alertas de preço'),
  ],
  platformsTitle: 'Onde usar',
  platformsText: 'O mesmo app roda no navegador e nos aparelhos:',
  platforms: [
    ('Navegador', 'Abra agora, sem instalar nada, ou instale como app (PWA).'),
    ('Android', 'APK disponível no GitHub.'),
    ('Linux', 'Pacote Flatpak.'),
    ('Ubuntu Touch', 'Pacote click para a OpenStore.'),
  ],
  sourceCode: 'Código-fonte no GitHub',
  dataSource: 'Dados de cotação: AwesomeAPI',
  disclaimer: 'Valores de referência do câmbio comercial, atualizados a cada '
      'hora. Não servem para fechar operações e não são recomendação de '
      'investimento.',
  allRates: 'Todas as cotações',
  home: 'Início',
  notFoundTitle: 'Página não encontrada',
  notFoundText: 'O endereço que você abriu não existe mais ou nunca existiu.',
);

const stringsEn = SiteStrings(
  lang: 'en',
  homePath: 'en/',
  ogLocale: 'en_US',
  numberLocale: 'en_US',
  appName: 'Direct Quote',
  title: 'Direct Quote — live exchange rates to the Brazilian real',
  description: 'Live rates for the US dollar, euro, bitcoin and 30+ other '
      'currencies against the Brazilian real. Converter, history charts, price '
      'alerts and offline mode. Free.',
  headline: 'Exchange rates against the Brazilian real, at a glance',
  lead: 'Track 30+ currencies and cryptocurrencies against the Brazilian real, '
      'convert amounts, browse historical charts and get an alert when a rate '
      'hits your target. Free, ad-free and open source.',
  openApp: 'Open the app',
  seeRates: "See today's rates",
  featuresTitle: 'What Direct Quote does',
  features: [
    (
      'Up-to-date rates',
      'US dollar, euro, pound, yen, bitcoin and 30+ currencies against the '
          "real, with the day's change."
    ),
    (
      'Currency converter',
      'Convert any amount between the tracked currencies at the latest rate.'
    ),
    (
      'History charts',
      'See how each currency moved over the last days, months or years.'
    ),
    (
      'Price alerts',
      'Get notified when a currency crosses the value you picked.'
    ),
    (
      'On-device trends',
      'Indicators and statistical projections computed locally — your data '
          'never leaves the device.'
    ),
    (
      'Works offline',
      'Install it as an app and check the latest rates without a connection.'
    ),
  ],
  ratesTitle: "Today's rates against the Brazilian real",
  currencyHeader: 'Currency',
  rateHeader: 'Rate',
  changeHeader: 'Change',
  updatedAt: 'Updated',
  brasiliaTime: 'Brasília time',
  screenshotsTitle: 'Screenshots',
  screenshots: [
    ('home', 'Home screen with the tracked rates'),
    ('conversion', 'Currency converter'),
    ('history', 'Rate history chart'),
    ('alerts', 'Price alerts'),
  ],
  platformsTitle: 'Where to use it',
  platformsText: 'The same app runs in the browser and on devices:',
  platforms: [
    ('Browser', 'Open it now, nothing to install, or install it as a PWA.'),
    ('Android', 'APK available on GitHub.'),
    ('Linux', 'Flatpak package.'),
    ('Ubuntu Touch', 'Click package for the OpenStore.'),
  ],
  sourceCode: 'Source code on GitHub',
  dataSource: 'Rate data: AwesomeAPI',
  disclaimer: 'Reference commercial exchange rates, refreshed every hour. Not '
      'suitable for settling transactions and not investment advice.',
  allRates: 'All rates',
  home: 'Home',
  notFoundTitle: 'Page not found',
  notFoundText: 'The address you opened does not exist.',
);

const stringsEs = SiteStrings(
  lang: 'es',
  homePath: 'es/',
  ogLocale: 'es_ES',
  numberLocale: 'es',
  appName: 'Cotización Directa',
  title: 'Cotización Directa — tipo de cambio del real brasileño hoy',
  description: 'Cotización del dólar, euro, bitcoin y más de 30 monedas frente '
      'al real brasileño. Conversor, historial, alertas de precio y funciona '
      'sin internet. Gratis.',
  headline: 'El tipo de cambio frente al real brasileño, en un vistazo',
  lead: 'Sigue más de 30 monedas y criptomonedas frente al real, convierte '
      'importes, consulta el historial en gráficos y recibe una alerta cuando '
      'la cotización llegue a tu objetivo. Gratis, sin anuncios y de código '
      'abierto.',
  openApp: 'Abrir la app',
  seeRates: 'Ver cotizaciones de hoy',
  featuresTitle: 'Qué hace Cotización Directa',
  features: [
    (
      'Cotizaciones actualizadas',
      'Dólar, euro, libra, yen, bitcoin y más de 30 monedas frente al real, '
          'con la variación del día.'
    ),
    (
      'Conversor de monedas',
      'Convierte cualquier importe entre las monedas seguidas con la '
          'cotización más reciente.'
    ),
    (
      'Historial en gráficos',
      'Mira cómo se movió cada moneda en los últimos días, meses o años.'
    ),
    (
      'Alertas de precio',
      'Recibe una notificación cuando la moneda supere el valor que elegiste.'
    ),
    (
      'Tendencias en el dispositivo',
      'Indicadores y proyecciones estadísticas calculados localmente, sin '
          'enviar tus datos a nadie.'
    ),
    (
      'Funciona sin internet',
      'Instálala como app y consulta las últimas cotizaciones sin conexión.'
    ),
  ],
  ratesTitle: 'Cotizaciones de hoy frente al real',
  currencyHeader: 'Moneda',
  rateHeader: 'Cotización',
  changeHeader: 'Variación',
  updatedAt: 'Actualizado el',
  brasiliaTime: 'hora de Brasilia',
  screenshotsTitle: 'Capturas',
  screenshots: [
    ('home', 'Pantalla de inicio con las cotizaciones seguidas'),
    ('conversion', 'Conversor de monedas'),
    ('history', 'Historial de la cotización en gráfico'),
    ('alerts', 'Alertas de precio'),
  ],
  platformsTitle: 'Dónde usarla',
  platformsText: 'La misma app funciona en el navegador y en dispositivos:',
  platforms: [
    ('Navegador', 'Ábrela ahora sin instalar nada, o instálala como PWA.'),
    ('Android', 'APK disponible en GitHub.'),
    ('Linux', 'Paquete Flatpak.'),
    ('Ubuntu Touch', 'Paquete click para la OpenStore.'),
  ],
  sourceCode: 'Código fuente en GitHub',
  dataSource: 'Datos de cotización: AwesomeAPI',
  disclaimer: 'Valores de referencia del cambio comercial, actualizados cada '
      'hora. No sirven para cerrar operaciones y no son recomendación de '
      'inversión.',
  allRates: 'Todas las cotizaciones',
  home: 'Inicio',
  notFoundTitle: 'Página no encontrada',
  notFoundText: 'La dirección que abriste no existe.',
);

const allStrings = [stringsPt, stringsEn, stringsEs];
