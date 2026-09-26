import 'dart:convert';

import 'package:intl/intl.dart';

import 'awesome_api.dart';
import 'currencies.dart';
import 'site_strings.dart';

/// Onde o site é publicado e o que muda de uma publicação para outra.
class SiteConfig {
  /// Endereço absoluto da raiz do site, terminado em `/`
  /// (https://hhldiniz.github.io/cotacao_direta/). Entra no `canonical`, no
  /// Open Graph e no sitemap, que exigem endereços completos.
  final Uri siteUrl;

  /// Conteúdo da meta `google-site-verification` do Search Console, se houver.
  final String? googleSiteVerification;

  /// Conteúdo da meta `msvalidate.01` do Bing Webmaster Tools, se houver.
  final String? bingSiteVerification;

  SiteConfig(
      {required Uri siteUrl,
      this.googleSiteVerification,
      this.bingSiteVerification})
      : siteUrl = siteUrl.path.endsWith('/')
            ? siteUrl
            : siteUrl.replace(path: '${siteUrl.path}/');
}

/// As cotações que o site mostra, buscadas uma vez por build.
class SiteData {
  final DateTime generatedAt;

  /// Última cotação por código (USD, EUR...).
  final Map<String, Quote> quotes;

  /// Fechamentos diários por código, do mais antigo para o mais novo. Uma
  /// moeda sem histórico só perde o gráfico e a tabela da página dela.
  final Map<String, List<DailyClose>> history;

  const SiteData(
      {required this.generatedAt, required this.quotes, required this.history});
}

/// Pasta, relativa à raiz do site, em que o app Flutter é publicado.
const appPath = 'app/';

/// Pasta das páginas de cada moeda.
const ratesPath = 'cotacao/';

/// Monta todos os arquivos de texto do site: caminho relativo à raiz → conteúdo.
///
/// Os arquivos binários (ícones, capturas de tela, imagem do Open Graph) e o
/// app Flutter em [appPath] ficam a cargo de quem chama; ver
/// tool/build_site.dart.
Map<String, String> buildSite(SiteConfig config, SiteData data) {
  for (var currency in siteCurrencies) {
    if (!data.quotes.containsKey(currency.code))
      throw ArgumentError('Sem cotação para ${currency.code}');
  }
  var builder = _SiteBuilder(config, data);
  var files = <String, String>{};
  for (var strings in allStrings) {
    files['${strings.homePath}index.html'] = builder.home(strings);
  }
  files['${ratesPath}index.html'] = builder.ratesIndex();
  for (var currency in siteCurrencies) {
    files['${_currencyPath(currency)}index.html'] = builder.currency(currency);
  }
  files['404.html'] = builder.notFound();
  files['sitemap.xml'] = builder.sitemap();
  files['robots.txt'] = builder.robots();
  return files;
}

String _currencyPath(SiteCurrency currency) => '$ratesPath${currency.slug}/';

class _SiteBuilder {
  final SiteConfig config;
  final SiteData data;

  _SiteBuilder(this.config, this.data);

  String _absolute(String path) => config.siteUrl.resolve(path).toString();

  /// Todas as páginas que entram no sitemap.
  List<String> get _indexablePaths => [
        for (var strings in allStrings) strings.homePath,
        ratesPath,
        for (var currency in siteCurrencies) _currencyPath(currency),
      ];

  // ---------------------------------------------------------------------------
  // Páginas

  String home(SiteStrings s) {
    var isPt = s == stringsPt;
    var body = StringBuffer()
      ..write('<section class="hero"><div class="wrap">')
      ..write('<h1>${_e(s.headline)}</h1>')
      ..write('<p class="lead">${_e(s.lead)}</p>')
      ..write('<p class="actions">')
      ..write('<a class="button" href="{{root}}$appPath">${_e(s.openApp)}</a>')
      ..write(
          '<a class="button secondary" href="#cotacoes">${_e(s.seeRates)}</a>')
      ..write('</p></div></section>')
      ..write('<section class="wrap" id="cotacoes">')
      ..write('<h2>${_e(s.ratesTitle)}</h2>')
      ..write(_ratesTable(s, linkToPages: isPt))
      ..write(_updatedAt(s, _latestQuoteTime))
      ..write(isPt
          ? '<p><a href="{{root}}$ratesPath">${_e(s.allRates)} →</a></p>'
          : '')
      ..write('</section>')
      ..write('<section class="wrap"><h2>${_e(s.featuresTitle)}</h2>')
      ..write('<ul class="features">');
    for (var (title, text) in s.features) {
      body.write('<li><h3>${_e(title)}</h3><p>${_e(text)}</p></li>');
    }
    body
      ..write('</ul></section>')
      ..write('<section class="wrap"><h2>${_e(s.screenshotsTitle)}</h2>')
      ..write('<div class="shots">');
    for (var (file, alt) in s.screenshots) {
      body.write('<figure><img src="{{root}}screenshots/$file.png" '
          'alt="${_e(alt)}" width="1279" height="720" loading="lazy">'
          '<figcaption>${_e(alt)}</figcaption></figure>');
    }
    body
      ..write('</div></section>')
      ..write('<section class="wrap"><h2>${_e(s.platformsTitle)}</h2>')
      ..write('<p>${_e(s.platformsText)}</p><ul class="platforms">');
    for (var (name, text) in s.platforms) {
      body.write('<li><strong>${_e(name)}</strong> — ${_e(text)}</li>');
    }
    body
      ..write('</ul><p class="actions">')
      ..write('<a class="button" href="{{root}}$appPath">${_e(s.openApp)}</a>')
      ..write('<a class="button secondary" href="$_repoUrl">'
          '${_e(s.sourceCode)}</a></p></section>');

    return _page(
      strings: s,
      path: s.homePath,
      title: s.title,
      description: s.description,
      body: body.toString(),
      alternates: {for (var other in allStrings) other.lang: other.homePath},
      isRoot: isPt,
      jsonLd: [
        {
          '@context': 'https://schema.org',
          '@type': 'WebApplication',
          'name': s.appName,
          'alternateName': [
            for (var other in allStrings)
              if (other != s) other.appName
          ],
          'url': _absolute(s.homePath),
          'description': s.description,
          'inLanguage': s.lang,
          'applicationCategory': 'FinanceApplication',
          'operatingSystem': 'Web, Android, Linux, Ubuntu Touch',
          'browserRequirements': 'Requires JavaScript and WebAssembly',
          'isAccessibleForFree': true,
          'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'BRL'},
          'image': _absolute('og-image.png'),
          'screenshot': [
            for (var (file, _) in s.screenshots)
              _absolute('screenshots/$file.png')
          ],
          'installUrl': _absolute(appPath),
          'codeRepository': _repoUrl,
        },
      ],
    );
  }

  String ratesIndex() {
    var s = stringsPt;
    var body = StringBuffer()
      ..write('<div class="wrap">')
      ..write(_breadcrumb([(s.home, ''), ('Cotações', ratesPath)]))
      ..write('<h1>Cotações de hoje frente ao real</h1>')
      ..write('<p class="lead">Quanto vale hoje o dólar, o euro, a libra, o '
          'bitcoin e outras moedas em reais. Toque em uma moeda para ver a '
          'conversão, o histórico dos últimos 30 dias e o gráfico.</p>')
      ..write(_ratesTable(s, linkToPages: true))
      ..write(_updatedAt(s, _latestQuoteTime))
      ..write(_appCallout('Quer acompanhar em tempo real?',
          'No app você escolhe as moedas, converte valores, vê o histórico '
              'completo e cria alertas de preço.'))
      ..write('</div>');
    return _page(
      strings: s,
      path: ratesPath,
      title: 'Cotações de hoje: dólar, euro, libra e bitcoin | Cotação Direta',
      description: 'Cotação de hoje do dólar, euro, libra, iene, bitcoin e '
          'outras moedas frente ao real, com variação do dia e histórico. '
          'Atualizado a cada hora.',
      body: body.toString(),
      jsonLd: [
        _breadcrumbJsonLd([(s.home, ''), ('Cotações', ratesPath)])
      ],
    );
  }

  String currency(SiteCurrency c) {
    var s = stringsPt;
    var quote = data.quotes[c.code]!;
    var history = data.history[c.code] ?? const <DailyClose>[];
    var path = _currencyPath(c);
    var name = c.shortNamePt;
    var capitalized = _capitalize(name);
    var crumbs = [(s.home, ''), ('Cotações', ratesPath), (capitalized, path)];

    var body = StringBuffer()
      ..write('<div class="wrap">')
      ..write(_breadcrumb(crumbs))
      ..write('<h1>Cotação ${c.ofPt} $name hoje</h1>')
      ..write('<div class="quote">')
      ..write('<p class="quote-main">1 ${_e(c.namePt)} (${c.code}) = '
          '<strong>${_brl(quote.bid, s)}</strong></p>');
    if (quote.pctChange != null) {
      body.write('<p>${_change(quote.pctChange!, s)} em relação ao '
          'fechamento anterior</p>');
    }
    if (quote.high != null && quote.low != null) {
      body.write('<p class="muted">Máxima do dia: ${_brl(quote.high!, s)} · '
          'Mínima do dia: ${_brl(quote.low!, s)}</p>');
    }
    body
      ..write(_updatedAt(s, quote.time))
      ..write('</div>');

    if (history.length >= 2) {
      var first = history.first;
      var last = history.last;
      var min = history.map((d) => d.bid).reduce((a, b) => a < b ? a : b);
      var max = history.map((d) => d.bid).reduce((a, b) => a > b ? a : b);
      var periodChange = (last.bid - first.bid) / first.bid * 100;
      body
        ..write('<h2>${_capitalize(name)} nos últimos ${history.length} '
            'dias</h2>')
        ..write(_sparkline(history,
            'Gráfico da cotação ${c.ofPt} $name nos últimos '
            '${history.length} dias'))
        ..write('<p>Entre ${_date(first.time)} e ${_date(last.time)}, o $name '
            'oscilou entre <strong>${_brl(min, s)}</strong> e '
            '<strong>${_brl(max, s)}</strong>, uma variação de '
            '${_change(periodChange, s)} no período.</p>');
    }

    body
      ..write(_appCallout('Acompanhe o $name em tempo real',
          'Crie um alerta e receba uma notificação quando o $name chegar ao '
              'valor que você quer. Grátis, no navegador ou no celular.'))
      ..write('<h2>Conversão de ${_e(c.namePt)} para real</h2>')
      ..write(_conversionTables(c, quote.bid, s));

    if (history.length >= 2) {
      body
        ..write('<h2>Histórico da cotação ${c.ofPt} $name</h2>')
        ..write('<table><thead><tr><th>Data</th><th>Cotação</th>'
            '<th>Variação</th></tr></thead><tbody>');
      for (var day in history.reversed.take(10)) {
        body.write('<tr><td>${_date(day.time)}</td>'
            '<td>${_brl(day.bid, s)}</td>'
            '<td>${day.pctChange == null ? '—' : _change(day.pctChange!, s)}'
            '</td></tr>');
      }
      body.write('</tbody></table>');
    }

    body
      ..write('<h2>Sobre a cotação ${c.ofPt} $name</h2>')
      ..write(c.isCrypto ? _aboutCrypto(c) : _aboutFiat(c))
      ..write('<h2>Outras cotações</h2><ul class="links">');
    for (var other in siteCurrencies) {
      if (other == c) continue;
      body.write('<li><a href="{{root}}${_currencyPath(other)}">'
          'Cotação ${other.ofPt} ${other.shortNamePt}</a></li>');
    }
    body.write('</ul></div>');

    var bid = _brl(quote.bid, s);
    return _page(
      strings: s,
      path: path,
      title: 'Cotação ${c.ofPt} $name hoje (${c.code}/BRL): $bid | '
          'Cotação Direta',
      description: 'Cotação ${c.ofPt} ${c.namePt} hoje: 1 ${c.code} = $bid. '
          'Veja a variação do dia, o histórico dos últimos 30 dias, a '
          'conversão para real e crie alertas de preço.',
      body: body.toString(),
      jsonLd: [_breadcrumbJsonLd(crumbs)],
    );
  }

  String notFound() {
    var s = stringsPt;
    var body = '<div class="wrap"><h1>${_e(s.notFoundTitle)}</h1>'
        '<p>${_e(s.notFoundText)}</p><p class="actions">'
        '<a class="button" href="{{root}}$appPath">${_e(s.openApp)}</a>'
        '<a class="button secondary" href="{{root}}$ratesPath">'
        '${_e(s.allRates)}</a></p></div>';
    // O GitHub Pages serve esta página em qualquer endereço inexistente, a
    // qualquer profundidade: os links vão absolutos, e ela não é indexada.
    return _page(
      strings: s,
      path: null,
      root: config.siteUrl.toString(),
      title: '${s.notFoundTitle} | ${s.appName}',
      description: s.description,
      body: body,
    );
  }

  String sitemap() {
    var lastmod = _isoDate(data.generatedAt);
    var buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
    for (var path in _indexablePaths) {
      buffer.writeln('  <url><loc>${_e(_absolute(path))}</loc>'
          '<lastmod>$lastmod</lastmod></url>');
    }
    buffer.writeln('</urlset>');
    return buffer.toString();
  }

  /// Os buscadores só leem o robots.txt na raiz do domínio. Publicado num
  /// subcaminho (o GitHub Pages de projeto), ele é ignorado; vale a partir do
  /// dia em que o site tiver domínio próprio. O sitemap, enquanto isso, é
  /// enviado à mão no Search Console — ver o README.
  String robots() => 'User-agent: *\n'
      'Allow: /\n'
      '\n'
      'Sitemap: ${_absolute('sitemap.xml')}\n';

  // ---------------------------------------------------------------------------
  // Pedaços das páginas

  DateTime get _latestQuoteTime => data.quotes.values
      .map((q) => q.time)
      .reduce((a, b) => a.isAfter(b) ? a : b);

  String _ratesTable(SiteStrings s, {required bool linkToPages}) {
    var buffer = StringBuffer()
      ..write('<table class="rates"><thead><tr>'
          '<th>${_e(s.currencyHeader)}</th><th>${_e(s.rateHeader)}</th>'
          '<th>${_e(s.changeHeader)}</th></tr></thead><tbody>');
    for (var c in siteCurrencies) {
      var quote = data.quotes[c.code]!;
      var name = _e(_capitalize(_nameFor(c, s)));
      var label = linkToPages
          ? '<a href="{{root}}${_currencyPath(c)}">$name</a>'
          : name;
      buffer.write('<tr><td>$label <span class="code">${c.code}</span></td>'
          '<td>${_brl(quote.bid, s)}</td>'
          '<td>${quote.pctChange == null ? '—' : _change(quote.pctChange!, s)}'
          '</td></tr>');
    }
    buffer.write('</tbody></table>');
    return buffer.toString();
  }

  String _nameFor(SiteCurrency c, SiteStrings s) => switch (s.lang) {
        'en' => c.nameEn,
        'es' => c.nameEs,
        _ => c.namePt,
      };

  String _updatedAt(SiteStrings s, DateTime time) =>
      '<p class="muted">${_e(s.updatedAt)} '
      '<time datetime="${time.toUtc().toIso8601String()}">'
      '${_dateTime(time, s)}</time> (${_e(s.brasiliaTime)})</p>';

  String _appCallout(String title, String text) =>
      '<aside class="callout"><div><h2>${_e(title)}</h2><p>${_e(text)}</p>'
      '</div><a class="button" href="{{root}}$appPath">'
      '${_e(stringsPt.openApp)}</a></aside>';

  String _conversionTables(SiteCurrency c, double bid, SiteStrings s) {
    var toBrl = c.isCrypto
        ? const [0.0001, 0.001, 0.01, 0.1, 0.5, 1.0]
        : const [1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0];
    var fromBrl = c.isCrypto
        ? const [50.0, 100.0, 500.0, 1000.0, 5000.0, 10000.0]
        : const [1.0, 10.0, 50.0, 100.0, 500.0, 1000.0, 5000.0];
    var amount = NumberFormat('#,##0.########', s.numberLocale);
    var foreign = NumberFormat(
        c.isCrypto ? '#,##0.00000000' : '#,##0.00', s.numberLocale);
    var buffer = StringBuffer()
      ..write('<div class="columns"><table><thead><tr>'
          '<th>${c.code}</th><th>BRL</th></tr></thead><tbody>');
    for (var value in toBrl) {
      buffer.write('<tr><td>${_e(c.symbol)} ${amount.format(value)}</td>'
          '<td>${_brl(value * bid, s, decimals: 2)}</td></tr>');
    }
    buffer.write('</tbody></table><table><thead><tr><th>BRL</th>'
        '<th>${c.code}</th></tr></thead><tbody>');
    for (var value in fromBrl) {
      buffer.write('<tr><td>${_brl(value, s, decimals: 2)}</td>'
          '<td>${_e(c.symbol)} ${foreign.format(value / bid)}</td></tr>');
    }
    buffer.write('</tbody></table></div>');
    return buffer.toString();
  }

  String _aboutFiat(SiteCurrency c) =>
      '<p>A cotação mostrada aqui é a do câmbio comercial, o valor de compra '
      'usado entre bancos e empresas, informado pela AwesomeAPI e atualizado a '
      'cada hora. É a referência que o noticiário usa quando fala na cotação '
      '${c.ofPt} ${c.shortNamePt}.</p>'
      '<p>Quem compra ${c.namePt} em espécie, no cartão de crédito ou em conta '
      'global paga o câmbio turismo: bancos e casas de câmbio acrescentam o '
      'spread deles e o IOF, então o valor final costuma ficar acima do '
      'comercial.</p>';

  String _aboutCrypto(SiteCurrency c) =>
      '<p>O ${c.namePt} é negociado em corretoras 24 horas por dia, todos os '
      'dias, e a cotação muda o tempo todo. O valor mostrado aqui vem da '
      'AwesomeAPI e é atualizado a cada hora; o preço de compra e venda em '
      'cada corretora pode ser diferente.</p>'
      '<p>Criptomoedas oscilam muito mais do que moedas tradicionais. O '
      'histórico e o gráfico acima ajudam a ver o movimento recente, mas não '
      'indicam o que vai acontecer.</p>';

  String _breadcrumb(List<(String, String)> crumbs) {
    var buffer = StringBuffer('<nav class="crumbs" aria-label="Trilha"><ol>');
    for (var i = 0; i < crumbs.length; i++) {
      var (name, path) = crumbs[i];
      buffer.write(i == crumbs.length - 1
          ? '<li aria-current="page">${_e(name)}</li>'
          : '<li><a href="{{root}}$path">${_e(name)}</a></li>');
    }
    buffer.write('</ol></nav>');
    return buffer.toString();
  }

  Map<String, Object> _breadcrumbJsonLd(List<(String, String)> crumbs) => {
        '@context': 'https://schema.org',
        '@type': 'BreadcrumbList',
        'itemListElement': [
          for (var i = 0; i < crumbs.length; i++)
            {
              '@type': 'ListItem',
              'position': i + 1,
              'name': crumbs[i].$1,
              'item': _absolute(crumbs[i].$2),
            }
        ],
      };

  /// Gráfico de linha em SVG, desenhado aqui mesmo: aparece sem JavaScript e
  /// sem biblioteca, e o buscador lê o texto alternativo.
  String _sparkline(List<DailyClose> history, String label) {
    const width = 600.0, height = 180.0, pad = 8.0;
    var values = history.map((d) => d.bid).toList();
    var min = values.reduce((a, b) => a < b ? a : b);
    var max = values.reduce((a, b) => a > b ? a : b);
    var span = max - min == 0 ? 1 : max - min;
    var points = <String>[];
    for (var i = 0; i < values.length; i++) {
      var x = pad + (width - 2 * pad) * i / (values.length - 1);
      var y = pad + (height - 2 * pad) * (1 - (values[i] - min) / span);
      points.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }
    var line = points.join(' ');
    var area = '$pad,${height - pad} $line ${width - pad},${height - pad}';
    return '<figure class="chart"><svg viewBox="0 0 $width $height" '
        'role="img" aria-label="${_e(label)}" preserveAspectRatio="none">'
        '<title>${_e(label)}</title>'
        '<polygon points="$area" class="chart-area"/>'
        '<polyline points="$line" class="chart-line"/></svg></figure>';
  }

  // ---------------------------------------------------------------------------
  // Esqueleto

  /// Monta a página completa.
  ///
  /// [path] é o endereço da página relativo à raiz do site; `null` para a
  /// página de erro, que não tem endereço próprio nem é indexada. Os links
  /// internos são escritos como `{{root}}caminho` e resolvidos aqui para
  /// relativos (`../../caminho`), o que mantém o site navegável servido de
  /// qualquer lugar — inclusive de uma pasta local, para conferir o build.
  String _page({
    required SiteStrings strings,
    required String? path,
    required String title,
    required String description,
    required String body,
    String? root,
    Map<String, String>? alternates,
    List<Map<String, Object>> jsonLd = const [],
    bool isRoot = false,
  }) {
    var s = strings;
    if (root == null) {
      var depth = '/'.allMatches(path!).length;
      root = depth == 0 ? './' : '../' * depth;
    }
    var head = StringBuffer()
      ..write('<meta charset="utf-8">')
      ..write('<meta name="viewport" content="width=device-width, '
          'initial-scale=1">')
      ..write('<title>${_e(title)}</title>')
      ..write('<meta name="description" content="${_e(description)}">')
      ..write('<meta name="theme-color" content="#6C4DFF">')
      ..write('<link rel="icon" type="image/png" href="{{root}}favicon.png">')
      ..write('<link rel="apple-touch-icon" href="{{root}}icon-192.png">')
      ..write('<link rel="stylesheet" href="{{root}}styles.css">');
    if (path == null) {
      head.write('<meta name="robots" content="noindex">');
    } else {
      var url = _absolute(path);
      head
        ..write('<link rel="canonical" href="${_e(url)}">')
        ..write('<meta property="og:type" content="website">')
        ..write('<meta property="og:site_name" content="${_e(s.appName)}">')
        ..write('<meta property="og:title" content="${_e(title)}">')
        ..write('<meta property="og:description" '
            'content="${_e(description)}">')
        ..write('<meta property="og:url" content="${_e(url)}">')
        ..write('<meta property="og:image" '
            'content="${_e(_absolute('og-image.png'))}">')
        ..write('<meta property="og:image:width" content="1200">')
        ..write('<meta property="og:image:height" content="630">')
        ..write('<meta property="og:locale" content="${s.ogLocale}">')
        ..write('<meta name="twitter:card" content="summary_large_image">');
    }
    if (alternates != null) {
      for (var MapEntry(key: lang, value: altPath) in alternates.entries) {
        head.write('<link rel="alternate" hreflang="$lang" '
            'href="${_e(_absolute(altPath))}">');
      }
      head.write('<link rel="alternate" hreflang="x-default" '
          'href="${_e(_absolute(stringsPt.homePath))}">');
    }
    if (isRoot) {
      if (config.googleSiteVerification case var token?) {
        head.write('<meta name="google-site-verification" '
            'content="${_e(token)}">');
      }
      if (config.bingSiteVerification case var token?) {
        head.write('<meta name="msvalidate.01" content="${_e(token)}">');
      }
    }
    for (var item in jsonLd) {
      // "</" dentro do JSON fecharia o <script> antes da hora.
      var json = jsonEncode(item).replaceAll('</', '<\\/');
      head.write('<script type="application/ld+json">$json</script>');
    }
    head.write('<script>${_migrationScript(isRoot)}</script>');

    var languages = [
      for (var other in allStrings)
        other == s
            ? '<span aria-current="true">${_languageName(other)}</span>'
            : '<a href="{{root}}${other.homePath}" hreflang="${other.lang}" '
                'lang="${other.lang}">${_languageName(other)}</a>'
    ].join(' · ');

    var html = '<!DOCTYPE html>\n<html lang="${s.lang}"><head>$head</head>'
        '<body><header class="top"><div class="wrap">'
        '<a class="brand" href="{{root}}${s.homePath}">'
        '<img src="{{root}}icon-192.png" alt="" width="32" height="32">'
        '${_e(s.appName)}</a><nav>'
        '${s == stringsPt ? '<a href="{{root}}$ratesPath">Cotações</a>' : ''}'
        '<a class="button small" href="{{root}}$appPath">${_e(s.openApp)}</a>'
        '</nav></div></header><main>$body</main>'
        '<footer class="bottom"><div class="wrap">'
        '<p class="muted">${_e(s.disclaimer)}</p>'
        '<p>${_e(s.dataSource)} · <a href="$_repoUrl">${_e(s.sourceCode)}</a>'
        '</p><p>$languages</p></div></footer></body></html>\n';
    return html.replaceAll('{{root}}', root);
  }

  /// Até esta versão o app ficava na raiz do site, e é para lá que apontam o
  /// `start_url` de quem já o instalou e o service worker registrado nessa
  /// época. Este script, que roda nas páginas estáticas:
  ///
  /// - desregistra aquele service worker, que agora só atrapalharia (ele
  ///   serviria do cache a página antiga, o app, no lugar destas);
  /// - na raiz, manda para o app quem abriu pelo ícone do app instalado. Lá o
  ///   navegador lê o manifesto novo, com o mesmo `id`, e atualiza o
  ///   `start_url` da instalação — daí em diante o ícone já abre o app direto.
  String _migrationScript(bool isRoot) => '(function(){'
      "var root=new URL('{{root}}',location.href).href;"
      "if('serviceWorker' in navigator){navigator.serviceWorker"
      '.getRegistrations().then(function(rs){rs.forEach(function(r){'
      'if(r.scope===root)r.unregister();});});}'
      '${isRoot ? "var modes=['standalone','fullscreen','minimal-ui'];"
          "if(navigator.standalone===true||modes.some(function(m){"
          "return matchMedia('(display-mode: '+m+')').matches;}))"
          "location.replace(root+'$appPath');" : ''}'
      '})();';

  String _languageName(SiteStrings s) => switch (s.lang) {
        'en' => 'English',
        'es' => 'Español',
        _ => 'Português',
      };

  // ---------------------------------------------------------------------------
  // Formatação

  String _brl(double value, SiteStrings s, {int? decimals}) {
    decimals ??= value >= 10 ? 2 : 4;
    return NumberFormat.currency(
            locale: s.numberLocale, symbol: 'R\$', decimalDigits: decimals)
        .format(value);
  }

  String _change(double pct, SiteStrings s) {
    var formatted = NumberFormat('#,##0.00', s.numberLocale).format(pct.abs());
    var (sign, css) = pct > 0
        ? ('+', 'up')
        : pct < 0
            ? ('−', 'down')
            : ('', 'flat');
    return '<span class="change $css">$sign$formatted%</span>';
  }

  /// A AwesomeAPI data as cotações pelo horário de Brasília, que desde 2019
  /// não tem horário de verão: UTC−3 o ano todo.
  DateTime _brasilia(DateTime time) =>
      time.toUtc().subtract(const Duration(hours: 3));

  String _date(DateTime time) {
    var t = _brasilia(time);
    return '${_two(t.day)}/${_two(t.month)}/${t.year}';
  }

  String _dateTime(DateTime time, SiteStrings s) {
    var t = _brasilia(time);
    var clock = '${_two(t.hour)}:${_two(t.minute)}';
    return switch (s.lang) {
      'en' => '${DateFormat.yMMMd('en_US').format(t)}, $clock',
      'es' => '${_date(time)}, $clock',
      _ => '${_date(time)} às $clock',
    };
  }

  String _isoDate(DateTime time) {
    var t = time.toUtc();
    return '${t.year}-${_two(t.month)}-${_two(t.day)}';
  }
}

const _repoUrl = 'https://github.com/hhldiniz/cotacao_direta';

String _two(int value) => value.toString().padLeft(2, '0');

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

const _escape = HtmlEscape(HtmlEscapeMode(
    escapeLtGt: true, escapeQuot: true, escapeApos: true, escapeSlash: false));

String _e(String text) => _escape.convert(text);
