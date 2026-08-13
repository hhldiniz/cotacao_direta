import 'package:cotacao_direta/model/base_model.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Configuration', () {
    test('é um BaseModel', () {
      expect(Configuration(1), isA<BaseModel>());
    });

    test('usa os padrões quando só o id é informado', () {
      var configuration = Configuration(1);

      expect(configuration.id, 1);
      expect(configuration.overrideDefaultCurrency, isFalse);
      expect(configuration.selectedOverrideCurrencyCode, "");
      expect(configuration.homeCurrencyCodes,
          Configuration.defaultHomeCurrencyCodes,
          reason: "quem nunca escolheu vê as moedas que a tela já mostrava");
      expect(configuration.languageCode, "",
          reason: "sem escolha, a interface segue o idioma do aparelho");
    });

    test('aceita os valores informados', () {
      var configuration = Configuration(1,
          overrideDefaultCurrency: true, selectedOverrideCurrencyCode: "EUR");

      expect(configuration.overrideDefaultCurrency, isTrue);
      expect(configuration.selectedOverrideCurrencyCode, "EUR");
    });

    test('toMap converte o booleano em 1 quando o override está ligado', () {
      var map = Configuration(1,
              overrideDefaultCurrency: true,
              selectedOverrideCurrencyCode: "JPY")
          .toMap();

      expect(map, {
        'id': 1,
        'overrideDefaultCurrency': 1,
        'selectedOverrideCurrencyCode': "JPY",
        'homeCurrencyCodes': "USD,EUR,CAD,JPY",
        'languageCode': ""
      });
    });

    test('toMap converte o booleano em 0 quando o override está desligado', () {
      var map = Configuration(1, overrideDefaultCurrency: false).toMap();

      expect(map['overrideDefaultCurrency'], 0);
    });

    test('toMap preserva o código nulo', () {
      var map = Configuration(1, selectedOverrideCurrencyCode: null).toMap();

      expect(map['selectedOverrideCurrencyCode'], isNull);
    });

    test('aceita as moedas escolhidas para a tela inicial', () {
      var configuration =
          Configuration(1, homeCurrencyCodes: ["GBP", "CHF"]);

      expect(configuration.homeCurrencyCodes, ["GBP", "CHF"]);
    });

    test('toMap guarda as moedas da tela inicial separadas por vírgula', () {
      var map = Configuration(1, homeCurrencyCodes: ["GBP", "CHF"]).toMap();

      expect(map['homeCurrencyCodes'], "GBP,CHF");
    });

    test('parseHomeCurrencyCodes lê a lista gravada', () {
      expect(Configuration.parseHomeCurrencyCodes("GBP,CHF"), ["GBP", "CHF"]);
    });

    test('parseHomeCurrencyCodes normaliza espaços e caixa', () {
      expect(Configuration.parseHomeCurrencyCodes(" gbp , chf ,"),
          ["GBP", "CHF"]);
    });

    // Coluna vazia é o que a migração deixa para quem já usava o app, e o
    // padrão da coluna para quem nunca abriu a opção.
    test('parseHomeCurrencyCodes devolve o padrão para texto vazio ou nulo',
        () {
      expect(Configuration.parseHomeCurrencyCodes(""),
          Configuration.defaultHomeCurrencyCodes);
      expect(Configuration.parseHomeCurrencyCodes(null),
          Configuration.defaultHomeCurrencyCodes);
    });

    test('aceita o idioma escolhido para a interface', () {
      expect(Configuration(1, languageCode: "pt").languageCode, "pt");
    });

    // O que vem do banco pode ter espaço ou caixa diferente; um "PT " não
    // bateria com nenhum idioma da build e cairia no do aparelho.
    test('parseLanguageCode normaliza espaços e caixa', () {
      expect(Configuration.parseLanguageCode(" PT "), "pt");
      expect(Configuration(1, languageCode: " EN").languageCode, "en");
    });

    test('parseLanguageCode lê nulo como o idioma do aparelho', () {
      expect(Configuration.parseLanguageCode(null), "");
    });

    test('toMap guarda o idioma escolhido', () {
      expect(Configuration(1, languageCode: "en").toMap()['languageCode'],
          "en");
    });

    test('toString expõe todos os campos', () {
      var text = Configuration(1,
              overrideDefaultCurrency: true,
              selectedOverrideCurrencyCode: "GBP")
          .toString();

      expect(text, contains("id: 1"));
      expect(text, contains("overrideDefaultCurrency: true"));
      expect(text, contains("selectedOverrideCurrencyCode: GBP"));
      expect(text, contains("homeCurrencyCodes: USD,EUR,CAD,JPY"));
      expect(text, contains("languageCode:"));
    });
  });
}
