import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';

/// Bridge between the insight engine, which is pure Dart, and the screen.
///
/// The engine decides *what* to say ([InsightCode]) and in what tone
/// ([InsightSentiment]), and already formats the numbers in the requested
/// language; here the code becomes the translated sentence, the icon and the
/// colour.

/// Translated sentence for the insight, with the numbers slotted into the
/// placeholders.
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

/// Colour of the insight icon. Rises and falls do not come out of the theme's
/// colour scheme: green and red come from fixed shades, adjusted to the theme
/// brightness so they stay readable in dark mode.
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
