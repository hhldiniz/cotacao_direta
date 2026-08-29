import 'package:cotacao_direta/view/widgets/reorderable_bento_grid.dart';
// kLongPressTimeout: o material.dart não reexporta as constantes de gestos.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uma grade com os rótulos informados, que aplica de verdade a reordenação
/// pedida — é assim que a tela inicial usa o widget, e é o que permite conferir
/// a ordem em que os cartões ficam depois do arrasto.
class _GridHarness extends StatefulWidget {
  final List<String> items;
  final List<List<int>> reorders;
  final void Function(String label)? onTapItem;

  /// Rótulo do cartão fixo do fim da grade — na tela inicial, o de acrescentar
  /// uma moeda. Nulo monta a grade sem ele.
  final String? footerLabel;
  final VoidCallback? onTapFooter;

  /// Posições soltas sobre a faixa de descarte. Nulo monta a grade sem
  /// remoção — a faixa nem chega a aparecer.
  final List<int>? deletions;

  const _GridHarness(this.items, this.reorders,
      {this.onTapItem, this.footerLabel, this.onTapFooter, this.deletions});

  @override
  State<_GridHarness> createState() => _GridHarnessState();
}

class _GridHarnessState extends State<_GridHarness> {
  late List<String> _items = List.of(widget.items);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReorderableBentoGrid(
            itemCount: _items.length,
            moveEarlierSemanticsLabel: "Mover para trás",
            moveLaterSemanticsLabel: "Mover para frente",
            deleteZoneLabel: "Solte aqui para remover",
            deleteSemanticsLabel: "Remover",
            onDelete: widget.deletions == null
                ? null
                : (index) {
                    widget.deletions!.add(index);
                    setState(() => _items.removeAt(index));
                  },
            footerBuilder: widget.footerLabel == null
                ? null
                : (BuildContext context, int index, bool hero) =>
                    GestureDetector(
                      onTap: widget.onTapFooter,
                      child: Container(
                        height: hero ? 90 : 60,
                        color: Colors.grey,
                        alignment: Alignment.center,
                        child: Text(hero
                            ? "${widget.footerLabel!} (destaque)"
                            : widget.footerLabel!),
                      ),
                    ),
            onReorder: (oldIndex, newIndex) {
              widget.reorders.add([oldIndex, newIndex]);
              setState(() {
                _items.insert(newIndex, _items.removeAt(oldIndex));
              });
            },
            itemBuilder: (BuildContext context, int index, bool hero) {
              final label = _items[index];
              return GestureDetector(
                onTap: () => widget.onTapItem?.call(label),
                child: Container(
                  height: hero ? 90 : 60,
                  color: Colors.blueGrey,
                  alignment: Alignment.center,
                  child: Text(hero ? "$label (destaque)" : label),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Os rótulos na ordem em que a grade os desenha, de cima para baixo e da
/// esquerda para a direita.
List<String> _renderedOrder(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data!)
      .toList();
  // O cartão que segue o dedo também tem um Text: fora do arrasto não existe,
  // e as posições abaixo bastam para o que estes testes conferem.
  return texts.map((label) => label.replaceAll(" (destaque)", "")).toList();
}

/// Faz o arrasto por toque longo de um cartão até a posição de outro.
Future<void> _dragTile(WidgetTester tester,
    {required Offset from, required Offset to}) async {
  final gesture = await tester.startGesture(from);
  // Sem esperar o toque longo, o gesto não vira arrasto — é justamente o que
  // impede a rolagem da tela de mover cartões sem querer.
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
  await gesture.moveTo(to);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('ReorderableBentoGrid', () {
    testWidgets('o toque longo arrasta um cartão para outra posição',
        (WidgetTester tester) async {
      final reorders = <List<int>>[];
      await tester.pumpWidget(_GridHarness(const ["A", "B", "C"], reorders));

      final from = tester.getCenter(find.text("C"));
      final to = tester.getCenter(find.text("A (destaque)"));
      await _dragTile(tester, from: from, to: to);

      expect(reorders, [
        [2, 0]
      ], reason: "o cartão arrastado deve assumir a posição em que foi solto");
      expect(_renderedOrder(tester), ["C", "A", "B"]);
    });

    testWidgets('arrastar para a primeira posição promove o cartão a destaque',
        (WidgetTester tester) async {
      await tester.pumpWidget(_GridHarness(const ["A", "B", "C"], []));

      final from = tester.getCenter(find.text("B"));
      final to = tester.getCenter(find.text("A (destaque)"));
      await _dragTile(tester, from: from, to: to);

      expect(find.text("B (destaque)"), findsOneWidget);
      expect(find.text("A"), findsOneWidget);
    });

    testWidgets('soltar o cartão onde ele já estava não reordena nada',
        (WidgetTester tester) async {
      final reorders = <List<int>>[];
      await tester.pumpWidget(_GridHarness(const ["A", "B", "C"], reorders));

      final center = tester.getCenter(find.text("B"));
      await _dragTile(tester, from: center, to: center);

      expect(reorders, isEmpty);
      expect(_renderedOrder(tester), ["A", "B", "C"]);
    });

    // O toque curto continua sendo o atalho para a conversão da moeda: só o
    // toque longo pega o cartão.
    testWidgets('o toque curto chega ao cartão, sem reordenar',
        (WidgetTester tester) async {
      final reorders = <List<int>>[];
      final taps = <String>[];
      await tester.pumpWidget(_GridHarness(const ["A", "B", "C"], reorders,
          onTapItem: taps.add));

      await tester.tap(find.text("B"));
      await tester.pumpAndSettle();

      expect(taps, ["B"]);
      expect(reorders, isEmpty);
    });

    testWidgets('um arrasto curto, sem toque longo, não move o cartão',
        (WidgetTester tester) async {
      final reorders = <List<int>>[];
      await tester.pumpWidget(_GridHarness(const ["A", "B", "C"], reorders));

      final gesture = await tester.startGesture(tester.getCenter(find.text("C")));
      await gesture.moveTo(tester.getCenter(find.text("A (destaque)")));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(reorders, isEmpty,
          reason: "arrastar a tela para rolar não pode reordenar a grade");
    });

    testWidgets('a grade vazia não desenha nada', (WidgetTester tester) async {
      await tester.pumpWidget(_GridHarness(const [], []));

      expect(find.byType(LongPressDraggable<int>), findsNothing);
    });

    // Arrastar não existe para quem navega pelo leitor de tela: as mesmas
    // reordenações precisam estar disponíveis como ação de acessibilidade.
    // A grade da tela inicial fecha com o cartão de acrescentar uma moeda, que
    // fica sempre no fim e fora do arrasto que reordena as bolhas.
    testWidgets('o cartão do fim vem depois dos outros',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          _GridHarness(const ["A", "B", "C"], [], footerLabel: "Adicionar"));

      expect(_renderedOrder(tester), ["A", "B", "C", "Adicionar"]);
    });

    testWidgets('o cartão do fim não é arrastável', (WidgetTester tester) async {
      await tester.pumpWidget(
          _GridHarness(const ["A", "B", "C"], [], footerLabel: "Adicionar"));

      expect(find.byType(LongPressDraggable<int>), findsNWidgets(3),
          reason: "um arrastável por cartão de moeda, e nenhum para o do fim");

      final center = tester.getCenter(find.text("Adicionar"));
      await _dragTile(tester, from: center, to: tester.getCenter(find.text("B")));

      expect(_renderedOrder(tester), ["A", "B", "C", "Adicionar"]);
    });

    testWidgets('soltar um cartão sobre o do fim não reordena nada',
        (WidgetTester tester) async {
      final reorders = <List<int>>[];
      await tester.pumpWidget(_GridHarness(const ["A", "B", "C"], reorders,
          footerLabel: "Adicionar"));

      await _dragTile(tester,
          from: tester.getCenter(find.text("B")),
          to: tester.getCenter(find.text("Adicionar")));

      expect(reorders, isEmpty,
          reason: "nada pode tomar o lugar do cartão do fim");
      expect(_renderedOrder(tester), ["A", "B", "C", "Adicionar"]);
    });

    testWidgets('o toque no cartão do fim chega a quem o montou',
        (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(_GridHarness(const ["A", "B"], [],
          footerLabel: "Adicionar", onTapFooter: () => taps++));

      await tester.tap(find.text("Adicionar"));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    // Sem nenhum cartão de moeda, o de acrescentar é o único da grade: fica na
    // posição de destaque, senão a grade abriria com meia linha vazia.
    testWidgets('sem cartões, o do fim assume o destaque',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(_GridHarness(const [], [], footerLabel: "Adicionar"));

      expect(find.text("Adicionar (destaque)"), findsOneWidget);
    });

    // A faixa de descarte só existe enquanto um cartão está no ar: fora do
    // arrasto ela tomaria o rodapé da tela sem ter o que receber.
    testWidgets('a faixa de descarte só aparece durante o arrasto',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(_GridHarness(const ["A", "B", "C"], [], deletions: []));

      expect(find.text("Solte aqui para remover"), findsNothing);

      final gesture =
          await tester.startGesture(tester.getCenter(find.text("B")));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text("Solte aqui para remover"), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text("Solte aqui para remover"), findsNothing);
    });

    // Sem um Material por perto, o texto e o ícone da faixa levariam o
    // sublinhado amarelo e preto que o Flutter desenha em debug por faltar um
    // DefaultTextStyle — o Overlay em que a faixa vive não tem um por conta
    // própria.
    testWidgets('a faixa de descarte tem um Material por perto',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(_GridHarness(const ["A", "B", "C"], [], deletions: []));

      final gesture =
          await tester.startGesture(tester.getCenter(find.text("B")));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await tester.pump();

      expect(
        find.ancestor(
          of: find.text("Solte aqui para remover"),
          matching: find.byType(Material),
        ),
        findsWidgets,
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('soltar o cartão sobre a faixa o tira da grade',
        (WidgetTester tester) async {
      final deletions = <int>[];
      final reorders = <List<int>>[];
      await tester.pumpWidget(
          _GridHarness(const ["A", "B", "C"], reorders, deletions: deletions));

      final gesture =
          await tester.startGesture(tester.getCenter(find.text("B")));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture
          .moveTo(tester.getCenter(find.text("Solte aqui para remover")));
      await tester.pump();
      // Em cima da faixa o ícone muda: é o aviso de que levantar o dedo ali
      // remove o cartão.
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(deletions, [1]);
      expect(reorders, isEmpty,
          reason: "soltar na faixa remove o cartão, não o reordena");
      expect(_renderedOrder(tester), ["A", "C"]);
      expect(find.text("Solte aqui para remover"), findsNothing,
          reason: "a faixa some junto com o cartão removido");
    });

    // Sem retorno de remoção o arrasto continua sendo só o que era: uma
    // reordenação.
    testWidgets('sem onDelete a faixa não aparece',
        (WidgetTester tester) async {
      await tester.pumpWidget(_GridHarness(const ["A", "B", "C"], []));

      final gesture =
          await tester.startGesture(tester.getCenter(find.text("B")));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text("Solte aqui para remover"), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('soltar um cartão sobre outro continua reordenando',
        (WidgetTester tester) async {
      final deletions = <int>[];
      final reorders = <List<int>>[];
      await tester.pumpWidget(
          _GridHarness(const ["A", "B", "C"], reorders, deletions: deletions));

      await _dragTile(tester,
          from: tester.getCenter(find.text("C")),
          to: tester.getCenter(find.text("A (destaque)")));

      expect(deletions, isEmpty);
      expect(reorders, [
        [2, 0]
      ]);
    });

    // Arrastar até a faixa não existe para quem navega pelo leitor de tela: a
    // remoção precisa estar disponível como ação.
    testWidgets('oferece a ação de remover ao leitor de tela',
        (WidgetTester tester) async {
      final deletions = <int>[];
      await tester.pumpWidget(
          _GridHarness(const ["A", "B", "C"], [], deletions: deletions));

      final actions = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((widget) => widget.properties.customSemanticsActions)
          .whereType<Map<CustomSemanticsAction, VoidCallback>>()
          .where((actions) => actions.isNotEmpty)
          .toList();

      // A ação de remover do último cartão o tira da grade.
      final remove =
          actions.last.entries.firstWhere((entry) => entry.key.label == "Remover");
      remove.value();
      await tester.pumpAndSettle();

      expect(deletions, [2]);
      expect(_renderedOrder(tester), ["A", "B"]);
    });

    testWidgets('oferece as ações de mover ao leitor de tela',
        (WidgetTester tester) async {
      final reorders = <List<int>>[];
      await tester.pumpWidget(_GridHarness(const ["A", "B", "C"], reorders));

      final actions = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((widget) => widget.properties.customSemanticsActions)
          .whereType<Map<CustomSemanticsAction, VoidCallback>>()
          .where((actions) => actions.isNotEmpty)
          .toList();

      expect(actions.length, 3, reason: "uma ação por cartão da grade");
      // O primeiro cartão não tem para onde ir para trás.
      expect(
          actions.first.keys.map((action) => action.label), ["Mover para frente"]);

      // A ação do último cartão o move uma posição para trás.
      actions.last.values.first();
      await tester.pumpAndSettle();

      expect(reorders, [
        [2, 1]
      ]);
      expect(_renderedOrder(tester), ["A", "C", "B"]);
    });

    // Mover o cartão do fim não significa nada: ele não tem posição na lista
    // de moedas para trocar com ninguém.
    testWidgets('o cartão do fim não ganha as ações de mover',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          _GridHarness(const ["A", "B", "C"], [], footerLabel: "Adicionar"));

      final actions = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((widget) => widget.properties.customSemanticsActions)
          .whereType<Map<CustomSemanticsAction, VoidCallback>>()
          .where((actions) => actions.isNotEmpty)
          .toList();

      expect(actions.length, 3,
          reason: "uma ação por cartão de moeda, nenhuma para o do fim");
    });
  });
}
