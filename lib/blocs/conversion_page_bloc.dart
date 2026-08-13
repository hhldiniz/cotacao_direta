import 'dart:async';

import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';

import 'exchange_value_bloc.dart';

/// Em que pé está a conversão mostrada na tela.
enum ConversionStatus {
  /// Buscando as cotações das duas moedas.
  loading,

  /// Há um valor convertido para mostrar.
  success,

  /// Falta a cotação de alguma das moedas, então não há conversão possível.
  unavailable,
}

/// Tudo o que a tela precisa para desenhar uma conversão de uma vez só: o
/// valor convertido sozinho não basta, porque a tela também mostra a que
/// quantidade e a que par de moedas ele corresponde e qual foi a cotação
/// usada. Em streams separadas esses dados chegariam em momentos diferentes e
/// a tela piscaria combinações que nunca existiram (o valor novo com o par
/// antigo, por exemplo).
class ConversionResult {
  final ConversionStatus status;

  /// Quantidade informada pelo usuário, na moeda [from].
  final double amount;
  final Currencies from;
  final Currencies to;

  /// [amount] convertido para [to]; nulo enquanto não houver cotação.
  final double? convertedAmount;

  /// Quanto vale uma unidade de [from] em [to]; nulo enquanto não houver
  /// cotação.
  final double? unitRate;

  const ConversionResult({
    required this.status,
    required this.amount,
    required this.from,
    required this.to,
    this.convertedAmount,
    this.unitRate,
  });

  /// O caminho contrário: quanto vale uma unidade de [to] em [from].
  double? get inverseUnitRate =>
      unitRate == null || unitRate == 0 ? null : 1 / unitRate!;

  bool get hasValue => convertedAmount != null && unitRate != null;

  bool get isLoading => status == ConversionStatus.loading;
}

class ConversionPageBloc extends BaseBloc {
  static const initialAmount = 1.0;

  /// O par que a tela abre escolhido quando quem a abriu não pediu outro.
  static const defaultFromCurrency = Currencies.BRL;
  static const defaultToCurrency = Currencies.USD;

  // Broadcast porque mais de um trecho da tela acompanha a mesma informação
  // (a moeda de origem aparece no campo de quantidade e no seletor, por
  // exemplo) e um StreamController comum só aceita um ouvinte.
  final _amountController = StreamController<double>.broadcast();
  final _currencyFromController = StreamController<Currencies>.broadcast();
  final _currencyToController = StreamController<Currencies>.broadcast();
  final _conversionResultController =
      StreamController<ConversionResult>.broadcast();

  final ExchangeValueBloc _exchangeValueBloc;

  /// Só descarta o bloc de cotações se foi ele quem o criou: um bloc recebido
  /// de fora pertence a quem o passou.
  final bool _ownsExchangeValueBloc;

  /// Moedas que a tela de origem quer ver no topo do seletor — na prática, as
  /// que estão em bolha na tela inicial. Quem chegou aqui tocando numa bolha
  /// muito provavelmente vai querer converter para outra das suas moedas, e
  /// não para uma das mais de trinta que a lista tem.
  final List<Currencies> priorityCurrencies;

  /// [initialFromCurrency] e [initialToCurrency] são o par que a tela abre já
  /// escolhido: tocar na bolha do dólar na tela inicial abre esta tela
  /// convertendo dólar para a contrapartida das cotações, o mesmo que a bolha
  /// mostrava. Sem eles vale o par padrão (real para dólar).
  ConversionPageBloc({
    ExchangeValueBloc? exchangeValueBloc,
    Currencies? initialFromCurrency,
    Currencies? initialToCurrency,
    List<Currencies> priorityCurrencies = const [],
  })  : _exchangeValueBloc = exchangeValueBloc ?? ExchangeValueBloc(),
        _ownsExchangeValueBloc = exchangeValueBloc == null,
        priorityCurrencies = List.unmodifiable(priorityCurrencies),
        _fromCurrency = initialFromCurrency ?? defaultFromCurrency,
        _toCurrency = _resolveToCurrency(
            initialFromCurrency ?? defaultFromCurrency, initialToCurrency) {
    _result = ConversionResult(
        status: ConversionStatus.loading,
        amount: _amount,
        from: _fromCurrency,
        to: _toCurrency);
  }

  /// O destino pedido por quem abriu a tela, desde que ele não seja a própria
  /// moeda de origem: uma moeda convertida para ela mesma não diria nada. Nesse
  /// caso vale o outro lado do par padrão, para a tela abrir com uma conversão
  /// de verdade — tocar na bolha do real com o real de contrapartida abre real
  /// para dólar.
  static Currencies _resolveToCurrency(Currencies from, Currencies? candidate) {
    if (candidate != null && candidate != from) return candidate;
    return from == defaultToCurrency ? defaultFromCurrency : defaultToCurrency;
  }

  var _amount = initialAmount;
  Currencies _fromCurrency;
  Currencies _toCurrency;

  late ConversionResult _result;

  /// Cada conversão leva um número de ordem para que a resposta de uma
  /// conversão antiga — a busca das cotações é assíncrona — não sobrescreva o
  /// resultado de uma conversão pedida depois dela.
  var _lastRequestId = 0;

  var _disposed = false;

  Stream<double> get amountStream => _amountController.stream;

  Sink<double> get amountSink => _amountController.sink;

  Stream<Currencies> get currencyFromStream => _currencyFromController.stream;

  Sink<Currencies> get currencyFromSink => _currencyFromController.sink;

  Stream<Currencies> get currencyToStream => _currencyToController.stream;

  Sink<Currencies> get currencyToSink => _currencyToController.sink;

  Stream<ConversionResult> get conversionResultStream =>
      _conversionResultController.stream;

  Sink<ConversionResult> get conversionResultSink =>
      _conversionResultController.sink;

  /// Estado atual, para a tela desenhar o primeiro quadro sem esperar a
  /// primeira emissão das streams.
  double get amount => _amount;

  Currencies get fromCurrency => _fromCurrency;

  Currencies get toCurrency => _toCurrency;

  ConversionResult get result => _result;

  /// Quantidade a converter. Um texto vazio ou inválido na tela vira zero, que
  /// converte para zero em vez de deixar o resultado anterior no lugar.
  void updateAmount(double? value) {
    _amount = value ?? 0;
    _amountController.add(_amount);
    updateResult();
  }

  /// Escolher para a origem a moeda que já está no destino inverte o par, em
  /// vez de deixar as duas pontas iguais: é o que o usuário quis dizer ao
  /// escolher "converter para" a moeda que estava convertendo.
  void updateFromCurrency(Currencies value) {
    if (value == _toCurrency) return switchCurrencies();
    _fromCurrency = value;
    _currencyFromController.add(value);
    updateResult();
  }

  void updateToCurrency(Currencies value) {
    if (value == _fromCurrency) return switchCurrencies();
    _toCurrency = value;
    _currencyToController.add(value);
    updateResult();
  }

  void switchCurrencies() {
    var previousFromCurrency = _fromCurrency;
    _fromCurrency = _toCurrency;
    _toCurrency = previousFromCurrency;
    _currencyFromController.add(_fromCurrency);
    _currencyToController.add(_toCurrency);
    updateResult();
  }

  Future<void> updateResult() async {
    var requestId = ++_lastRequestId;
    var amount = _amount;
    var from = _fromCurrency;
    var to = _toCurrency;
    _emit(_loadingResult());

    var rate = await _unitRate(from, to);

    // Chegou tarde: outra conversão já foi pedida (ou a tela foi embora).
    if (_disposed || requestId != _lastRequestId) return;
    _emit(ConversionResult(
      status: rate == null ? ConversionStatus.unavailable : ConversionStatus.success,
      amount: amount,
      from: from,
      to: to,
      unitRate: rate,
      convertedAmount: rate == null ? null : amount * rate,
    ));
  }

  /// Quantas unidades de [to] valem uma unidade de [from], ou nulo quando
  /// falta a cotação de alguma das duas.
  Future<double?> _unitRate(Currencies from, Currencies to) async {
    // Uma moeda vale exatamente uma unidade dela mesma; a cotação do par nem
    // existe.
    if (from == to) return 1;
    try {
      var fromValue = await _exchangeValueBloc.retrieveCurrencyValue(from);
      var toValue = await _exchangeValueBloc.retrieveCurrencyValue(to);
      // As cotações guardadas dizem quantas unidades da moeda valem uma
      // unidade da contrapartida (ver CurrencyRepository), então a taxa entre
      // duas moedas é a razão entre elas.
      if (fromValue == null || fromValue == 0 || toValue == null) return null;
      return toValue / fromValue;
    } catch (exception) {
      // Sem rede e sem nada salvo a busca pode falhar; para a tela é o mesmo
      // que não ter cotação.
      return null;
    }
  }

  /// Enquanto as cotações não chegam, o par que já estava na tela continua
  /// mostrando seu último valor (recalculado para a quantidade nova) para que
  /// a tela não pisque em branco a cada tecla digitada.
  ConversionResult _loadingResult() {
    var keepsRate = _result.from == _fromCurrency && _result.to == _toCurrency;
    var rate = keepsRate ? _result.unitRate : null;
    return ConversionResult(
      status: ConversionStatus.loading,
      amount: _amount,
      from: _fromCurrency,
      to: _toCurrency,
      unitRate: rate,
      convertedAmount: rate == null ? null : _amount * rate,
    );
  }

  void _emit(ConversionResult result) {
    _result = result;
    _conversionResultController.add(result);
  }

  @override
  void dispose() {
    _disposed = true;
    _amountController.close();
    _currencyFromController.close();
    _currencyToController.close();
    _conversionResultController.close();
    if (_ownsExchangeValueBloc) _exchangeValueBloc.dispose();
  }
}
