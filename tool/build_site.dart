// Gera o site público estático: as páginas iniciais (pt-BR, en, es), uma
// página por moeda em /cotacao/, o sitemap e o robots.txt. O app Flutter é
// publicado ao lado, em /app/ — ver .github/workflows/deploy-pages.yml e a
// seção "Public website and SEO" do README.
//
// Uso:
//   dart run tool/build_site.dart --out build/site \
//       --site-url https://hhldiniz.github.io/cotacao_direta/
//
// As metas de verificação do Search Console e do Bing vêm das variáveis de
// ambiente GOOGLE_SITE_VERIFICATION e BING_SITE_VERIFICATION, quando
// definidas.
//
// Se a AwesomeAPI não devolver a cotação de alguma moeda, o build falha: é
// melhor o site continuar com a publicação anterior do que ficar com uma
// página faltando.
import 'dart:io';

import 'site/awesome_api.dart';
import 'site/currencies.dart';
import 'site/site_builder.dart';

/// Dias de histórico nas páginas de cada moeda.
const _historyDays = 30;

/// Arquivos copiados como estão: destino no site → origem no repositório.
const _staticFiles = {
  'styles.css': 'site/styles.css',
  'og-image.png': 'site/og-image.png',
  'favicon.png': 'web/favicon.png',
  'icon-192.png': 'web/icons/Icon-192.png',
  'screenshots/home.png': 'flatpak/screenshots/home.png',
  'screenshots/conversion.png': 'flatpak/screenshots/conversion.png',
  'screenshots/history.png': 'flatpak/screenshots/history.png',
  'screenshots/alerts.png': 'flatpak/screenshots/alerts.png',
};

Future<void> main(List<String> args) async {
  var options = _parseArgs(args);
  var out = options['out'];
  var siteUrl = options['site-url'];
  if (out == null || siteUrl == null) {
    stderr.writeln('Uso: dart run tool/build_site.dart --out <pasta> '
        '--site-url <https://.../>');
    exit(64);
  }

  var api = AwesomeApi();
  SiteData data;
  try {
    var codes = siteCurrencies.map((c) => c.code).toList();
    var quotes = await api.latest(codes);
    var history = <String, List<DailyClose>>{};
    for (var code in codes) {
      try {
        history[code] = await api.daily(code, _historyDays);
      } catch (error) {
        // Sem histórico a página ainda sai, só sem gráfico e tabela.
        stderr.writeln('Aviso: sem histórico de $code: $error');
      }
    }
    data = SiteData(
        generatedAt: DateTime.now().toUtc(), quotes: quotes, history: history);
  } finally {
    api.close();
  }

  var env = Platform.environment;
  var files = buildSite(
      SiteConfig(
          siteUrl: Uri.parse(siteUrl),
          googleSiteVerification: _nonEmpty(env['GOOGLE_SITE_VERIFICATION']),
          bingSiteVerification: _nonEmpty(env['BING_SITE_VERIFICATION'])),
      data);

  for (var MapEntry(key: path, value: content) in files.entries) {
    var file = File('$out/$path');
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }
  for (var MapEntry(key: path, value: source) in _staticFiles.entries) {
    var file = File('$out/$path');
    await file.parent.create(recursive: true);
    await File(source).copy(file.path);
  }
  stdout.writeln('Site gerado em $out: ${files.length} páginas e arquivos, '
      '${_staticFiles.length} arquivos estáticos.');
}

Map<String, String> _parseArgs(List<String> args) {
  var options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    var arg = args[i];
    if (!arg.startsWith('--')) continue;
    var name = arg.substring(2);
    var eq = name.indexOf('=');
    if (eq >= 0) {
      options[name.substring(0, eq)] = name.substring(eq + 1);
    } else if (i + 1 < args.length) {
      options[name] = args[++i];
    }
  }
  return options;
}

String? _nonEmpty(String? value) =>
    value == null || value.trim().isEmpty ? null : value.trim();
