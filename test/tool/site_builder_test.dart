import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../tool/site/awesome_api.dart';
import '../../tool/site/currencies.dart';
import '../../tool/site/site_builder.dart';

final _siteUrl = Uri.parse('https://example.github.io/cotacao_direta/');

SiteData _sampleData({Map<String, List<DailyClose>>? history}) {
  // 26/09/2026 18:30 UTC = 15:30 em Brasília.
  var time = DateTime.utc(2026, 9, 26, 18, 30);
  return SiteData(
    generatedAt: time,
    quotes: {
      for (var c in siteCurrencies)
        c.code: Quote(
            bid: c.code == 'BTC' ? 612345.67 : 5.4321,
            time: time,
            high: 5.5,
            low: 5.3,
            pctChange: c.code == 'EUR' ? -0.5 : 0.25),
    },
    history: history ??
        {
          'USD': [
            for (var i = 0; i < 30; i++)
              DailyClose(
                  time: time.subtract(Duration(days: 29 - i)),
                  bid: 5.0 + i * 0.01,
                  pctChange: 0.1),
          ],
        },
  );
}

void main() {
  group('buildSite', () {
    late Map<String, String> files;

    setUp(() {
      files = buildSite(
          SiteConfig(
              siteUrl: _siteUrl, googleSiteVerification: 'google-token'),
          _sampleData());
    });

    test('gera as páginas iniciais, uma por moeda, o sitemap e o robots', () {
      expect(
          files.keys,
          containsAll([
            'index.html',
            'en/index.html',
            'es/index.html',
            'cotacao/index.html',
            'cotacao/dolar/index.html',
            'cotacao/bitcoin/index.html',
            '404.html',
            'sitemap.xml',
            'robots.txt',
          ]));
      expect(files.keys.where((p) => p.startsWith('cotacao/')),
          hasLength(siteCurrencies.length + 1));
    });

    test('página inicial tem canonical, hreflang, Open Graph e JSON-LD', () {
      var home = files['index.html']!;
      expect(home, contains('<html lang="pt-BR">'));
      expect(home,
          contains('<link rel="canonical" href="https://example.github.io/'
              'cotacao_direta/">'));
      expect(home, contains('hreflang="en" href="$_siteUrl' 'en/"'));
      expect(home, contains('hreflang="es" href="$_siteUrl' 'es/"'));
      expect(home, contains('hreflang="x-default" href="$_siteUrl"'));
      expect(home,
          contains('<meta property="og:image" content="${_siteUrl}og-image.png">'));
      expect(home,
          contains('<meta name="google-site-verification" '
              'content="google-token">'));
      expect(home, contains('href="./app/"'));

      var jsonLd = RegExp(r'<script type="application/ld\+json">(.*?)</script>')
          .firstMatch(home)!
          .group(1)!;
      var decoded = jsonDecode(jsonLd) as Map;
      expect(decoded['@type'], 'WebApplication');
      expect(decoded['applicationCategory'], 'FinanceApplication');
      expect(decoded['url'], _siteUrl.toString());
    });

    test('só a raiz leva a verificação e o redirecionamento do app instalado',
        () {
      expect(files['en/index.html'], isNot(contains('google-site-verification')));
      expect(files['index.html'], contains("location.replace(root+'app/')"));
      expect(files['en/index.html'], isNot(contains('location.replace')));
    });

    test('páginas em inglês e espanhol ficam no próprio idioma', () {
      expect(files['en/index.html'], contains('<html lang="en">'));
      expect(files['en/index.html'], contains('Direct Quote'));
      expect(files['en/index.html'], contains('href="../app/"'));
      expect(files['es/index.html'], contains('<html lang="es">'));
      expect(files['es/index.html'], contains('Cotización Directa'));
    });

    test('página da moeda traz a cotação formatada em reais', () {
      var page = files['cotacao/dolar/index.html']!;
      expect(page, contains('<h1>Cotação do dólar hoje</h1>'));
      expect(page, contains('R\$ 5,4321'));
      expect(page, contains('<span class="change up">+0,25%</span>'));
      expect(page, contains('26/09/2026 às 15:30'));
      expect(page, contains('href="../../app/"'));
      expect(page, contains('href="../../cotacao/euro/"'));
      expect(page, contains('<svg'));
      expect(page, contains('Histórico da cotação do dólar'));
    });

    test('moeda sem histórico sai sem gráfico', () {
      var page = files['cotacao/euro/index.html']!;
      expect(page, isNot(contains('<svg')));
      expect(page, contains('<span class="change down">−0,50%</span>'));
    });

    test('criptomoeda usa oito casas na conversão a partir do real', () {
      var page = files['cotacao/bitcoin/index.html']!;
      expect(page, contains('R\$ 612.345,67'));
      expect(page, contains('₿ 0,00016331'));
    });

    test('404 não é indexada e usa endereços absolutos', () {
      var page = files['404.html']!;
      expect(page, contains('<meta name="robots" content="noindex">'));
      expect(page, contains('href="${_siteUrl}app/"'));
      expect(page, isNot(contains('rel="canonical"')));
    });

    test('sitemap lista todas as páginas indexáveis', () {
      var sitemap = files['sitemap.xml']!;
      expect(RegExp('<loc>').allMatches(sitemap),
          hasLength(3 + 1 + siteCurrencies.length));
      expect(sitemap, contains('<loc>${_siteUrl}cotacao/dolar/</loc>'));
      expect(sitemap, contains('<lastmod>2026-09-26</lastmod>'));
      expect(files['robots.txt'], contains('Sitemap: ${_siteUrl}sitemap.xml'));
    });

    test('nenhum marcador de caminho fica sem resolver', () {
      for (var MapEntry(key: path, value: content) in files.entries) {
        expect(content, isNot(contains('{{root}}')), reason: path);
      }
    });
  });

  test('SiteConfig acrescenta a barra final ao endereço', () {
    var config = SiteConfig(siteUrl: Uri.parse('https://x.dev/sub'));
    expect(config.siteUrl.toString(), 'https://x.dev/sub/');
  });

  test('moeda sem cotação mantém a página, com um aviso no lugar do valor',
      () {
    var data = _sampleData();
    data.quotes.remove('USD');
    var files = buildSite(SiteConfig(siteUrl: _siteUrl), data);
    var page = files['cotacao/dolar/index.html']!;
    expect(page, contains('indisponível no momento'));
    expect(page, contains('<title>Cotação do dólar hoje (USD/BRL) | '));
    expect(page, isNot(contains('Conversão de')));
    expect(files['sitemap.xml'], contains('cotacao/dolar/'));
  });

  test('sem nenhuma cotação o site ainda é gerado', () {
    var files = buildSite(
        SiteConfig(siteUrl: _siteUrl),
        SiteData(
            generatedAt: DateTime.utc(2026, 9, 26), quotes: {}, history: {}));
    expect(files['index.html'], isNot(contains('Atualizado em')));
    expect(files['cotacao/euro/index.html'], contains('indisponível'));
  });

  test('SiteData sobrevive à ida e volta pelo data.json', () {
    var data = _sampleData();
    var copy = SiteData.fromJson(jsonDecode(jsonEncode(data.toJson())) as Map);
    expect(copy.generatedAt, data.generatedAt);
    expect(copy.quotes['USD']!.bid, data.quotes['USD']!.bid);
    expect(copy.quotes['USD']!.high, 5.5);
    expect(copy.history['USD']!.length, 30);
    expect(buildSite(SiteConfig(siteUrl: _siteUrl), copy),
        buildSite(SiteConfig(siteUrl: _siteUrl), data));
  });

  group('AwesomeApi', () {
    test('parseLatest lê o objeto indexado pelo par', () {
      var quotes = AwesomeApi.parseLatest(jsonEncode({
        'USDBRL': {
          'code': 'USD',
          'codein': 'BRL',
          'bid': '5.4321',
          'high': '5.5',
          'low': '5.3',
          'pctChange': '0.25',
          'timestamp': '1790447400',
        },
        'EURBRL': {'code': 'EUR', 'bid': '0', 'timestamp': '1790447400'},
      }));
      expect(quotes.keys, ['USD']);
      expect(quotes['USD']!.bid, 5.4321);
      expect(quotes['USD']!.pctChange, 0.25);
      expect(quotes['USD']!.time,
          DateTime.fromMillisecondsSinceEpoch(1790447400000, isUtc: true));
    });

    test('parseDaily ordena do mais antigo para o mais novo', () {
      var history = AwesomeApi.parseDaily(jsonEncode([
        {'bid': '5.3', 'timestamp': '200', 'code': 'USD'},
        {'bid': '5.2', 'timestamp': '100'},
        {'bid': 'x', 'timestamp': '50'},
      ]));
      expect(history.map((d) => d.bid), [5.2, 5.3]);
    });

    test('tenta de novo depois de um 429 e manda o token', () async {
      var calls = <Uri>[];
      var api = AwesomeApi(
          token: 'segredo',
          retryDelays: const [Duration.zero, Duration.zero],
          client: MockClient((request) async {
            calls.add(request.url);
            return calls.length == 1
                ? http.Response('', 429)
                : http.Response(
                    jsonEncode({
                      'USDBRL': {'code': 'USD', 'bid': '5', 'timestamp': '1'}
                    }),
                    200);
          }));
      var quotes = await api.latest(['USD']);
      expect(quotes['USD']!.bid, 5);
      expect(calls, hasLength(2));
      expect(calls.first.queryParameters['token'], 'segredo');
    });

    test('desiste depois das tentativas sem expor o token', () async {
      var api = AwesomeApi(
          token: 'segredo',
          retryDelays: const [Duration.zero],
          client: MockClient((_) async => http.Response('', 429)));
      await expectLater(
          api.latest(['USD']),
          throwsA(predicate((error) =>
              '$error'.contains('HTTP 429') &&
              !'$error'.contains('segredo'))));
    });

    test('respostas de erro viram coleções vazias', () {
      expect(AwesomeApi.parseLatest('{"status":404}'), isEmpty);
      expect(AwesomeApi.parseDaily('{"status":404}'), isEmpty);
    });
  });
}
