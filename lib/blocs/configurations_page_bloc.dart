import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/view/widgets/widget_state_helpers/override_currency_state_helper.dart';

class ConfigurationsPageBloc extends BaseBloc {
  final OverrideCurrencyStateHelper _overrideCurrencyStateHelper =
      OverrideCurrencyStateHelper();

  StreamController _currencyOptionsStreamController = StreamController();

  StreamController _overrideDefaultCurrencyValueStreamController =
      StreamController<OverrideCurrencyStateHelper>.broadcast();

  StreamController _selectedCurrencyCodeStreamController = StreamController();

  Stream get currencyOptionsStream => _currencyOptionsStreamController.stream;

  Stream get overrideDefaultCurrencyValueStream =>
      _overrideDefaultCurrencyValueStreamController.stream;

  Sink get overrideDefaultCurrencyValueSink =>
      _overrideDefaultCurrencyValueStreamController.sink;

  OverrideCurrencyStateHelper get overrideCurrencyStateHelper =>
      _overrideCurrencyStateHelper;

  updateSelectedOverrideCurrency(String currencyCode) {
    _overrideCurrencyStateHelper.selectedCurrencyOverride = currencyCode;
    overrideDefaultCurrencyValueSink.add(_overrideCurrencyStateHelper);
  }

  updateOverrideCurrencySwitch(bool enabled) {
    _overrideCurrencyStateHelper.enableCurrencyOverride = enabled;
    overrideDefaultCurrencyValueSink.add(_overrideCurrencyStateHelper);
  }

  @override
  void dispose() {
    _currencyOptionsStreamController.close();
    _overrideDefaultCurrencyValueStreamController.close();
    _selectedCurrencyCodeStreamController.close();
  }
}
