import 'package:cotacao_direta/util/third_party_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // rootBundle só existe depois que o binding sobe: o texto da licença da
  // Roboto é lido do pacote de assets do app.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('registerThirdPartyLicenses', () {
    late List<LicenseEntry> entries;

    setUpAll(() async {
      registerThirdPartyLicenses();
      entries = await LicenseRegistry.licenses.toList();
    });

    test('a Apache 2.0 da Roboto entra na tela de licenças', () async {
      final roboto = entries.firstWhere(
        (entry) => entry.packages.contains("Roboto"),
        orElse: () => throw StateError("Roboto não foi registrada"),
      );
      final text =
          roboto.paragraphs.map((paragraph) => paragraph.text).join(" ");
      expect(text, contains("Apache License"));
      expect(text, contains("Version 2.0"));
    });

    test('a MIT do flag-icons entra na tela de licenças', () {
      final flagIcons = entries.firstWhere(
        (entry) => entry.packages.contains("flag-icons"),
        orElse: () => throw StateError("flag-icons não foi registrado"),
      );
      final text =
          flagIcons.paragraphs.map((paragraph) => paragraph.text).join(" ");
      // É o aviso que a MIT obriga a manter, e que o pacote `flag` não traz.
      expect(text, contains("Copyright (c) 2013 Panayiotis Lipiridis"));
      expect(text, contains("The above copyright notice"));
    });
  });
}
