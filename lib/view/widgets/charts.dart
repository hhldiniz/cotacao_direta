import 'package:flutter/widgets.dart';

class SimpleLineChart extends StatelessWidget {
  // final List<Series>? seriesList;
  final bool? animate;

  SimpleLineChart({/*this.seriesList,*/ this.animate});

  @override
  Widget build(BuildContext context) {
    // TODO Replace this with a chart from another library
    /*return TimeSeriesChart(
      seriesList as List<Series<dynamic, DateTime>>,
      animate: animate,
      primaryMeasureAxis: NumericAxisSpec(
          tickFormatterSpec: BasicNumericTickFormatterSpec.fromNumberFormat(
              NumberFormat.compactSimpleCurrency())),
      domainAxis: DateTimeAxisSpec(
          tickFormatterSpec: AutoDateTimeTickFormatterSpec(
              day: TimeFormatterSpec(
                  format: 'dd', transitionFormat: 'yyyy-MM-dd'),
              month: TimeFormatterSpec(
                  format: 'MM', transitionFormat: 'yyyy-MM-dd'),
              year: TimeFormatterSpec(
                  format: 'yyyy', transitionFormat: 'yyyy-MM-dd'))),
    );*/
    return Container(
      child: Text("TODO"),
    );
  }
}
