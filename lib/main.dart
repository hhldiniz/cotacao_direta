import 'package:cotacao_direta/providers/currency_alerts_bloc_provider.dart';
import 'package:cotacao_direta/providers/home_bloc_provider.dart';
import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_stetho/flutter_stetho.dart';

import 'view/pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Stetho.initialize();
  await NotificationService().initialize();
  return runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  final appName = "Cotação Direta";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MyAppLocalizationsDelegate()
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        fontFamily: "Roboto",
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        fontFamily: "Roboto",
      ),
      themeMode: ThemeMode.system,
      supportedLocales: [const Locale("en"), const Locale("pt")],
      title: appName,
      home: HomeBlocProvider(
        child: CurrencyAlertsBlocProvider(
          child: Home(appName),
        ),
      ),
    );
  }
}
