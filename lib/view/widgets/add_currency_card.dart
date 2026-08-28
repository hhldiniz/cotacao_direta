import 'package:cotacao_direta/util/responsive.dart';
import 'package:cotacao_direta/view/widgets/bento_card.dart';
import 'package:flutter/material.dart';

/// O cartão que fecha a grade da tela inicial: um sinal de mais que abre a
/// escolha das moedas mostradas.
///
/// Escolher as moedas era coisa da aba de opções, longe da grade que elas
/// formam; aqui o gesto fica onde o resultado dele aparece. Por isso o cartão
/// não é uma bolha de moeda: contorno em vez de fundo colorido, para se ler
/// como um espaço vago à espera de uma moeda, e não como mais uma cotação.
///
/// Ele é sempre o último da grade e não entra na reordenação: quem o mantém
/// fora do arrasto é o `footerBuilder` da grade.
class AddCurrencyCard extends StatelessWidget {
  /// Ocupa a posição de destaque da grade (a largura toda), o que só acontece
  /// quando não há nenhuma moeda em bolha.
  final bool hero;

  final String label;
  final VoidCallback onTap;

  const AddCurrencyCard({
    super.key,
    required this.label,
    required this.onTap,
    this.hero = false,
  });

  @override
  Widget build(BuildContext context) {
    final scale = Responsive.scaleFactor(context);
    final colorScheme = Theme.of(context).colorScheme;
    final radius = hero ? BentoRadius.hero : BentoRadius.standard;
    final borderRadius = BorderRadius.circular(radius);

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: colorScheme.outlineVariant, width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: (hero ? 18 : 14) * scale,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: (hero ? 32 : 26) * scale,
                  color: colorScheme.primary,
                ),
                SizedBox(height: 6 * scale),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (hero ? 14 : 12) * scale,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
