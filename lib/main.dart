import 'package:cotacao_direta/providers/currency_alerts_bloc_provider.dart';
import 'package:cotacao_direta/providers/home_bloc_provider.dart';
import 'package:cotacao_direta/util/app_locale_controller.dart';
import 'package:cotacao_direta/util/currency_colors.dart';
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
  // Antes do primeiro quadro: a tela já abre no idioma escolhido, em vez de
  // aparecer no do aparelho e trocar em seguida.
  await AppLocaleController.instance.load();
  return runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  final appName = "Cotação Direta";

  /// O idioma escolhido nas configurações. Injetável para os testes montarem
  /// o app sem depender do controlador global.
  final AppLocaleController localeController;

  MyApp({Key? key, AppLocaleController? localeController})
      : localeController = localeController ?? AppLocaleController.instance,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    // Escutar aqui, na raiz, é o que faz a troca de idioma valer para o app
    // inteiro assim que o usuário escolhe.
    return ValueListenableBuilder<Locale?>(
      valueListenable: localeController,
      builder: (BuildContext context, Locale? locale, _) =>
          _buildApp(context, locale),
    );
  }

  Widget _buildApp(BuildContext context, Locale? locale) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MyAppLocalizationsDelegate()
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: CurrencyColors.seed),
        fontFamily: "Roboto",
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CurrencyColors.seed,
          brightness: Brightness.dark,
        ),
        fontFamily: "Roboto",
      ),
      themeMode: ThemeMode.system,
      // Nulo deixa o Flutter resolver pelo idioma do aparelho, como antes de a
      // opção existir.
      locale: locale,
      supportedLocales: AppLocales.supported,
      title: appName,
      home: HomeBlocProvider(
        child: CurrencyAlertsBlocProvider(
          child: Home(appName),
        ),
      ),
    );
  }
}
