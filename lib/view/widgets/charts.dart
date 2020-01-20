import 'package:charts_flutter/flutter.dart';
import 'package:flutter/widgets.dart';

class SimpleLineChart extends StatelessWidget{

  final List<Series> seriesList;
  final bool animate;

  SimpleLineChart({this.seriesList, this.animate});

  @override
  Widget build(BuildContext context) {
    return LineChart(seriesList, animate: animate);
  }
}