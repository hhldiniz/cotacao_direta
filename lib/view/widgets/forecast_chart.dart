import 'package:cotacao_direta/model/asset_series.dart';
import 'package:cotacao_direta/model/financial_analysis.dart';
import 'package:cotacao_direta/util/quote_format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Recent history and the local model's projection on the same chart: the
/// solid line is what happened, the dashed one is what the model expects, and
/// the band around it is the confidence interval.
///
/// The projection starts at the last observed point (rather than the next day)
/// so the two lines meet, instead of the dashed one starting out of thin air.
class ForecastChart extends StatelessWidget {
  final List<AssetPoint> history;
  final List<ForecastPoint> forecast;

  ForecastChart({Key? key, required this.history, required this.forecast})
      : super(key: key);

  final DateFormat _axisDateFormatter = DateFormat("dd/MM");

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final historyColor = colorScheme.primary;
    final forecastColor = colorScheme.tertiary;

    final dates = [
      ...history.map((point) => point.date),
      ...forecast.map((point) => point.date),
    ];
    final joinIndex = (history.length - 1).toDouble();

    final historySpots = List.generate(history.length,
        (index) => FlSpot(index.toDouble(), history[index].price));

    final lastPrice = history.last.price;
    final forecastSpots = [
      FlSpot(joinIndex, lastPrice),
      ...forecast.map(
          (point) => FlSpot(joinIndex + point.step, point.price)),
    ];
    final lowerSpots = [
      FlSpot(joinIndex, lastPrice),
      ...forecast.map(
          (point) => FlSpot(joinIndex + point.step, point.lowerBound)),
    ];
    final upperSpots = [
      FlSpot(joinIndex, lastPrice),
      ...forecast.map(
          (point) => FlSpot(joinIndex + point.step, point.upperBound)),
    ];

    // Same decimal-places logic as the history chart: the order of magnitude
    // of the series decides the precision, otherwise a crypto quote turns into
    // "0.00" on the axis.
    final peakValue = [...historySpots, ...upperSpots].fold<double>(
        0, (peak, spot) => spot.y.abs() > peak ? spot.y.abs() : peak);
    final axisDigits = quoteDecimalDigits(peakValue);
    final leftAxisWidth =
        (peakValue.toStringAsFixed(axisDigits).length * 6.5 + 12)
            .clamp(48.0, 110.0);

    LineChartBarData bandLine(List<FlSpot> spots) => LineChartBarData(
          spots: spots,
          isCurved: false,
          color: forecastColor.withValues(alpha: 0.35),
          barWidth: 1,
          dotData: const FlDotData(show: false),
        );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (dates.length - 1).toDouble(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final index = spot.x.round();
              final date = dates[index.clamp(0, dates.length - 1)];
              return LineTooltipItem(
                "${_axisDateFormatter.format(date)}\n"
                "${spot.y.toStringAsFixed(quoteDecimalDigits(peakValue, minimumDigits: 4, significantDigits: 4))}",
                TextStyle(color: colorScheme.onInverseSurface),
              );
            }).toList(),
          ),
        ),
        // Marks where the observed data ends and the projection begins.
        extraLinesData: ExtraLinesData(verticalLines: [
          VerticalLine(
            x: joinIndex,
            color: colorScheme.outline.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ]),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: dates.length > 1 ? (dates.length - 1) / 4 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= dates.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _axisDateFormatter.format(dates[index]),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: leftAxisWidth,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(axisDigits),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: historySpots,
            isCurved: true,
            color: historyColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData:
                BarAreaData(show: true, color: historyColor.withValues(alpha: 0.12)),
          ),
          bandLine(lowerSpots),
          bandLine(upperSpots),
          LineChartBarData(
            spots: forecastSpots,
            isCurved: false,
            color: forecastColor,
            barWidth: 2,
            dashArray: const [6, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
        // Fills the confidence interval between the two band lines.
        betweenBarsData: [
          BetweenBarsData(
            fromIndex: 1,
            toIndex: 2,
            color: forecastColor.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}
