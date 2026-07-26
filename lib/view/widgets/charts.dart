import 'package:cotacao_direta/model/currency.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Gráfico de linha simples com o histórico de valores de uma moeda ao longo
/// do tempo, uma [Currency] por dia.
class SimpleLineChart extends StatelessWidget {
  final List<Currency> currencyList;

  SimpleLineChart({required this.currencyList});

  final DateFormat _axisDateFormatter = DateFormat("dd/MM");

  @override
  Widget build(BuildContext context) {
    final dates = currencyList
        .map((currency) => DateTime.parse(currency.historicalDate!))
        .toList();
    final spots = List.generate(
      currencyList.length,
      (index) => FlSpot(index.toDouble(), currencyList[index].value ?? 0),
    );
    final color = Theme.of(context).colorScheme.primary;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final date = dates[spot.x.toInt()];
              return LineTooltipItem(
                "${_axisDateFormatter.format(date)}\n${spot.y.toStringAsFixed(4)}",
                TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
              );
            }).toList(),
          ),
        ),
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
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.15)),
          ),
        ],
      ),
    );
  }
}
