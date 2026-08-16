import 'dart:async';

import 'package:cotacao_direta/blocs/conversion_page_bloc.dart';
import 'package:cotacao_direta/blocs/exchange_value_bloc.dart';
import 'package:cotacao_direta/enums/currency_enum.dart';
import 'package:cotacao_direta/model/currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers/fakes.dart';

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

/// Uma cotação de um dia, na convenção do CurrencyRepository.
Currency _quote(String currencyCode, DateTime date, double value) => Currency(
    id: currencyCode,
    value: value,
    historicalDate: date.toIso8601String(),
    counterCurrency: "BRL");

DateTime _daysAgo(int days) {
  var today = DateTime.now();
  return DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: days));
}

void main() {
  late _FakeExchangeValueBloc exchangeValueBloc;
  late FakeCurrencyRepository currencyRepository;
  late ConversionPageBloc bloc;

  setUp(() {
    exchangeValueBloc = _FakeExchangeValueBloc({
      Currencies.BRL: 1,
      Currencies.USD: 0.2,
      Currencies.EUR: 0.1,
      Currencies.JPY: null,
    });
    currencyRepository = FakeCurrencyRepository();
    bloc = ConversionPageBloc(
        exchangeValueBloc: exchangeValueBloc,
        currencyRepository: currencyRepository);
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
          exchangeValueBloc: _FakeExchangeValueBloc({Currencies.BRL: 1}),
          currencyRepository: currencyRepository);

      bloc.dispose();

      expect(() => bloc.amountSink.add(1), throwsStateError);
      expect(() => bloc.currencyFromSink.add(Currencies.USD), throwsStateError);
      expect(() => bloc.currencyToSink.add(Currencies.USD), throwsStateError);
      expect(
          () => bloc.conversionResultSink.add(bloc.result), throwsStateError);
      expect(() => bloc.conversionHistorySink.add(bloc.history),
          throwsStateError);
    });

    test('abre no par pedido por quem chamou a tela', () async {
      var bloc = ConversionPageBloc(
          exchangeValueBloc: exchangeValueBloc,
          currencyRepository: currencyRepository,
          initialFromCurrency: Currencies.USD,
          initialToCurrency: Currencies.EUR);
      addTearDown(bloc.dispose);

      expect(bloc.fromCurrency, Currencies.USD);
      expect(bloc.toCurrency, Currencies.EUR);
      expect(bloc.result.from, Currencies.USD,
          reason: "a tela desenha o primeiro quadro a partir do resultado");
      expect(bloc.result.to, Currencies.EUR);
    });

    test('só a origem pedida deixa o destino no padrão', () async {
      var bloc = ConversionPageBloc(
          exchangeValueBloc: exchangeValueBloc,
          currencyRepository: currencyRepository,
          initialFromCurrency: Currencies.EUR);
      addTearDown(bloc.dispose);

      expect(bloc.fromCurrency, Currencies.EUR);
      expect(bloc.toCurrency, Currencies.USD);
    });

    test('o mesmo par dos dois lados vira uma conversão de verdade', () async {
      // Acontece com a bolha da própria moeda de contrapartida: a tela inicial
      // pede real para real.
      var bloc = ConversionPageBloc(
          exchangeValueBloc: exchangeValueBloc,
          currencyRepository: currencyRepository,
          initialFromCurrency: Currencies.BRL,
          initialToCurrency: Currencies.BRL);
      addTearDown(bloc.dispose);

      expect(bloc.fromCurrency, Currencies.BRL);
      expect(bloc.toCurrency, Currencies.USD);

      var dollarBloc = ConversionPageBloc(
          exchangeValueBloc: exchangeValueBloc,
          currencyRepository: currencyRepository,
          initialFromCurrency: Currencies.USD,
          initialToCurrency: Currencies.USD);
      addTearDown(dollarBloc.dispose);

      expect(dollarBloc.fromCurrency, Currencies.USD);
      expect(dollarBloc.toCurrency, Currencies.BRL,
          reason: "o outro lado do par padrão, para o par não ficar repetido");
    });

    test('converte o par pedido sem esperar nenhuma escolha', () async {
      var bloc = ConversionPageBloc(
          exchangeValueBloc: exchangeValueBloc,
          currencyRepository: currencyRepository,
          initialFromCurrency: Currencies.USD,
          initialToCurrency: Currencies.BRL);
      addTearDown(bloc.dispose);

      await bloc.updateResult();

      expect(bloc.result.unitRate, closeTo(5, 0.000001),
          reason: "um dólar vale cinco reais nas cotações do teste");
    });

    test('guarda as moedas em destaque para o seletor', () async {
      var bloc = ConversionPageBloc(
          exchangeValueBloc: exchangeValueBloc,
          currencyRepository: currencyRepository,
          priorityCurrencies: [Currencies.EUR, Currencies.JPY]);
      addTearDown(bloc.dispose);

      expect(bloc.priorityCurrencies, [Currencies.EUR, Currencies.JPY]);
      expect(() => bloc.priorityCurrencies.add(Currencies.USD),
          throwsUnsupportedError,
          reason: "a lista é do bloc, não de quem a leu");
    });

    test('sem moedas em destaque a lista fica vazia', () async {
      expect(bloc.priorityCurrencies, isEmpty);
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

  group('ConversionPageBloc: histórico do par', () {
    final apiDateFormatter = DateFormat("yyyy-MM-dd");

    ConversionPageBloc buildBloc(
        {Currencies? initialFromCurrency, Currencies? initialToCurrency}) {
      var bloc = ConversionPageBloc(
          exchangeValueBloc: exchangeValueBloc,
          currencyRepository: currencyRepository,
          initialFromCurrency: initialFromCurrency,
          initialToCurrency: initialToCurrency);
      addTearDown(bloc.dispose);
      return bloc;
    }

    test('a série do par é a razão entre as séries das duas moedas', () async {
      // A API cota cada moeda frente ao real; a cotação de euro em dólar não
      // vem pronta de lugar nenhum.
      currencyRepository.historicalDataByCode["EUR"] = [
        _quote("EUR", _daysAgo(2), 0.1),
        _quote("EUR", _daysAgo(1), 0.1),
      ];
      currencyRepository.historicalDataByCode["USD"] = [
        _quote("USD", _daysAgo(2), 0.2),
        _quote("USD", _daysAgo(1), 0.25),
      ];
      var bloc = buildBloc(
          initialFromCurrency: Currencies.EUR,
          initialToCurrency: Currencies.USD);

      await bloc.loadHistory();

      expect(bloc.history.status, ConversionHistoryStatus.ready);
      expect(bloc.history.from, Currencies.EUR);
      expect(bloc.history.to, Currencies.USD);
      expect(bloc.history.points.map((point) => point.rate),
          [closeTo(2, 0.000001), closeTo(2.5, 0.000001)],
          reason: "um euro valia dois dólares e passou a valer dois e meio");
      expect(bloc.history.points.first.date.isBefore(bloc.history.points.last.date),
          isTrue,
          reason: "o gráfico é desenhado do dia mais antigo para o mais novo");
    });

    test('a contrapartida das cotações vale uma unidade todo dia', () async {
      // BRL é a contrapartida: ela não tem série própria (o repositório pula a
      // consulta), e sem tratamento o gráfico do par mais comum ficaria vazio.
      currencyRepository.historicalDataByCode["USD"] = [
        _quote("USD", _daysAgo(2), 0.2),
        _quote("USD", _daysAgo(1), 0.25),
      ];
      var bloc = buildBloc(
          initialFromCurrency: Currencies.BRL,
          initialToCurrency: Currencies.USD);

      await bloc.loadHistory();

      expect(bloc.history.points.map((point) => point.rate),
          [closeTo(0.2, 0.000001), closeTo(0.25, 0.000001)]);
      expect(currencyRepository.historicalDataCalls.map((call) => call.first),
          [["USD"]],
          reason: "não há o que pedir para a moeda da contrapartida");
    });

    test('o período pedido é a última semana', () async {
      var bloc = buildBloc();

      await bloc.loadHistory();

      var today = DateTime.now();
      expect(ConversionPageBloc.historyWindowInDays, 7);
      expect(currencyRepository.historicalDataCalls.single.sublist(1), [
        apiDateFormatter.format(today.subtract(const Duration(days: 6))),
        apiDateFormatter.format(today)
      ]);
    });

    test('só os dias com cotação das duas moedas entram no gráfico', () async {
      // Feriado em um dos mercados: completar o dia que falta desenharia uma
      // variação que não houve.
      currencyRepository.historicalDataByCode["EUR"] = [
        _quote("EUR", _daysAgo(2), 0.1),
        _quote("EUR", _daysAgo(1), 0.1),
      ];
      currencyRepository.historicalDataByCode["USD"] = [
        _quote("USD", _daysAgo(3), 0.2),
        _quote("USD", _daysAgo(2), 0.2),
        _quote("USD", _daysAgo(1), 0.25),
      ];
      var bloc = buildBloc(
          initialFromCurrency: Currencies.EUR,
          initialToCurrency: Currencies.USD);

      await bloc.loadHistory();

      expect(bloc.history.points.length, 2);
      expect(bloc.history.points.first.date, _daysAgo(2));
    });

    test('cotações do mesmo dia não viram dois pontos', () async {
      currencyRepository.historicalDataByCode["USD"] = [
        _quote("USD", _daysAgo(2), 0.2),
        _quote("USD", _daysAgo(1).add(const Duration(hours: 10)), 0.24),
        _quote("USD", _daysAgo(1).add(const Duration(hours: 17)), 0.25),
      ];
      var bloc = buildBloc();

      await bloc.loadHistory();

      expect(bloc.history.points.length, 2);
      expect(bloc.history.points.last.rate, closeTo(0.25, 0.000001),
          reason: "vale a cotação mais recente do dia");
    });

    test('um ponto só não vira gráfico', () async {
      currencyRepository.historicalDataByCode["USD"] = [
        _quote("USD", _daysAgo(1), 0.2),
      ];
      var bloc = buildBloc();

      await bloc.loadHistory();

      expect(bloc.history.status, ConversionHistoryStatus.unavailable);
      expect(bloc.history.points, isEmpty);
    });

    test('a busca que falha deixa a tela sem histórico', () async {
      // Sem rede e sem nada salvo; para a tela é o mesmo que não ter histórico.
      currencyRepository.failure = Exception("sem rede");
      var bloc = buildBloc();

      await bloc.loadHistory();

      expect(bloc.history.status, ConversionHistoryStatus.unavailable);
    });

    test('anuncia o histórico pela stream', () async {
      currencyRepository.historicalDataByCode["USD"] = [
        _quote("USD", _daysAgo(2), 0.2),
        _quote("USD", _daysAgo(1), 0.25),
      ];
      var bloc = buildBloc();
      var emitted = <ConversionHistory>[];
      bloc.conversionHistoryStream.listen(emitted.add);

      await bloc.loadHistory();
      // A stream é broadcast: os eventos chegam a quem escuta no ciclo
      // seguinte do laço de eventos.
      await Future<void>.delayed(Duration.zero);

      expect(emitted.first.isLoading, isTrue);
      expect(emitted.last.status, ConversionHistoryStatus.ready);
    });

    test('trocar de moeda busca o histórico do par novo', () async {
      var bloc = buildBloc();

      bloc.updateToCurrency(Currencies.EUR);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.history.to, Currencies.EUR);
      expect(currencyRepository.historicalDataCalls.map((call) => call.first),
          anyElement(equals(["EUR"])));
    });

    test('inverter o par redesenha o gráfico ao contrário', () async {
      currencyRepository.historicalDataByCode["USD"] = [
        _quote("USD", _daysAgo(2), 0.2),
        _quote("USD", _daysAgo(1), 0.25),
      ];
      var bloc = buildBloc();
      await bloc.loadHistory();

      bloc.switchCurrencies();
      await Future<void>.delayed(Duration.zero);

      expect(bloc.history.from, Currencies.USD);
      expect(bloc.history.to, Currencies.BRL);
      expect(bloc.history.points.map((point) => point.rate),
          [closeTo(5, 0.000001), closeTo(4, 0.000001)],
          reason: "um dólar valia cinco reais e passou a valer quatro");
    });

    test('o gráfico do par anterior fica na tela enquanto o novo não chega',
        () async {
      currencyRepository.historicalDataByCode["USD"] = [
        _quote("USD", _daysAgo(2), 0.2),
        _quote("USD", _daysAgo(1), 0.25),
      ];
      var bloc = buildBloc();
      await bloc.loadHistory();

      var reload = bloc.loadHistory();

      expect(bloc.history.isLoading, isTrue);
      expect(bloc.history.hasPoints, isTrue,
          reason: "a linha some da tela a cada atualização se for descartada");
      await reload;
    });

    test('não emite histórico depois de descartado', () async {
      var bloc = ConversionPageBloc(
          exchangeValueBloc: exchangeValueBloc,
          currencyRepository: currencyRepository);

      var loading = bloc.loadHistory();
      bloc.dispose();

      // Emitir numa stream fechada lançaria, e o erro chegaria aqui.
      await loading;
    });
  });
}
