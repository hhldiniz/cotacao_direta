import 'package:flutter/foundation.dart';

/// Uma obra de terceiro embarcada no app (ou consumida por ele) cuja licença
/// obriga a manter o crédito ao autor.
///
/// Praticamente toda licença permissiva usada aqui — MIT, BSD de 2 e de 3
/// cláusulas, Apache 2.0, MPL 2.0 — exige que o aviso de direito autoral
/// acompanhe as redistribuições, e um aplicativo publicado é uma
/// redistribuição em forma binária. Por isso a tela "Sobre" traz esta lista.
@immutable
class ThirdPartyCredit {
  /// Nome pelo qual a obra é conhecida ("fl_chart", "Roboto", "REST
  /// Countries").
  final String name;

  /// O detentor do direito autoral, copiado do arquivo LICENSE da própria
  /// obra — é este texto que a licença manda preservar.
  final String copyright;

  /// Identificador SPDX da licença ("MIT", "BSD-3-Clause", ...).
  final String license;

  /// Endereço do projeto, para quem quiser conferir a licença na origem.
  final String url;

  const ThirdPartyCredit({
    required this.name,
    required this.copyright,
    required this.license,
    required this.url,
  });
}

/// Os créditos que a tela "Sobre" exibe, separados nos três grupos em que o
/// usuário os procura: de onde vêm os dados, o que desenha a interface e o que
/// sustenta o app por baixo.
///
/// A lista é curada: traz as dependências diretas do `pubspec.yaml`, as obras
/// embarcadas que não são pacotes Dart (a fonte, os desenhos das bandeiras) e
/// as transitivas grandes o bastante para merecerem o nome. A lista exaustiva,
/// com o texto integral de cada licença, sai do `showLicensePage` do Flutter,
/// que a própria tela oferece logo abaixo destes cartões.
class ThirdPartyCredits {
  ThirdPartyCredits._();

  /// Serviços de rede consultados pelo app. Não são código embarcado, mas são
  /// a origem dos números que o app mostra, e creditá-los é o mínimo — a REST
  /// Countries ainda é um projeto aberto, sob MPL 2.0.
  static const List<ThirdPartyCredit> dataSources = [
    ThirdPartyCredit(
      name: "AwesomeAPI",
      copyright: "© AwesomeAPI",
      license: "awesomeapi.com.br",
      url: "https://docs.awesomeapi.com.br/api-de-moedas",
    ),
    ThirdPartyCredit(
      name: "REST Countries",
      copyright: "Copyright (c) Alejandro Matos",
      license: "MPL-2.0",
      url: "https://restcountries.com",
    ),
  ];

  /// Fontes e conjuntos de ícones embarcados no pacote do app.
  ///
  /// Os desenhos das bandeiras merecem atenção: eles vêm do flag-icons, que é
  /// MIT e pede o aviso de direito autoral, mas o pacote `flag` que os
  /// redistribui traz só a própria licença. O crédito ao flag-icons, então,
  /// precisa sair daqui.
  static const List<ThirdPartyCredit> fontsAndIcons = [
    ThirdPartyCredit(
      name: "Roboto",
      copyright: "Copyright (c) Google LLC",
      license: "Apache-2.0",
      url: "https://fonts.google.com/specimen/Roboto",
    ),
    ThirdPartyCredit(
      name: "Material Icons",
      copyright: "Copyright (c) Google LLC",
      license: "Apache-2.0",
      url: "https://fonts.google.com/icons",
    ),
    ThirdPartyCredit(
      name: "Cupertino Icons",
      copyright: "Copyright (c) 2016 Vladimir Kharlampidi",
      license: "MIT",
      url: "https://pub.dev/packages/cupertino_icons",
    ),
    ThirdPartyCredit(
      name: "flag-icons",
      copyright: "Copyright (c) 2013 Panayiotis Lipiridis",
      license: "MIT",
      url: "https://github.com/lipis/flag-icons",
    ),
  ];

  /// Plataforma, pacotes Dart e bibliotecas nativas embarcadas.
  static const List<ThirdPartyCredit> software = [
    ThirdPartyCredit(
      name: "Flutter",
      copyright: "Copyright 2014 The Flutter Authors",
      license: "BSD-3-Clause",
      url: "https://flutter.dev",
    ),
    ThirdPartyCredit(
      name: "fl_chart",
      copyright: "Copyright (c) 2022 Flutter 4 Fun",
      license: "MIT",
      url: "https://github.com/imaNNeo/fl_chart",
    ),
    ThirdPartyCredit(
      name: "flag",
      copyright: "Copyright (c) 2019 Luna Gao",
      license: "BSD-2-Clause",
      url: "https://github.com/LunaGao/flag_flutter",
    ),
    ThirdPartyCredit(
      name: "flutter_local_notifications",
      copyright: "Copyright 2018 Michael Bui",
      license: "BSD-3-Clause",
      url: "https://github.com/MaikuB/flutter_local_notifications",
    ),
    ThirdPartyCredit(
      name: "flutter_svg",
      copyright: "Copyright (c) 2018 Dan Field",
      license: "BSD-2-Clause",
      url: "https://github.com/dnfield/flutter_svg",
    ),
    ThirdPartyCredit(
      name: "http",
      copyright: "Copyright 2014, the Dart project authors",
      license: "BSD-3-Clause",
      url: "https://pub.dev/packages/http",
    ),
    ThirdPartyCredit(
      name: "intl",
      copyright: "Copyright 2013, the Dart project authors",
      license: "BSD-3-Clause",
      url: "https://pub.dev/packages/intl",
    ),
    ThirdPartyCredit(
      name: "package_info_plus",
      copyright: "Copyright 2017 The Chromium Authors",
      license: "BSD-3-Clause",
      url: "https://github.com/fluttercommunity/plus_plugins",
    ),
    ThirdPartyCredit(
      name: "path",
      copyright: "Copyright 2014, the Dart project authors",
      license: "BSD-3-Clause",
      url: "https://pub.dev/packages/path",
    ),
    ThirdPartyCredit(
      name: "petitparser / xml",
      copyright: "Copyright (c) 2006-2025 Lukas Renggli",
      license: "MIT",
      url: "https://github.com/renggli/dart-xml",
    ),
    ThirdPartyCredit(
      name: "SQLite",
      copyright: "SQLite Consortium",
      license: "Public Domain",
      url: "https://www.sqlite.org/copyright.html",
    ),
    ThirdPartyCredit(
      name: "sqflite",
      copyright: "Copyright (c) 2019 Alexandre Roux Tekartik",
      license: "BSD-2-Clause",
      url: "https://github.com/tekartik/sqflite",
    ),
    ThirdPartyCredit(
      name: "sqlite3.dart",
      copyright: "Copyright (c) 2020 Simon Binder",
      license: "MIT",
      url: "https://github.com/simolus3/sqlite3.dart",
    ),
    ThirdPartyCredit(
      name: "sprintf",
      copyright: "Copyright (c) 2012 Richard Eames",
      license: "BSD-2-Clause",
      url: "https://pub.dev/packages/sprintf",
    ),
    ThirdPartyCredit(
      name: "timezone / IANA Time Zone Database",
      copyright: "Copyright (c) 2014 timezone project authors",
      license: "BSD-2-Clause",
      url: "https://pub.dev/packages/timezone",
    ),
    ThirdPartyCredit(
      name: "url_launcher",
      copyright: "Copyright 2013 The Flutter Authors",
      license: "BSD-3-Clause",
      url: "https://pub.dev/packages/url_launcher",
    ),
    ThirdPartyCredit(
      name: "workmanager",
      copyright: "Copyright (c) 2019 vrtdev, 2023 Flutter Community",
      license: "MIT",
      url: "https://github.com/fluttercommunity/flutter_workmanager",
    ),
  ];
}
