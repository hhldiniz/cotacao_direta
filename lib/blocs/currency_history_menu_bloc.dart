import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/repository/country_names_repository.dart';

class CurrencyHistoryMenuBloc extends BaseBloc {
  final CountryNamesRepository _countryNameRepository;
  final Map<String, StreamController<String?>> _countryNameControllerMap = {};
  final Map<String, String?> _savedCountryNamesByCurrencyCod = {};
  final Set<String> _pendingRequests = {};

  CurrencyHistoryMenuBloc({CountryNamesRepository? countryNamesRepository})
      : _countryNameRepository =
            countryNamesRepository ?? CountryNamesRepository();

  /// Cria um controller por moeda. É idempotente de propósito: a tela chama
  /// isto a cada build, e recriar os controllers deixaria os anteriores
  /// abertos, com os ouvintes presos neles.
  void initStreamControllers(List<String> currencyCodList) {
    for (var currencyCode in currencyCodList) {
      _countryNameControllerMap.putIfAbsent(
          currencyCode, () => StreamController<String?>.broadcast());
    }
  }

  Stream<String?>? getCountryNameController(String currencyCod) =>
      _countryNameControllerMap[currencyCod]?.stream;

  /// Nome já conhecido, para a tela mostrá-lo enquanto a stream (que é
  /// broadcast e não repete o último evento) ainda não emitiu nada.
  String? cachedCountryName(String currencyCod) =>
      _savedCountryNamesByCurrencyCod[currencyCod];

  Future<void> getCountryNameByCurrencyCode(String currencyCode) async {
    // Uma vez resolvido, o nome não é buscado de novo: como esta chamada sai de
    // dentro do builder da lista, repetir dispararia uma requisição por
    // rebuild, e cada resposta provocaria o rebuild seguinte.
    if (_savedCountryNamesByCurrencyCod.containsKey(currencyCode)) return;
    if (!_pendingRequests.add(currencyCode)) return;
    try {
      String? countryName = await _countryNameRepository
          .getCountryNameByCurrencyCode(currencyCode);
      _savedCountryNamesByCurrencyCod[currencyCode] = countryName;
      _countryNameControllerMap[currencyCode]?.add(countryName);
    } catch (_) {
      // Guarda a falha para não repetir a chamada a cada rebuild. Uma nova
      // visita à tela cria outro bloc e tenta de novo.
      _savedCountryNamesByCurrencyCod[currencyCode] = null;
    } finally {
      _pendingRequests.remove(currencyCode);
    }
  }

  @override
  void dispose() {
    _countryNameControllerMap.values.forEach((controller) {
      controller.close();
    });
    _countryNameControllerMap.clear();
  }
}
