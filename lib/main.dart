import 'package:cotacao_direta/providers/home_bloc_provider.dart';
import 'package:flutter/material.dart';

import 'view/pages/home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  final appName = "Cotação Direta";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: "Roboto"
      ),
      home: HomeBlocProvider(child: Home(appName),),
    );
  }
}