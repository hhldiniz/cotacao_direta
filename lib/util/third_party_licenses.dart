import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licenças que o Flutter não recolhe sozinho e que a tela de licenças
/// (`showLicensePage`) precisa mostrar.
///
/// O Flutter registra automaticamente o LICENSE de cada pacote do grafo de
/// dependências, então os pacotes Dart e a plataforma já aparecem lá sem
/// esforço. O que fica de fora são as obras embarcadas pelo próprio app:
///
///  * a fonte Roboto, declarada em `flutter: fonts:` do `pubspec.yaml`, cujo
///    LICENSE.txt viaja junto como asset;
///  * os desenhos das bandeiras, que o pacote `flag` redistribui a partir do
///    flag-icons sem trazer a licença de origem (o LICENSE dele cobre só o
///    código do pacote).
///
/// Ambas as licenças — Apache 2.0 e MIT — obrigam a incluir o aviso de direito
/// autoral em qualquer redistribuição, e publicar o app é redistribuir.
///
/// [LicenseRegistry.addLicense] recebe uma função preguiçosa: o texto só é
/// lido quando alguém abre a tela de licenças.
void registerThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ["Roboto"],
      await rootBundle.loadString("fonts/Roboto/LICENSE.txt"),
    );
    yield LicenseEntryWithLineBreaks(const ["flag-icons"], _flagIconsLicense);
  });
}

/// MIT do flag-icons (https://github.com/lipis/flag-icons), a origem dos SVGs
/// que o pacote `flag` desenha.
const String _flagIconsLicense = '''
The MIT License (MIT)

Copyright (c) 2013 Panayiotis Lipiridis

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''';
