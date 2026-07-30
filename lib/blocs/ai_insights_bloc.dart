import 'dart:async';

import 'package:cotacao_direta/ai/financial_ai_service.dart';
import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Por que a análise não pôde ser feita, para a tela escolher a mensagem.
enum AiInsightsError {
  /// Nenhuma cotação voltou: sem rede e sem histórico salvo, ou par não cotado
  /// pela API.
  noData,

  /// Vieram cotações, mas poucas demais para calcular indicadores.
  insufficientData,

  /// Qualquer falha inesperada no caminho.
  failure,
}

/// Estado da tela de insights. Um objeto só, em vez de três streams, porque as
/// três informações mudam sempre juntas e a tela precisa delas em conjunto.
class AiInsightsState {
  final bool loading;
  final FinancialAnalysis? analysis;
  final AiInsightsError? error;

  const AiInsightsState._({this.loading = false, this.analysis, this.error});

  const AiInsightsState.idle() : this._();

  const AiInsightsState.loading() : this._(loading: true);

  const AiInsightsState.ready(FinancialAnalysis analysis)
      : this._(analysis: analysis);

  const AiInsightsState.failed(AiInsightsError error) : this._(error: error);

  bool get hasAnalysis => analysis != null;
}

/// Liga a tela de insights ao histórico de cotações e ao modelo local.
///
/// A análise roda no próprio aparelho: o bloc busca o histórico pelo
/// repositório que o app já usa, monta a série e chama o [FinancialAiService].
/// Nada de cotação ou de resultado sai do celular.
class AiInsightsBloc extends BaseBloc {
  final CurrencyRepository _currencyRepository;
  final FinancialAiService _aiService;

  final StreamController<AiInsightsState> _stateController =
      StreamController<AiInsightsState>.broadcast();

  final TextEditingController _amountController = TextEditingController();

  final DateFormat _apiDateFormatter = DateFormat("yyyy-MM-dd");

  /// Horizontes oferecidos na tela, em dias.
  static const List<int> horizonOptions = [7, 15, 30];

  /// Dias corridos de histórico pedidos à API. Cobre uns quatro meses de
  /// pregão — o bastante para treinar a rede sem esbarrar no teto de 360
  /// registros por consulta.
  static const int historyWindowInDays = 180;

  AiInsightsState _state = const AiInsightsState.idle();

  String _selectedAssetCode;
  AssetKind _selectedAssetKind;
  int _horizonInDays;

  Future<String>? _counterCurrencyFuture;

  /// Requisição em andamento, para uma resposta atrasada não sobrescrever o
  /// resultado de um pedido mais novo (o usuário troca de ativo e toca de novo
  /// antes de a primeira consulta voltar).
  int _requestId = 0;

  /// Idioma da última análise pedida pela tela, para reaproveitar quando o
  /// próprio bloc refaz a análise (troca de horizonte).
  String _languageCode = "pt";

  AiInsightsBloc({
    CurrencyRepository? currencyRepository,
    FinancialAiService? aiService,
    String initialAssetCode = "USD",
    AssetKind initialAssetKind = AssetKind.currency,
    int initialHorizonInDays = 15,
  })  : _currencyRepository = currencyRepository ?? CurrencyRepository(),
        _aiService = aiService ?? FinancialAiService(),
        _selectedAssetCode = initialAssetCode,
        _selectedAssetKind = initialAssetKind,
        _horizonInDays = initialHorizonInDays;

  Stream<AiInsightsState> get stateStream => _stateController.stream;

  /// Último estado emitido. A stream é broadcast e não repete o último evento,
  /// então a tela usa isto como `initialData` ao reconstruir.
  AiInsightsState get currentState => _state;

  String get selectedAssetCode => _selectedAssetCode;

  AssetKind get selectedAssetKind => _selectedAssetKind;

  int get horizonInDays => _horizonInDays;

  TextEditingController get amountController => _amountController;

  /// Moeda em que as cotações estão expressas, resolvida uma vez e mantida em
  /// cache (a tela reconsulta a cada rebuild).
  Future<String> get counterCurrencyCode =>
      _counterCurrencyFuture ??= _currencyRepository.resolveCounterCurrency();

  void selectAsset(String assetCode, AssetKind kind) {
    if (_selectedAssetCode == assetCode && _selectedAssetKind == kind) return;
    _selectedAssetCode = assetCode;
    _selectedAssetKind = kind;
    // O resultado na tela é de outro ativo: mantê-lo visível ao lado do nome
    // novo faria a análise parecer atualizada.
    _emit(const AiInsightsState.idle());
  }

  void selectHorizon(int days) {
    if (_horizonInDays == days) return;
    _horizonInDays = days;
    // O horizonte muda só a projeção; refazer a análise é barato e não precisa
    // de rede, então a tela responde na hora se já houver um resultado.
    if (_state.hasAnalysis) analyze(languageCode: _languageCode);
  }

  /// Valor digitado para simulação, ou nulo quando o campo está vazio ou
  /// inválido. Aceita tanto "1.234,50" quanto "1,234.50": o separador decimal é
  /// o último que aparecer.
  double? get simulationAmount => parseAmount(_amountController.text);

  static double? parseAmount(String text) {
    var cleaned = text.trim().replaceAll(RegExp(r"[^0-9.,-]"), "");
    if (cleaned.isEmpty) return null;
    final lastComma = cleaned.lastIndexOf(",");
    final lastDot = cleaned.lastIndexOf(".");
    if (lastComma > lastDot) {
      cleaned = cleaned.replaceAll(".", "").replaceAll(",", ".");
    } else {
      cleaned = cleaned.replaceAll(",", "");
    }
    final value = double.tryParse(cleaned);
    if (value == null || !value.isFinite || value <= 0) return null;
    return value;
  }

  /// Busca o histórico do ativo selecionado e roda o modelo local sobre ele.
  Future<void> analyze({String languageCode = "pt"}) async {
    final requestId = ++_requestId;
    _languageCode = languageCode;
    _emit(const AiInsightsState.loading());
    try {
      final today = DateTime.now();
      final history = await _currencyRepository.getCurrencyHistoricalData(
        [_selectedAssetCode],
        _apiDateFormatter
            .format(today.subtract(const Duration(days: historyWindowInDays))),
        _apiDateFormatter.format(today),
      );
      if (requestId != _requestId) return;

      final series = AssetSeries.fromQuoteHistory(
        code: _selectedAssetCode,
        kind: _selectedAssetKind,
        quoteCurrency: await counterCurrencyCode,
        history: history,
      );
      if (requestId != _requestId) return;

      if (series.isEmpty) {
        _emit(const AiInsightsState.failed(AiInsightsError.noData));
        return;
      }
      if (series.length < FinancialAiService.minimumPoints) {
        _emit(const AiInsightsState.failed(AiInsightsError.insufficientData));
        return;
      }

      // Devolve o controle ao laço de eventos antes de treinar: o treino é
      // curto (milissegundos), mas assim o indicador de carregamento chega a
      // aparecer e a tela não trava em aparelho lento.
      final analysis = await Future(() => _aiService.analyze(
            series,
            horizonInDays: _horizonInDays,
            languageCode: languageCode,
          ));
      if (requestId != _requestId) return;
      _emit(AiInsightsState.ready(analysis));
    } catch (exception) {
      if (requestId != _requestId) return;
      _emit(const AiInsightsState.failed(AiInsightsError.failure));
    }
  }

  void _emit(AiInsightsState state) {
    _state = state;
    if (!_stateController.isClosed) _stateController.sink.add(state);
  }

  @override
  void dispose() {
    _stateController.close();
    _amountController.dispose();
  }
}
