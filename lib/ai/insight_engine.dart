import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:cotacao_direta/util/quote_format.dart';
import 'package:intl/intl.dart';

/// Traduz os números da análise em observações curtas.
///
/// A camada de linguagem do recurso mora aqui: o modelo produz estatísticas e
/// uma projeção, e esta classe decide o que merece ser dito e com que tom. O
/// texto final não sai daqui — sai do arquivo de traduções, que a tela preenche
/// com [FinancialInsight.arguments]. Assim o motor continua sendo Dart puro,
/// sem depender de Flutter, e os dois idiomas do app são atendidos pelo mesmo
/// código.
class InsightEngine {
  /// Idioma em que os números são formatados ("pt" ou "en"): muda a vírgula
  /// decimal e o separador de milhar.
  final String languageCode;

  const InsightEngine({this.languageCode = "pt"});

  /// Acima disto a variação do período deixa de ser ruído e vira tendência.
  static const double _trendThreshold = 0.025;

  /// Faixa em que a projeção é considerada estável.
  static const double _projectionThreshold = 0.01;

  static const double _overboughtLevel = 70;
  static const double _oversoldLevel = 30;

  /// A partir daqui a queda do topo merece aviso.
  static const double _drawdownThreshold = 0.15;

  /// Vantagem mínima sobre o passeio aleatório para a rede ser digna de nota.
  static const double _meaningfulSkill = 0.05;

  List<FinancialInsight> generate({
    required AssetSeries series,
    required MarketStatistics statistics,
    required AssetForecast forecast,
  }) {
    return [
      _projectionInsight(forecast),
      ..._trendInsights(statistics),
      ..._momentumInsights(statistics),
      ..._volatilityInsights(series.kind, statistics),
      ..._riskInsights(statistics),
      _confidenceInsight(forecast.diagnostics),
    ];
  }

  FinancialInsight _projectionInsight(AssetForecast forecast) {
    final change = forecast.projectedChange;
    final days = "${forecast.horizonInDays}";
    final price = _price(forecast.projectedPrice);
    if (change > _projectionThreshold) {
      return FinancialInsight(
          code: InsightCode.projectionUp,
          sentiment: InsightSentiment.positive,
          arguments: [_percent(change.abs()), days, price]);
    }
    if (change < -_projectionThreshold) {
      return FinancialInsight(
          code: InsightCode.projectionDown,
          sentiment: InsightSentiment.negative,
          arguments: [_percent(change.abs()), days, price]);
    }
    return FinancialInsight(
        code: InsightCode.projectionStable,
        sentiment: InsightSentiment.neutral,
        arguments: [days, price]);
  }

  List<FinancialInsight> _trendInsights(MarketStatistics statistics) {
    final change = statistics.referenceChange;
    if (change == null) return const [];
    // A variação de referência é a de 30 dias quando existe; senão, a de 7.
    final days = statistics.monthlyChange != null ? "30" : "7";
    final arguments = [_percent(change.abs()), days];
    if (change > _trendThreshold) {
      return [
        FinancialInsight(
            code: InsightCode.trendUp,
            sentiment: InsightSentiment.positive,
            arguments: arguments)
      ];
    }
    if (change < -_trendThreshold) {
      return [
        FinancialInsight(
            code: InsightCode.trendDown,
            sentiment: InsightSentiment.negative,
            arguments: arguments)
      ];
    }
    return [
      FinancialInsight(
          code: InsightCode.trendSideways,
          sentiment: InsightSentiment.neutral,
          arguments: arguments)
    ];
  }

  List<FinancialInsight> _momentumInsights(MarketStatistics statistics) {
    final rsi = statistics.relativeStrengthIndex;
    if (rsi == null) return const [];
    final arguments = [_number(rsi, decimalDigits: 0)];
    if (rsi >= _overboughtLevel) {
      return [
        FinancialInsight(
            code: InsightCode.momentumOverbought,
            sentiment: InsightSentiment.caution,
            arguments: arguments)
      ];
    }
    if (rsi <= _oversoldLevel) {
      return [
        FinancialInsight(
            code: InsightCode.momentumOversold,
            sentiment: InsightSentiment.caution,
            arguments: arguments)
      ];
    }
    return [
      FinancialInsight(
          code: InsightCode.momentumNeutral,
          sentiment: InsightSentiment.neutral,
          arguments: arguments)
    ];
  }

  List<FinancialInsight> _volatilityInsights(
      AssetKind kind, MarketStatistics statistics) {
    final volatility = statistics.annualizedVolatility;
    if (volatility <= 0) return const [];
    final arguments = [_percent(volatility)];
    if (volatility >= _highVolatilityLevel(kind)) {
      return [
        FinancialInsight(
            code: InsightCode.volatilityHigh,
            sentiment: InsightSentiment.caution,
            arguments: arguments)
      ];
    }
    if (volatility <= _lowVolatilityLevel(kind)) {
      return [
        FinancialInsight(
            code: InsightCode.volatilityLow,
            sentiment: InsightSentiment.positive,
            arguments: arguments)
      ];
    }
    return const [];
  }

  /// Cripto oscila numa ordem de grandeza acima de moeda fiduciária: 40% ao ano
  /// é rotina para bitcoin e seria um susto para o euro. Por isso os limiares
  /// dependem do tipo de ativo.
  double _highVolatilityLevel(AssetKind kind) => switch (kind) {
        AssetKind.currency => 0.15,
        AssetKind.stock => 0.35,
        AssetKind.cryptocurrency => 0.60,
      };

  double _lowVolatilityLevel(AssetKind kind) => switch (kind) {
        AssetKind.currency => 0.05,
        AssetKind.stock => 0.12,
        AssetKind.cryptocurrency => 0.25,
      };

  List<FinancialInsight> _riskInsights(MarketStatistics statistics) {
    if (statistics.maxDrawdown < _drawdownThreshold) return const [];
    return [
      FinancialInsight(
          code: InsightCode.drawdown,
          sentiment: InsightSentiment.caution,
          arguments: [_percent(statistics.maxDrawdown)])
    ];
  }

  FinancialInsight _confidenceInsight(ModelDiagnostics diagnostics) {
    if (!diagnostics.trained) {
      return FinancialInsight(
          code: InsightCode.dataLimited,
          sentiment: InsightSentiment.caution,
          arguments: ["${diagnostics.trainingSamples}"]);
    }
    if (diagnostics.skill >= _meaningfulSkill) {
      return FinancialInsight(
          code: InsightCode.confidenceGood,
          sentiment: InsightSentiment.positive,
          arguments: [_percent(diagnostics.skill)]);
    }
    return const FinancialInsight(
        code: InsightCode.confidenceLow, sentiment: InsightSentiment.caution);
  }

  String _percent(double fraction) =>
      NumberFormat.decimalPercentPattern(locale: languageCode, decimalDigits: 1)
          .format(fraction);

  String _number(double value, {int decimalDigits = 2}) =>
      NumberFormat.decimalPatternDigits(
              locale: languageCode, decimalDigits: decimalDigits)
          .format(value);

  /// Cotação com casas decimais suficientes para o preço não virar "0,00":
  /// cripto cotada em real anda na casa das centenas de milhares, e a mesma
  /// tela mostra pares de moeda na casa das unidades.
  String _price(double value) => _number(value,
      decimalDigits:
          quoteDecimalDigits(value, minimumDigits: 2, significantDigits: 4));
}
