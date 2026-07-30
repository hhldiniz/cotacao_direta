import 'dart:async';

import 'package:cotacao_direta/blocs/conversion_page_bloc.dart';
import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cotações fixas por moeda, no lugar da busca real (rede e banco).
///
/// Os valores seguem a convenção do CurrencyRepository: quantas unidades da
/// moeda valem uma unidade da contrapartida (BRL). Com BRL em 1 e USD em 0,2,
/// um real vale vinte centavos de dólar.
class _FakeExchangeValueBloc extends ExchangeValueBloc {
  final Map<Currencies, double?> values;

  /// Conversões pendentes, para simular uma busca que demora e chega atrasada.
  final List<Completer<void>> pendingLookups = [];
  bool holdLookups = false;

  final List<Currencies?> requestedCurrencies = [];

  _FakeExchangeValueBloc(this.values);

  @override
  Future<double?> retrieveCurrencyValue(Currencies? currency) async {
    requestedCurrencies.add(currency);
    if (holdLookups) {
      var completer = Completer<void>();
      pendingLookups.add(completer);
      await completer.future;
    }
    return values[currency];
  }
}

void main() {
  late _FakeExchangeValueBloc exchangeValueBloc;
  late ConversionPageBloc bloc;

  setUp(() {
    exchangeValueBloc = _FakeExchangeValueBloc({
      Currencies.BRL: 1,
      Currencies.USD: 0.2,
      Currencies.EUR: 0.1,
      Currencies.JPY: null,
    });
    bloc = ConversionPageBloc(exchangeValueBloc: exchangeValueBloc);
  });

  tearDown(() => bloc.dispose());

  group('ConversionPageBloc', () {
    test('abre convertendo uma unidade de real para dólar', () {
      expect(bloc.amount, 1);
      expect(bloc.fromCurrency, Currencies.BRL);
      expect(bloc.toCurrency, Currencies.USD);
    });

    test('converte pela razão entre as cotações das duas moedas', () async {
      bloc.updateAmount(10);

      await bloc.updateResult();

      expect(bloc.result.status, ConversionStatus.success);
      expect(bloc.result.unitRate, closeTo(0.2, 0.000001));
      expect(bloc.result.convertedAmount, closeTo(2, 0.000001));
    });

    test('a taxa inversa é o caminho de volta', () async {
      await bloc.updateResult();

      expect(bloc.result.inverseUnitRate, closeTo(5, 0.000001));
    });

    test('converte sozinho ao mudar a quantidade', () async {
      bloc.updateAmount(3);
      // O emitido em seguida é o resultado carregando; o valor final vem
      // quando as cotações chegam.
      await Future<void>.delayed(Duration.zero);

      expect(bloc.result.convertedAmount, closeTo(0.6, 0.000001));
    });

    test('sem cotação de uma das moedas não há conversão', () async {
      bloc.updateToCurrency(Currencies.JPY);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.result.status, ConversionStatus.unavailable);
      expect(bloc.result.convertedAmount, isNull);
      expect(bloc.result.unitRate, isNull);
    });

    test('uma moeda vale uma unidade dela mesma', () async {
      // BRL para BRL: a API não tem esse par, então a taxa não vem de busca
      // nenhuma.
      bloc.updateToCurrency(Currencies.BRL);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.fromCurrency, Currencies.USD,
          reason: "escolher no destino a moeda de origem inverte o par");
      expect(bloc.toCurrency, Currencies.BRL);

      bloc.updateFromCurrency(Currencies.BRL);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.fromCurrency, Currencies.BRL);
      expect(bloc.toCurrency, Currencies.USD);
    });

    test('inverter troca as duas moedas de lugar e reconverte', () async {
      bloc.updateAmount(4);
      await Future<void>.delayed(Duration.zero);

      bloc.switchCurrencies();
      await Future<void>.delayed(Duration.zero);

      expect(bloc.fromCurrency, Currencies.USD);
      expect(bloc.toCurrency, Currencies.BRL);
      expect(bloc.result.unitRate, closeTo(5, 0.000001));
      expect(bloc.result.convertedAmount, closeTo(20, 0.000001));
    });

    test('anuncia o resultado pela stream', () async {
      var emitted = <ConversionResult>[];
      bloc.conversionResultStream.listen(emitted.add);

      bloc.updateAmount(2);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.first.isLoading, isTrue,
          reason: "a tela precisa saber que a cotação está sendo buscada");
      expect(emitted.last.status, ConversionStatus.success);
      expect(emitted.last.convertedAmount, closeTo(0.4, 0.000001));
    });

    test('mantém a última taxa do par enquanto busca a cotação nova', () async {
      await bloc.updateResult();

      exchangeValueBloc.holdLookups = true;
      bloc.updateAmount(7);

      expect(bloc.result.isLoading, isTrue);
      expect(bloc.result.convertedAmount, closeTo(1.4, 0.000001),
          reason: "o valor some da tela se a conversão anterior for descartada");
    });

    test('a conversão que chega atrasada não sobrescreve a mais recente',
        () async {
      exchangeValueBloc.holdLookups = true;
      bloc.updateToCurrency(Currencies.EUR);
      var lateLookups = List.of(exchangeValueBloc.pendingLookups);

      // A segunda conversão é pedida antes de a primeira responder, e responde
      // primeiro.
      exchangeValueBloc.holdLookups = false;
      bloc.updateToCurrency(Currencies.USD);
      await Future<void>.delayed(Duration.zero);
      for (var lookup in lateLookups) {
        lookup.complete();
      }
      await Future<void>.delayed(Duration.zero);

      expect(bloc.result.to, Currencies.USD);
      expect(bloc.result.unitRate, closeTo(0.2, 0.000001));
    });

    test('descartar fecha as streams', () async {
      var bloc = ConversionPageBloc(
          exchangeValueBloc: _FakeExchangeValueBloc({Currencies.BRL: 1}));

      bloc.dispose();

      expect(() => bloc.amountSink.add(1), throwsStateError);
      expect(() => bloc.currencyFromSink.add(Currencies.USD), throwsStateError);
      expect(() => bloc.currencyToSink.add(Currencies.USD), throwsStateError);
      expect(
          () => bloc.conversionResultSink.add(bloc.result), throwsStateError);
    });

    test('não emite resultado depois de descartado', () async {
      exchangeValueBloc.holdLookups = true;
      var conversion = bloc.updateResult();
      bloc.dispose();

      exchangeValueBloc.holdLookups = false;
      for (var lookup in exchangeValueBloc.pendingLookups) {
        lookup.complete();
      }

      // Emitir numa stream fechada lançaria, e o erro chegaria aqui.
      await conversion;
    });
  });
}
