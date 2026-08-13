import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:flutter/material.dart';

/// O idioma da interface escolhido nas configurações.
///
/// A opção fica gravada no banco como as outras, mas quem precisa dela é o
/// [MaterialApp] na raiz da árvore — acima dos blocs, que só existem dentro da
/// home. Um notificador de escopo do app é o caminho mais curto entre a tela
/// de opções e essa raiz; [ValueNotifier] já basta porque o valor é um só e
/// muda muito de vez em quando.
///
/// Nulo significa "seguir o aparelho": é o que o app sempre fez, e continua
/// sendo o padrão.
class AppLocaleController extends ValueNotifier<Locale?> {
  final ConfigurationRepository _configurationRepository;

  /// A instância que o aplicativo usa. Os testes constroem a sua própria, com
  /// um repositório de mentira, em vez de mexer nesta.
  static final AppLocaleController instance = AppLocaleController();

  AppLocaleController({ConfigurationRepository? configurationRepository})
      : _configurationRepository =
            configurationRepository ?? ConfigurationRepository(),
        super(null);

  /// Lê o idioma gravado. Chamada na partida do app, antes do primeiro quadro,
  /// para a tela já abrir no idioma certo em vez de piscar no do aparelho.
  ///
  /// Uma falha de leitura não pode impedir o app de abrir: sem configuração
  /// legível o idioma continua sendo o do aparelho.
  Future<void> load() async {
    try {
      var configuration = await _configurationRepository.getConfiguration();
      value = AppLocales.localeFor(configuration.languageCode);
    } catch (error, stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: "cotacao_direta",
          context: ErrorDescription("lendo o idioma escolhido")));
      value = null;
    }
  }

  /// Aplica o idioma escolhido na tela de opções. Etiqueta vazia ou nula volta
  /// a seguir o aparelho. A gravação fica com o bloc, que já cuida do resto da
  /// configuração.
  void updateLanguage(String? languageTag) {
    value = AppLocales.localeFor(languageTag);
  }
}
