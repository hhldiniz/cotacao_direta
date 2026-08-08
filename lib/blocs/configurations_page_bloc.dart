import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/view/widgets/widget_state_helpers/override_currency_state_helper.dart';

class ConfigurationsPageBloc extends BaseBloc {
  final OverrideCurrencyStateHelper _overrideCurrencyStateHelper =
      OverrideCurrencyStateHelper();
  final ConfigurationRepository _configurationRepository;

  /// O repositório é injetável para os testes rodarem sem tocar no banco.
  ConfigurationsPageBloc({ConfigurationRepository? configurationRepository})
      : _configurationRepository =
            configurationRepository ?? ConfigurationRepository();

  StreamController _currencyOptionsStreamController = StreamController();

  StreamController _overrideDefaultCurrencyValueStreamController =
      StreamController<OverrideCurrencyStateHelper>.broadcast();

  StreamController _selectedCurrencyCodeStreamController = StreamController();

  // Moedas que a tela inicial mostra em bolha. A lista é curta e sempre lida
  // inteira, então a tela recebe os códigos como estão gravados.
  StreamController<List<String>> _homeCurrenciesStreamController =
      StreamController<List<String>>.broadcast();

  List<String> _homeCurrencyCodes =
      List.of(Configuration.defaultHomeCurrencyCodes);

  Stream get currencyOptionsStream => _currencyOptionsStreamController.stream;

  Stream<List<String>> get homeCurrenciesStream =>
      _homeCurrenciesStreamController.stream;

  /// Última lista conhecida, para a tela ter o que mostrar antes de a leitura
  /// do banco terminar.
  List<String> get homeCurrencyCodes => _homeCurrencyCodes;

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
      _homeCurrencyCodes = List.of(configuration.homeCurrencyCodes);
      _homeCurrenciesStreamController.sink.add(_homeCurrencyCodes);
    });
  }

  /// Grava as moedas que aparecem em bolha na tela inicial, na ordem escolhida
  /// — a primeira é a bolha de destaque.
  ///
  /// Uma lista vazia é ignorada: a tela inicial ficaria sem nenhuma cotação, e
  /// a coluna vazia significa "nunca escolheu", o que traria de volta as
  /// moedas padrão sem o usuário ter pedido.
  Future<void> updateHomeCurrencies(List<String> currencyCodes) async {
    if (currencyCodes.isEmpty) return;
    _homeCurrencyCodes = List.of(currencyCodes);
    _homeCurrenciesStreamController.sink.add(_homeCurrencyCodes);
    var configuration = await _configurationRepository.getConfiguration();
    configuration.homeCurrencyCodes = List.of(currencyCodes);
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
    _homeCurrenciesStreamController.close();
  }
}
