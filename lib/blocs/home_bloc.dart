import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/configuration.dart';
import 'package:cotacao_direta/repository/configuration_repository.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:cotacao_direta/util/currency_name.dart';
import 'package:flutter/widgets.dart';

class HomeBloc extends BaseBloc {
  final CurrencyRepository _currencyRepository;
  final ConfigurationRepository _configurationRepository;
  StreamController<String?>? _headsUpTextStreamController;

  HomeBloc(
      {CurrencyRepository? currencyRepository,
      ConfigurationRepository? configurationRepository})
      : _currencyRepository = currencyRepository ?? CurrencyRepository(),
        _configurationRepository =
            configurationRepository ?? ConfigurationRepository();

  /// Moedas mostradas em bolha enquanto o usuário não escolhe as suas.
  static List<Currencies> get defaultHomeCurrencies =>
      _currenciesForCodes(Configuration.defaultHomeCurrencyCodes);

  /// Códigos que o app não conhece são descartados: a lista vem do banco e
  /// pode ter sobrado de uma versão que cotava uma moeda a mais.
  static List<Currencies> _currenciesForCodes(List<String> codes) =>
      codes.map(currencyForCode).whereType<Currencies>().toList();

  /// Moedas escolhidas nas configurações para aparecer em bolha na tela
  /// inicial, na ordem em que devem aparecer.
  ///
  /// Uma escolha que não sobrou nenhuma moeda conhecida vira as moedas padrão:
  /// a tela sem bolha nenhuma não diria ao usuário o que aconteceu.
  Future<List<Currencies>> loadHomeCurrencies() async {
    var configuration = await _configurationRepository.getConfiguration();
    var currencies = _currenciesForCodes(configuration.homeCurrencyCodes);
    return currencies.isEmpty ? defaultHomeCurrencies : currencies;
  }

  /// Grava a ordem em que as moedas aparecem em bolha na tela inicial.
  ///
  /// É a mesma configuração que a aba de opções escreve: reordenar a grade
  /// arrastando as bolhas e refazer a escolha nas opções são dois caminhos
  /// para a mesma lista, então a ordem arrastada continua valendo na próxima
  /// vez que o app abrir.
  ///
  /// Uma lista vazia é ignorada, como nas opções: a coluna vazia significa
  /// "o usuário nunca escolheu", e traria de volta as moedas padrão sem ele
  /// ter pedido.
  Future<void> saveHomeCurrencies(List<Currencies> currencies) async {
    if (currencies.isEmpty) return;
    var configuration = await _configurationRepository.getConfiguration();
    configuration.homeCurrencyCodes = currencies.map(currencyCode).toList();
    await _configurationRepository.insert(configuration);
  }

  /// Moeda usada como contrapartida das cotações, quando o app a conhece.
  ///
  /// É o outro lado de cada bolha: a bolha do dólar mostra quanto vale um dólar
  /// nela. A tela usa isso para abrir a conversão no mesmo par que a bolha
  /// tocada mostrava. Nulo se a moeda escolhida nas configurações não estiver
  /// entre as que o app conhece — aí a tela de conversão fica com o destino
  /// padrão dela.
  Future<Currencies?> loadCounterCurrency() async =>
      currencyForCode(await _currencyRepository.resolveCounterCurrency());

  Stream<String?> getNextStreamController() {
    if (_headsUpTextStreamController == null) {
      _headsUpTextStreamController = StreamController();
      return _headsUpTextStreamController!.stream;
    } else if (!_headsUpTextStreamController!.hasListener) {
      return _headsUpTextStreamController!.stream;
    } else {
      _headsUpTextStreamController!.close();
      _headsUpTextStreamController = StreamController();
      return _headsUpTextStreamController!.stream;
    }
  }

  /// Publica o nome da moeda em que as cotações das bolhas estão expressas:
  /// cada bolha mostra quanto vale uma unidade da sua moeda na contrapartida
  /// usada hoje (ver [CurrencyRepository.resolveCounterCurrency]), que é o real
  /// ou a moeda escolhida nas configurações — e não o dólar, que é só mais uma
  /// das moedas cotadas.
  ///
  /// O nome vem do mapa local de nomes, e não do `friendlyName` gravado com a
  /// cotação: a contrapartida não é cotada contra ela mesma, então não existe
  /// registro com o nome dela vindo da API.
  Future<void> loadCounterCurrencyName(Locale locale) async {
    var counterCurrencyCode =
        await _currencyRepository.resolveCounterCurrency();
    // A stream pode ter sido fechada enquanto a configuração era lida, se a
    // tela saiu da árvore nesse meio-tempo.
    var controller = _headsUpTextStreamController;
    if (controller == null || controller.isClosed) return;
    controller.sink.add(currencyNameForCode(counterCurrencyCode, locale));
  }

  @override
  void dispose() {
    // Pode não haver controller se o bloc foi descartado antes de a tela
    // chegar a construir a stream.
    _headsUpTextStreamController?.close();
  }
}
