import 'package:cotacao_direta/util/in_app_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showInAppNotification', () {
    test('sem app montado, não mostra nada', () {
      expect(showInAppNotification(title: 'Alerta', body: 'USD atingiu 5,5'),
          isFalse);
    });

    testWidgets('mostra título e texto por cima da tela aberta',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        scaffoldMessengerKey: inAppNotificationsKey,
        home: const Scaffold(body: SizedBox()),
      ));

      final shown = showInAppNotification(
          title: 'Alerta de câmbio', body: 'USD atingiu 5.5000 BRL');
      await tester.pump();

      expect(shown, isTrue);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Alerta de câmbio'), findsOneWidget);
      expect(find.text('USD atingiu 5.5000 BRL'), findsOneWidget);
    });
  });
}
