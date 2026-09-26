// Gera o site público estático: as páginas iniciais (pt-BR, en, es), uma
// página por moeda em /cotacao/, o sitemap e o robots.txt. O app Flutter é
// publicado ao lado, em /app/ — ver .github/workflows/deploy-pages.yml e a
// seção "Public website and SEO" do README.
//
// Uso:
//   dart run tool/build_site.dart --out build/site \
//       --site-url https://hhldiniz.github.io/cotacao_direta/
//
// Variáveis de ambiente opcionais:
//   GOOGLE_SITE_VERIFICATION, BING_SITE_VERIFICATION  metas de verificação do
//     Search Console e do Bing Webmaster Tools;
//   AWESOMEAPI_TOKEN  chave da AwesomeAPI, que tira o build do limite de
//     requisições por IP.
//
// A falha da AwesomeAPI não derruba o build: se ela não responder, as cotações
// vêm do `data.json` da publicação anterior (e, sem ele, as páginas saem com um
// aviso no lugar do valor). Assim o site, e o app que é publicado junto, nunca
// ficam presos a uma API fora do ar ou limitando as requisições.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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

  var env = Platform.environment;
  var config = SiteConfig(
      siteUrl: Uri.parse(siteUrl),
      googleSiteVerification: _nonEmpty(env['GOOGLE_SITE_VERIFICATION']),
      bingSiteVerification: _nonEmpty(env['BING_SITE_VERIFICATION']));
  var previous = await _loadPrevious(config.siteUrl.resolve('data.json'));
  var api = AwesomeApi(token: _nonEmpty(env['AWESOMEAPI_TOKEN']));
  var codes = siteCurrencies.map((c) => c.code).toList();
  var quotes = <String, Quote>{...?previous?.quotes};
  var history = <String, List<DailyClose>>{...?previous?.history};
  try {
    var latest = await api.latest(codes);
    quotes.addAll(latest);
    for (var code in codes) {
      if (!latest.containsKey(code))
        stderr.writeln('Aviso: a API não devolveu a cotação de $code.');
    }
    for (var code in codes) {
      // Uma pausa curta entre as consultas para não esbarrar no limite da API.
      await Future.delayed(const Duration(seconds: 1));
      try {
        history[code] = await api.daily(code, _historyDays);
      } catch (error) {
        stderr.writeln('Aviso: sem histórico novo de $code: $error');
      }
    }
  } catch (error) {
    // Se nem a última cotação veio, o histórico (dez consultas, cada uma com
    // as suas tentativas) só atrasaria o build para dar no mesmo.
    stderr.writeln('Aviso: AwesomeAPI indisponível ($error); usando '
        '${previous == null ? 'nenhuma cotação' : 'as cotações da publicação '
            'anterior (${previous.generatedAt.toIso8601String()})'}.');
  } finally {
    api.close();
  }
  var data = SiteData(
      generatedAt: DateTime.now().toUtc(), quotes: quotes, history: history);

  var files = buildSite(config, data);

  for (var MapEntry(key: path, value: content) in files.entries) {
    var file = File('$out/$path');
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }
  await File('$out/data.json').writeAsString(jsonEncode(data.toJson()));
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

/// O `data.json` da publicação atual, ou `null` se não houver (primeira
/// publicação, site fora do ar, formato antigo).
Future<SiteData?> _loadPrevious(Uri uri) async {
  try {
    var response =
        await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return null;
    return SiteData.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map);
  } catch (error) {
    stderr.writeln('Aviso: sem dados da publicação anterior em $uri: $error');
    return null;
  }
}

String? _nonEmpty(String? value) =>
    value == null || value.trim().isEmpty ? null : value.trim();
