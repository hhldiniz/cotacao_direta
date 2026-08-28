import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/util/app_locale_controller.dart';
import 'package:cotacao_direta/view/widgets/widget_state_helpers/override_currency_state_helper.dart';

class ConfigurationsPageBloc extends BaseBloc {
  final OverrideCurrencyStateHelper _overrideCurrencyStateHelper =
      OverrideCurrencyStateHelper();
  final ConfigurationRepository _configurationRepository;

  /// Quem leva o idioma escolhido até o MaterialApp da raiz, que está acima
  /// deste bloc na árvore e por isso não pode ouvir os streams daqui.
  final AppLocaleController _localeController;

  /// O repositório é injetável para os testes rodarem sem tocar no banco.
  ConfigurationsPageBloc(
      {ConfigurationRepository? configurationRepository,
      AppLocaleController? localeController})
      : _configurationRepository =
            configurationRepository ?? ConfigurationRepository(),
        _localeController = localeController ?? AppLocaleController.instance;

  StreamController _currencyOptionsStreamController = StreamController();

  StreamController _overrideDefaultCurrencyValueStreamController =
      StreamController<OverrideCurrencyStateHelper>.broadcast();

  StreamController _selectedCurrencyCodeStreamController = StreamController();

  // Idioma da interface escolhido pelo usuário. Vazio é "seguir o aparelho".
  StreamController<String> _languageStreamController =
      StreamController<String>.broadcast();

  String _languageCode = "";

  Stream get currencyOptionsStream => _currencyOptionsStreamController.stream;

  Stream<String> get languageStream => _languageStreamController.stream;

  /// Último idioma conhecido, para a tela ter o que mostrar no seletor antes
  /// de a leitura do banco terminar.
  String get languageCode => _languageCode;

  Stream get overrideDefaultCurrencyValueStream =>
      _overrideDefaultCurrencyValueStreamController.stream;

  Sink get overrideDefaultCurrencyValueSink =>
      _overrideDefaultCurrencyValueStreamController.sink;

  OverrideCurrencyStateHelper get overrideCurrencyStateHelper =>
      _overrideCurrencyStateHelper;

  loadCurrentConfiguration() {
    _configurationRepository
        .getConfiguration()
        .then((Configuration configuration) {
      _overrideCurrencyStateHelper.selectedCurrencyOverride =
          configuration.selectedOverrideCurrencyCode;
      _overrideCurrencyStateHelper.enableCurrencyOverride =
          configuration.overrideDefaultCurrency;
      overrideDefaultCurrencyValueSink.add(_overrideCurrencyStateHelper);
      _languageCode = configuration.languageCode;
      _languageStreamController.sink.add(_languageCode);
    });
  }

  /// Grava o idioma da interface e o aplica na hora.
  ///
  /// [languageCode] é a etiqueta do idioma ("pt", "es-419"); nula ou vazia
  /// volta a seguir o aparelho, que é o padrão.
  /// A troca vai para o controlador antes da gravação: a tela toda é
  /// reconstruída no idioma novo assim que o usuário escolhe, sem esperar o
  /// banco.
  Future<void> updateLanguage(String? languageCode) async {
    _languageCode = Configuration.parseLanguageCode(languageCode);
    _languageStreamController.sink.add(_languageCode);
    _localeController.updateLanguage(_languageCode);
    var configuration = await _configurationRepository.getConfiguration();
    configuration.languageCode = _languageCode;
    await _configurationRepository.insert(configuration);
  }

  updateSelectedOverrideCurrency(String? currencyCode) {
    _overrideCurrencyStateHelper.selectedCurrencyOverride = currencyCode;
    overrideDefaultCurrencyValueSink.add(_overrideCurrencyStateHelper);
    _configurationRepository
        .getConfiguration()
        .then((Configuration configuration) {
      configuration.selectedOverrideCurrencyCode = currencyCode;
      _configurationRepository.insert(configuration);
    });
  }

  /// Liga ou desliga a moeda de contrapartida escolhida pelo usuário.
  ///
  /// [fallbackCurrencyCode] é a moeda que a tela já mostra no seletor quando
  /// ainda não há nenhuma escolhida. Sem gravá-la, ligar a opção não mudava
  /// nada: a tela exibia uma moeda, mas a configuração continuava com o código
  /// vazio e as cotações seguiam saindo frente ao real.
  updateOverrideCurrencySwitch(bool enabled, {String? fallbackCurrencyCode}) {
    _overrideCurrencyStateHelper.enableCurrencyOverride = enabled;
    var selected = _overrideCurrencyStateHelper.selectedCurrencyOverride;
    if (enabled &&
        (selected == null || selected.isEmpty) &&
        fallbackCurrencyCode != null) {
      _overrideCurrencyStateHelper.selectedCurrencyOverride =
          fallbackCurrencyCode;
    }
    overrideDefaultCurrencyValueSink.add(_overrideCurrencyStateHelper);
    _configurationRepository
        .getConfiguration()
        .then((Configuration configuration) {
      configuration.overrideDefaultCurrency = enabled;
      // Os dois campos vão na mesma gravação: em escritas separadas, a leitura
      // da segunda poderia acontecer antes da primeira ser gravada e desfazê-la.
      configuration.selectedOverrideCurrencyCode =
          _overrideCurrencyStateHelper.selectedCurrencyOverride;
      _configurationRepository.insert(configuration);
    });
  }

  @override
  void dispose() {
    _currencyOptionsStreamController.close();
    _overrideDefaultCurrencyValueStreamController.close();
    _selectedCurrencyCodeStreamController.close();
    _languageStreamController.close();
  }
}
