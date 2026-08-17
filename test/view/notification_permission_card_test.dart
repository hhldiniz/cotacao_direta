import 'package:cotacao_direta/util/localizations.dart';
import 'package:cotacao_direta/util/notification_service.dart';
import 'package:cotacao_direta/view/widgets/notification_permission_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

Widget _cardApp(NotificationService service) => MaterialApp(
      locale: const Locale("pt"),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MyAppLocalizationsDelegate()
      ],
      supportedLocales: const [Locale("pt"), Locale("en")],
      home: Scaffold(
        body: Column(children: [NotificationPermissionCard(service: service)]),
      ),
    );

void main() {
  group('NotificationPermissionCard', () {
    testWidgets('não ocupa espaço com a permissão já concedida',
        (WidgetTester tester) async {
      await tester.pumpWidget(_cardApp(
          FakeNotificationService(status: NotificationPermissionStatus.granted)));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(NotificationPermissionCard)), Size.zero);
    });

    testWidgets('não ocupa espaço onde não há notificação a pedir',
        (WidgetTester tester) async {
      await tester.pumpWidget(_cardApp(FakeNotificationService(
          status: NotificationPermissionStatus.unsupported)));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(NotificationPermissionCard)), Size.zero);
    });

    testWidgets('pede a permissão pelo botão e some quando ela é concedida',
        (WidgetTester tester) async {
      var service = FakeNotificationService(
        status: NotificationPermissionStatus.notRequested,
        statusAfterRequest: NotificationPermissionStatus.granted,
      );
      await tester.pumpWidget(_cardApp(service));
      await tester.pumpAndSettle();

      expect(find.text("Notificações dos alertas"), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, "Permitir"));
      await tester.pumpAndSettle();

      expect(service.requestCount, 1);
      expect(find.text("Notificações ativadas"), findsOneWidget);
      expect(tester.getSize(find.byType(NotificationPermissionCard)), Size.zero);
    });

    testWidgets('explica como liberar depois de uma recusa',
        (WidgetTester tester) async {
      var service = FakeNotificationService(
        status: NotificationPermissionStatus.notRequested,
        statusAfterRequest: NotificationPermissionStatus.denied,
      );
      await tester.pumpWidget(_cardApp(service));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, "Permitir"));
      await tester.pumpAndSettle();

      expect(find.text("Notificações não ativadas"), findsOneWidget);
      // Sem botão: o navegador não pergunta de novo depois de uma recusa.
      expect(find.byType(FilledButton), findsNothing);
      expect(
          find.textContaining("As notificações estão bloqueadas"),
          findsOneWidget);
    });

    testWidgets('no iOS fora do app instalado explica a Tela de Início',
        (WidgetTester tester) async {
      await tester.pumpWidget(_cardApp(FakeNotificationService(
          status: NotificationPermissionStatus.requiresInstall)));
      await tester.pumpAndSettle();

      expect(find.textContaining("Tela de Início"), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('NotificationService fora da web', () {
    // Os testes rodam na VM Linux, onde não existe permissão a conceder.
    test('não tem permissão pendente', () async {
      expect(await NotificationService().permissionStatus(),
          NotificationPermissionStatus.granted);
    });
  });
}
