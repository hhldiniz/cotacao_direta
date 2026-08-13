import 'package:cotacao_direta/view/widgets/currency_rate_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A bolha de cotação da tela inicial. O toque nela é o atalho para a
/// conversão da moeda que ela mostra, então precisa chegar ao chamador.
Widget _cardApp(Widget card) => MaterialApp(home: Scaffold(body: card));

void main() {
  group('CurrencyRateCard', () {
    testWidgets('avisa o toque a quem passou o cartão',
        (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(_cardApp(CurrencyRateCard(
        color: Colors.green,
        icon: Icons.attach_money,
        code: "USD",
        label: "Dólar Americano",
        valueWidget: const Text("5,00"),
        onTap: () => taps++,
      )));

      await tester.tap(find.text("USD"));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('sem onTap o cartão não reage ao toque',
        (WidgetTester tester) async {
      await tester.pumpWidget(_cardApp(CurrencyRateCard(
        color: Colors.green,
        icon: Icons.attach_money,
        code: "USD",
        label: "Dólar Americano",
        valueWidget: const Text("5,00"),
      )));

      expect(find.byType(GestureDetector), findsNothing,
          reason: "um detector sem ação só atrapalharia a rolagem da grade");
    });
  });
}
