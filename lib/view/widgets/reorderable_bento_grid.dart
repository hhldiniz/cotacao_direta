import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:flutter/material.dart';
// CustomSemanticsAction: o material.dart não reexporta o pacote de semântica.
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// Constrói o cartão de uma posição da grade. [hero] indica a posição de
/// destaque (a primeira), que ocupa a largura toda.
typedef BentoTileBuilder = Widget Function(
    BuildContext context, int index, bool hero);

/// A grade "bento" da tela inicial: o primeiro cartão em destaque, ocupando a
/// largura toda, e os demais em pares — agora com reordenação por toque longo.
///
/// Segurar o dedo sobre um cartão o solta da grade e o prende ao dedo; soltá-lo
/// sobre outro cartão põe o arrastado naquela posição e empurra o resto,
/// exatamente como uma lista reordenável. Arrastar um cartão até a primeira
/// posição é o que promove uma moeda ao destaque — antes isso só era possível
/// refazendo a escolha inteira na aba de opções.
///
/// A reordenação não é gravada aqui: [onReorder] avisa quem monta a grade, que
/// é quem conhece a lista de moedas e o que fazer com a ordem nova.
class ReorderableBentoGrid extends StatelessWidget {
  final int itemCount;
  final BentoTileBuilder itemBuilder;

  /// Chamado quando um cartão é solto sobre outro: o cartão de [oldIndex] deve
  /// passar a ocupar [newIndex], empurrando os demais.
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Espaço entre cartões, na horizontal e na vertical.
  final double spacing;

  /// Rótulos das ações equivalentes ao arrasto, oferecidas ao leitor de tela:
  /// arrastar não existe para quem navega por gestos de acessibilidade, então
  /// mover um cartão uma posição para trás ou para frente precisa estar
  /// disponível como ação.
  final String? moveEarlierSemanticsLabel;
  final String? moveLaterSemanticsLabel;

  const ReorderableBentoGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.spacing = 12,
    this.moveEarlierSemanticsLabel,
    this.moveLaterSemanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();
    // A largura de cada cartão é necessária para o cartão que segue o dedo:
    // ele é montado no Overlay, fora da grade, onde nada o limitaria e ele
    // ficaria com a largura da tela inteira.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final heroWidth = constraints.maxWidth;
        final pairedWidth = (constraints.maxWidth - spacing) / 2;
        final rows = <Widget>[
          _tile(context, 0, hero: true, width: heroWidth),
        ];

        for (var first = 1; first < itemCount; first += 2) {
          final second = first + 1;
          rows.add(SizedBox(height: spacing));
          // O IntrinsicHeight é obrigatório aqui: a Row usa
          // CrossAxisAlignment.stretch para os dois cartões terminarem com a
          // mesma altura, mas o eixo transversal de uma Row é o vertical, que
          // dentro do SingleChildScrollView é ilimitado. Sem uma altura
          // definida, o stretch não tem o que esticar e o layout falha
          // (RenderFlex sem size, erro a cada frame).
          rows.add(IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _tile(context, first, hero: false, width: pairedWidth),
                ),
                SizedBox(width: spacing),
                // Numa linha ímpar o espaço vazio à direita fica reservado,
                // para o cartão sozinho ter a mesma largura dos das outras
                // linhas.
                Expanded(
                  child: second < itemCount
                      ? _tile(context, second, hero: false, width: pairedWidth)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }

  /// Um cartão da grade: alvo de soltura para os outros cartões e, ele mesmo,
  /// arrastável depois do toque longo.
  Widget _tile(BuildContext context, int index,
      {required bool hero, required double width}) {
    final radius = hero ? BentoRadius.hero : BentoRadius.standard;
    final child = itemBuilder(context, index, hero);

    final draggable = LongPressDraggable<int>(
      data: index,
      // O cartão que segue o dedo. É montado de novo, e não uma cópia do que
      // está na tela: o Overlay é outra subárvore, e o valor da cotação vem de
      // uma leitura própria — que, para um par já buscado, para no banco.
      feedback: _dragFeedback(context, index, hero: hero, width: width),
      childWhenDragging: _emptySlot(context, child, radius),
      // O mesmo retorno tátil de quem já arrastou um ícone na tela inicial do
      // aparelho: sem ele não fica claro que o toque longo pegou o cartão.
      onDragStarted: () => HapticFeedback.mediumImpact(),
      child: child,
    );

    return DragTarget<int>(
      // Soltar um cartão sobre ele mesmo não é uma reordenação.
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        HapticFeedback.selectionClick();
        onReorder(details.data, index);
      },
      builder: (BuildContext context, List<int?> candidateData, _) {
        final isTarget = candidateData.isNotEmpty;
        return _semantics(
          index,
          AnimatedScale(
            scale: isTarget ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: DecoratedBox(
              // Contorno por cima do cartão, e não atrás: é ele que diz em
              // qual posição o cartão arrastado vai cair.
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: isTarget
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: draggable,
            ),
          ),
        );
      },
    );
  }

  /// Ações de reordenação para o leitor de tela, quando os rótulos foram
  /// informados. Sem elas, a grade seria reordenável só por arrasto — um gesto
  /// que não existe para quem usa TalkBack ou VoiceOver.
  Widget _semantics(int index, Widget child) {
    final moveEarlier = moveEarlierSemanticsLabel;
    final moveLater = moveLaterSemanticsLabel;
    if (moveEarlier == null && moveLater == null) return child;
    return Semantics(
      container: true,
      customSemanticsActions: {
        if (moveEarlier != null && index > 0)
          CustomSemanticsAction(label: moveEarlier): () =>
              onReorder(index, index - 1),
        if (moveLater != null && index < itemCount - 1)
          CustomSemanticsAction(label: moveLater): () =>
              onReorder(index, index + 1),
      },
      child: child,
    );
  }

  /// O cartão preso ao dedo: o mesmo cartão, um pouco maior e com a largura
  /// que ele tinha na grade.
  Widget _dragFeedback(BuildContext context, int index,
      {required bool hero, required double width}) {
    return Material(
      // O Overlay não tem Material, e sem um a pintura de texto e tinta dos
      // widgets do cartão não teria onde acontecer. Transparente para o
      // arredondamento e a sombra continuarem sendo os do próprio cartão.
      type: MaterialType.transparency,
      child: Transform.scale(
        scale: 1.05,
        child: SizedBox(
          width: width,
          child: Opacity(
            opacity: 0.92,
            child: itemBuilder(context, index, hero),
          ),
        ),
      ),
    );
  }

  /// O buraco deixado na grade pelo cartão que está sendo arrastado. Mantém
  /// [child] invisível dentro para o espaço continuar com o tamanho exato do
  /// cartão, e a grade não pular enquanto o dedo está no ar.
  Widget _emptySlot(BuildContext context, Widget child, double radius) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border.all(color: colorScheme.outlineVariant, width: 2),
      ),
      child: Opacity(
        opacity: 0,
        child: IgnorePointer(child: child),
      ),
    );
  }
}
