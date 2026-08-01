import 'package:cotacao_direta/model/currency.dart';
import 'package:cotacao_direta/util/quote_format.dart';
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

    // A precisão sai da ordem de grandeza da série, e não de um número fixo de
    // casas: cotação de criptomoeda fica na casa dos milionésimos (ver
    // [quoteDecimalDigits]) e apareceria como "0,00" no eixo. Como todos os
    // rótulos usam a mesma quantidade de casas, a largura reservada à esquerda
    // é calculada a partir do maior rótulo possível.
    final peakValue = spots.fold<double>(
        0, (peak, spot) => spot.y.abs() > peak ? spot.y.abs() : peak);
    final axisDigits = quoteDecimalDigits(peakValue);
    final tooltipDigits = quoteDecimalDigits(peakValue,
        minimumDigits: 4, significantDigits: 4);
    final leftAxisWidth =
        (peakValue.toStringAsFixed(axisDigits).length * 6.5 + 12)
            .clamp(48.0, 110.0);

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final date = dates[spot.x.toInt()];
              return LineTooltipItem(
                "${_axisDateFormatter.format(date)}\n${spot.y.toStringAsFixed(tooltipDigits)}",
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
