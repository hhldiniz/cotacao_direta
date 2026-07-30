import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:cotacao_direta/util/currency_name.dart';
import 'package:flutter/widgets.dart';

class HomeBloc extends BaseBloc {
  final CurrencyRepository _currencyRepository;
  StreamController<String?>? _headsUpTextStreamController;

  HomeBloc({CurrencyRepository? currencyRepository})
      : _currencyRepository = currencyRepository ?? CurrencyRepository();

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
