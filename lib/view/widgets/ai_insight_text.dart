import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

/// Ponte entre o motor de insights, que é Dart puro, e a tela.
///
/// O motor decide *o que* dizer ([InsightCode]) e com que tom
/// ([InsightSentiment]), e já formata os números no idioma pedido; aqui o código
/// vira a frase traduzida, o ícone e a cor.

/// Frase traduzida do insight, com os números encaixados nos marcadores.
String insightText(MyAppLocalizations localizations, FinancialInsight insight) {
  final template = switch (insight.code) {
    InsightCode.trendUp => localizations.aiInsightTrendUp,
    InsightCode.trendDown => localizations.aiInsightTrendDown,
    InsightCode.trendSideways => localizations.aiInsightTrendSideways,
    InsightCode.momentumOverbought => localizations.aiInsightMomentumOverbought,
    InsightCode.momentumOversold => localizations.aiInsightMomentumOversold,
    InsightCode.momentumNeutral => localizations.aiInsightMomentumNeutral,
    InsightCode.volatilityHigh => localizations.aiInsightVolatilityHigh,
    InsightCode.volatilityLow => localizations.aiInsightVolatilityLow,
    InsightCode.projectionUp => localizations.aiInsightProjectionUp,
    InsightCode.projectionDown => localizations.aiInsightProjectionDown,
    InsightCode.projectionStable => localizations.aiInsightProjectionStable,
    InsightCode.drawdown => localizations.aiInsightDrawdown,
    InsightCode.confidenceGood => localizations.aiInsightConfidenceGood,
    InsightCode.confidenceLow => localizations.aiInsightConfidenceLow,
    InsightCode.dataLimited => localizations.aiInsightDataLimited,
  }!;
  return insight.arguments.isEmpty
      ? template
      : sprintf(template, insight.arguments);
}

IconData insightIcon(InsightSentiment sentiment) => switch (sentiment) {
      InsightSentiment.positive => Icons.trending_up,
      InsightSentiment.negative => Icons.trending_down,
      InsightSentiment.caution => Icons.warning_amber_rounded,
      InsightSentiment.neutral => Icons.remove,
    };

/// Cor do ícone do insight. Alta e baixa não saem do esquema de cores do tema:
/// verde e vermelho vêm de tons fixos, ajustados ao brilho do tema para
/// continuarem legíveis no modo escuro.
Color insightColor(BuildContext context, InsightSentiment sentiment) {
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return switch (sentiment) {
    InsightSentiment.positive =>
      isDark ? Colors.green.shade300 : Colors.green.shade700,
    InsightSentiment.negative => colorScheme.error,
    InsightSentiment.caution =>
      isDark ? Colors.amber.shade300 : Colors.amber.shade800,
    InsightSentiment.neutral => colorScheme.outline,
  };
}
