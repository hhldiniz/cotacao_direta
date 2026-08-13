import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/pwa_install_service.dart';
import 'package:cotacao_direta/view/widgets/pwa_install_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _cardApp() => MaterialApp(
    locale: const Locale("pt"),
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      MyAppLocalizationsDelegate()
    ],
    supportedLocales: const [Locale("pt"), Locale("en")],
    home: Scaffold(
        body: Column(children: const [PwaInstallCard(index: 0)])));

void main() {
  group('PwaInstallService fora da web', () {
    test('não oferece instalação', () {
      expect(PwaInstallService.status, PwaInstallStatus.unsupported);
    });

    test('o pedido de instalação não é aceito', () async {
      expect(await PwaInstallService.promptInstall(), isFalse);
    });

    test('o fluxo de mudanças termina sem emitir nada', () {
      expect(PwaInstallService.statusChanges, emitsDone);
    });
  });

  group('PwaInstallCard', () {
    // Os testes rodam na VM, onde a instalação como PWA não existe: o cartão
    // não pode aparecer no meio das opções do app Android/Linux.
    testWidgets('não ocupa espaço quando não há instalação a oferecer',
        (WidgetTester tester) async {
      await tester.pumpWidget(_cardApp());
      await tester.pumpAndSettle();

      expect(find.text("Instalar aplicativo"), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(tester.getSize(find.byType(PwaInstallCard)), Size.zero);
    });
  });
}
