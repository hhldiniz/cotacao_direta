import 'package:cotacao_direta/ai/financial_ai_service.dart';
import 'package:cotacao_direta/blocs/ai_insights_bloc.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/series_test_helper.dart';

void main() {
  late FakeCurrencyRepository repository;
  late AiInsightsBloc bloc;

  setUp(() {
    repository = FakeCurrencyRepository()
      ..historicalData =
          quoteHistoryFromPrices(syntheticPrices(length: 120));
    bloc = AiInsightsBloc(currencyRepository: repository);
  });

  tearDown(() => bloc.dispose());

  group('AiInsightsBloc.analyze', () {
    test('emite carregando e depois o resultado', () async {
      final states = <AiInsightsState>[];
      bloc.stateStream.listen(states.add);

      await bloc.analyze();
      // A stream é broadcast: a entrega aos ouvintes é agendada, então o último
      // evento só chega depois de o laço de eventos girar.
      await pumpEventQueue();

      expect(states.first.loading, isTrue);
      expect(states.last.hasAnalysis, isTrue);
      expect(states.last.analysis!.assetCode, "USD");
      expect(states.last.error, isNull);
    });

    test('o estado final fica disponível para quem chegar depois', () async {
      await bloc.analyze();

      expect(bloc.currentState.hasAnalysis, isTrue);
      expect(bloc.currentState.loading, isFalse);
    });

    test('pede o histórico do ativo selecionado', () async {
      bloc.selectAsset("BTC", AssetKind.cryptocurrency);

      await bloc.analyze();

      expect(repository.historicalDataCalls.single.first, ["BTC"]);
      expect(bloc.currentState.analysis!.assetKind,
          AssetKind.cryptocurrency);
    });

    test('pede a janela de histórico configurada, em datas da API', () async {
      await bloc.analyze();

      final call = repository.historicalDataCalls.single;
      final start = DateTime.parse(call[1] as String);
      final end = DateTime.parse(call[2] as String);

      // O horário de verão de alguns fusos encurta um dos dias do intervalo.
      expect(
          end.difference(start).inDays,
          inInclusiveRange(AiInsightsBloc.historyWindowInDays - 1,
              AiInsightsBloc.historyWindowInDays));
    });

    test('usa a moeda de contrapartida resolvida pelo repositório', () async {
      repository.counterCurrency = "EUR";

      await bloc.analyze();

      expect(bloc.currentState.analysis!.series.quoteCurrency, "EUR");
    });

    test('projeta o horizonte selecionado', () async {
      bloc.selectHorizon(7);

      await bloc.analyze();

      expect(bloc.currentState.analysis!.forecast.points.length, 7);
    });

    test('sem cotação nenhuma reporta ausência de dados', () async {
      repository.historicalData = [];

      await bloc.analyze();

      expect(bloc.currentState.error, AiInsightsError.noData);
      expect(bloc.currentState.hasAnalysis, isFalse);
    });

    test('histórico curto demais é reportado como tal', () async {
      repository.historicalData = quoteHistoryFromPrices(
          syntheticPrices(length: FinancialAiService.minimumPoints - 1));

      await bloc.analyze();

      expect(bloc.currentState.error, AiInsightsError.insufficientData);
    });

    test('falha do repositório vira erro genérico, sem derrubar o bloc',
        () async {
      repository.failure = Exception("sem rede");

      await bloc.analyze();

      expect(bloc.currentState.error, AiInsightsError.failure);
    });

    test('uma resposta atrasada não sobrescreve o pedido mais novo', () async {
      final primeira = bloc.analyze();
      bloc.selectAsset("EUR", AssetKind.currency);
      await bloc.analyze();
      await primeira;

      expect(bloc.currentState.analysis!.assetCode, "EUR");
    });
  });

  group('AiInsightsBloc seleção', () {
    test('trocar de ativo limpa o resultado anterior', () async {
      await bloc.analyze();
      expect(bloc.currentState.hasAnalysis, isTrue);

      bloc.selectAsset("EUR", AssetKind.currency);

      expect(bloc.currentState.hasAnalysis, isFalse);
      expect(bloc.selectedAssetCode, "EUR");
    });

    test('selecionar o mesmo ativo não mexe no resultado', () async {
      await bloc.analyze();

      bloc.selectAsset("USD", AssetKind.currency);

      expect(bloc.currentState.hasAnalysis, isTrue);
    });

    test('trocar o horizonte com resultado na tela refaz a análise', () async {
      await bloc.analyze();
      expect(bloc.currentState.analysis!.forecast.points.length, 15);

      bloc.selectHorizon(30);
      // A reanálise é assíncrona: espera o estado final voltar.
      await bloc.stateStream.firstWhere((state) => state.hasAnalysis);

      expect(bloc.currentState.analysis!.forecast.points.length, 30);
      expect(bloc.horizonInDays, 30);
    });

    test('trocar o horizonte sem resultado não consulta o repositório', () {
      bloc.selectHorizon(7);

      expect(repository.historicalDataCalls, isEmpty);
      expect(bloc.horizonInDays, 7);
    });

    test('a moeda de contrapartida é resolvida uma única vez', () async {
      final first = await bloc.counterCurrencyCode;
      repository.counterCurrency = "EUR";
      final second = await bloc.counterCurrencyCode;

      expect(first, "BRL");
      expect(second, "BRL");
    });
  });

  group('AiInsightsBloc.parseAmount', () {
    test('aceita o formato brasileiro', () {
      expect(AiInsightsBloc.parseAmount("1.234,50"), 1234.5);
      expect(AiInsightsBloc.parseAmount("10,25"), 10.25);
    });

    test('aceita o formato inglês', () {
      expect(AiInsightsBloc.parseAmount("1,234.50"), 1234.5);
      expect(AiInsightsBloc.parseAmount("10.25"), 10.25);
    });

    test('ignora símbolos e espaços', () {
      expect(AiInsightsBloc.parseAmount(" R\$ 1.000,00 "), 1000);
    });

    test('recusa vazio, texto e valores não positivos', () {
      expect(AiInsightsBloc.parseAmount(""), isNull);
      expect(AiInsightsBloc.parseAmount("abc"), isNull);
      expect(AiInsightsBloc.parseAmount("0"), isNull);
      expect(AiInsightsBloc.parseAmount("-10"), isNull);
    });

    test('o campo da tela alimenta o valor da simulação', () {
      bloc.amountController.text = "2.500,00";

      expect(bloc.simulationAmount, 2500);
    });
  });

  group('AiInsightsBloc.dispose', () {
    // Blocs próprios: o tearDown descarta o do setUp, e descartar duas vezes o
    // mesmo controller de texto quebraria.
    test('fecha a stream de estado', () async {
      final descartavel = AiInsightsBloc(currencyRepository: repository);
      final stream = descartavel.stateStream;

      descartavel.dispose();

      expect(await stream.isEmpty, isTrue);
    });

    test('descarta o controller do campo de valor', () {
      final descartavel = AiInsightsBloc(currencyRepository: repository);
      final controller = descartavel.amountController;

      descartavel.dispose();

      expect(() => controller.text = "1", throwsA(isA<FlutterError>()));
    });
  });
}
