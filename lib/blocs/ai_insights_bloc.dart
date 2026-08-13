import 'dart:async';

import 'package:cotacao_direta/ai/financial_ai_service.dart';
import 'package:cotacao_direta/blocs/base_bloc.dart';
import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:cotacao_direta/repository/currency_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Why the analysis could not be done, so the screen can pick the message.
enum AiInsightsError {
  /// No quote came back: no network and no saved history, or a pair the API
  /// does not quote.
  noData,

  /// Quotes did come back, but too few to compute indicators.
  insufficientData,

  /// Any unexpected failure along the way.
  failure,
}

/// State of the insights screen. A single object instead of three streams,
/// because the three pieces always change together and the screen needs them
/// as a set.
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

/// Connects the insights screen to the quote history and to the local model.
///
/// The analysis runs on the device itself: the bloc fetches the history
/// through the repository the app already uses, builds the series and calls
/// the [FinancialAiService]. No quote and no result leaves the phone.
class AiInsightsBloc extends BaseBloc {
  final CurrencyRepository _currencyRepository;
  final FinancialAiService _aiService;

  final StreamController<AiInsightsState> _stateController =
      StreamController<AiInsightsState>.broadcast();

  final TextEditingController _amountController = TextEditingController();

  final DateFormat _apiDateFormatter = DateFormat("yyyy-MM-dd");

  /// Horizons offered on the screen, in days.
  static const List<int> horizonOptions = [7, 15, 30];

  /// Calendar days of history requested from the API. It covers about four
  /// months of trading — enough to train the network without hitting the cap
  /// of 360 records per request.
  static const int historyWindowInDays = 180;

  AiInsightsState _state = const AiInsightsState.idle();

  String _selectedAssetCode;
  AssetKind _selectedAssetKind;
  int _horizonInDays;

  Future<String>? _counterCurrencyFuture;

  /// Request in flight, so a late response does not overwrite the result of a
  /// newer request (the user switches asset and taps again before the first
  /// query comes back).
  int _requestId = 0;

  /// Locale of the last analysis requested by the screen, to reuse when the
  /// bloc itself re-runs the analysis (on a horizon change).
  String _localeName = "pt";

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

  /// Last emitted state. The stream is a broadcast one and does not replay the
  /// latest event, so the screen uses this as `initialData` when rebuilding.
  AiInsightsState get currentState => _state;

  String get selectedAssetCode => _selectedAssetCode;

  AssetKind get selectedAssetKind => _selectedAssetKind;

  int get horizonInDays => _horizonInDays;

  TextEditingController get amountController => _amountController;

  /// Currency the quotes are expressed in, resolved once and cached (the
  /// screen asks for it on every rebuild).
  Future<String> get counterCurrencyCode =>
      _counterCurrencyFuture ??= _currencyRepository.resolveCounterCurrency();

  void selectAsset(String assetCode, AssetKind kind) {
    if (_selectedAssetCode == assetCode && _selectedAssetKind == kind) return;
    _selectedAssetCode = assetCode;
    _selectedAssetKind = kind;
    // The result on screen belongs to another asset: keeping it next to the
    // new name would make the analysis look up to date.
    _emit(const AiInsightsState.idle());
  }

  void selectHorizon(int days) {
    if (_horizonInDays == days) return;
    _horizonInDays = days;
    // The horizon only changes the projection; redoing the analysis is cheap
    // and needs no network, so the screen answers right away when a result is
    // already there.
    if (_state.hasAnalysis) analyze(localeName: _localeName);
  }

  /// Amount typed for the simulation, or null when the field is empty or
  /// invalid. It takes both "1.234,50" and "1,234.50": the decimal separator
  /// is whichever comes last.
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

  /// Fetches the history of the selected asset and runs the local model over
  /// it.
  Future<void> analyze({String localeName = "pt"}) async {
    final requestId = ++_requestId;
    _localeName = localeName;
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

      // Hands control back to the event loop before training: training is
      // short (milliseconds), but this way the loading indicator does get to
      // show and the screen does not freeze on a slow device.
      final analysis = await Future(() => _aiService.analyze(
            series,
            horizonInDays: _horizonInDays,
            localeName: localeName,
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
