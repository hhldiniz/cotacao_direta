import 'package:cotacao_direta/view/widgets/add_currency_card.dart';
import 'package:cotacao_direta/view/widgets/reorderable_bento_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _cardApp(AddCurrencyCard card) =>
    MaterialApp(home: Scaffold(body: Center(child: card)));

void main() {
  group('AddCurrencyCard', () {
    testWidgets('mostra o sinal de mais e o rótulo',
        (WidgetTester tester) async {
      await tester.pumpWidget(_cardApp(
          AddCurrencyCard(label: "Adicionar moeda", onTap: () {})));

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text("Adicionar moeda"), findsOneWidget);
    });

    testWidgets('o toque abre a escolha das moedas',
        (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(_cardApp(
          AddCurrencyCard(label: "Adicionar moeda", onTap: () => taps++)));

      await tester.tap(find.byType(AddCurrencyCard));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    // Na posição de destaque o cartão ocupa a largura toda da grade, e o
    // conteúdo cresce junto para não ficar perdido no meio dela.
    testWidgets('o cartão de destaque desenha o ícone maior',
        (WidgetTester tester) async {
      await tester.pumpWidget(_cardApp(
          AddCurrencyCard(label: "Adicionar moeda", onTap: () {})));
      final compactSize = tester.widget<Icon>(find.byIcon(Icons.add)).size;

      await tester.pumpWidget(_cardApp(AddCurrencyCard(
          label: "Adicionar moeda", onTap: () {}, hero: true)));

      expect(tester.widget<Icon>(find.byIcon(Icons.add)).size,
          greaterThan(compactSize!));
    });

    // Na grade, os dois cartões de uma linha são esticados até a mesma altura
    // (CrossAxisAlignment.stretch dentro de um IntrinsicHeight). O cartão de
    // acrescentar precisa aguentar essa altura imposta sem estourar o layout.
    testWidgets('acompanha a altura do cartão ao lado na grade',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReorderableBentoGrid(
              itemCount: 2,
              onReorder: (_, __) {},
              itemBuilder: (BuildContext context, int index, bool hero) =>
                  Container(
                key: ValueKey("tile$index"),
                height: hero ? 120 : 90,
                color: Colors.blueGrey,
              ),
              footerBuilder: (BuildContext context, int index, bool hero) =>
                  AddCurrencyCard(
                hero: hero,
                label: "Adicionar moeda",
                onTap: () {},
              ),
            ),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AddCurrencyCard)).height,
          tester.getSize(find.byKey(const ValueKey("tile1"))).height,
          reason: "a linha estica os dois cartões até a mesma altura");
    });
  });
}
