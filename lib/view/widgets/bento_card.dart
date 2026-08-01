import 'package:cotacao_direta/util/color_utils.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:flutter/material.dart';

/// Raios usados pelos cartões do app, para que todas as telas terminem com o
/// mesmo arredondamento da grade da tela inicial.
class BentoRadius {
  BentoRadius._();

  /// Cartão de destaque (o maior da grade).
  static const hero = 24.0;

  /// Cartão comum.
  static const standard = 18.0;
}

/// Título de seção no estilo da tela inicial: texto curto, em maiúscula de
/// frase, na cor primária do tema.
class BentoSectionTitle extends StatelessWidget {
  final String label;

  const BentoSectionTitle(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final scale = Responsive.scaleFactor(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24 * scale,
        20 * scale,
        24 * scale,
        8 * scale,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Cartão arredondado usado em todas as telas, no mesmo estilo dos cartões de
/// cotação da tela inicial.
///
/// Sem [accentColor] o cartão usa uma superfície neutra do tema, adequada para
/// conteúdo denso (listas, formulários). Com [accentColor] ele ganha o fundo
/// colorido e a sombra tingida dos cartões de moeda — reservado para destaques,
/// para a cor não virar ruído.
///
/// Quando [onTap] é informado, o cartão encolhe levemente ao toque, o mesmo
/// retorno tátil dos cartões da grade.
class BentoCard extends StatefulWidget {
  final Widget child;

  /// Cor de destaque. Nulo = superfície neutra do tema.
  final Color? accentColor;

  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;

  const BentoCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
    this.radius = BentoRadius.standard,
    this.onTap,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed || widget.onTap == null) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final scale = Responsive.scaleFactor(context);
    final colorScheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor;
    final backgroundColor = accent == null
        ? colorScheme.surfaceContainerHighest
        : circleBackgroundColor(context, accent);

    final borderRadius = BorderRadius.circular(widget.radius);

    Widget content = Padding(
      padding: widget.padding ?? EdgeInsets.all(16 * scale),
      child: _wrapContent(backgroundColor),
    );

    if (widget.onTap != null) {
      content = InkWell(
        onTap: widget.onTap,
        // Acompanha o estado de pressionado do próprio Ink, para o cartão
        // encolher junto com o splash.
        onHighlightChanged: _setPressed,
        child: content,
      );
    }

    // O cartão precisa ser um Material de verdade, e não só um contêiner
    // decorado: ListTile, SwitchListTile e InkWell pintam fundo e splash no
    // Material mais próximo. Com um DecoratedBox no meio, eles pintariam no
    // Material de trás e esconderiam a cor do cartão.
    Widget card = Material(
      color: backgroundColor,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    // A sombra tingida fica fora do Material, para não ser recortada por ele.
    if (accent != null) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: _pressed ? 4 : 12,
              offset: Offset(0, _pressed ? 1 : 6),
            ),
          ],
        ),
        child: card,
      );
    }

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: card,
    );
  }

  /// Em cartões com destaque, o conteúdo herda a cor de texto que contrasta
  /// com o fundo colorido; sem destaque, segue as cores normais do tema.
  Widget _wrapContent(Color backgroundColor) {
    if (widget.accentColor == null) return widget.child;
    final contentColor = contrastingTextColor(backgroundColor);
    return DefaultTextStyle.merge(
      style: TextStyle(color: contentColor),
      child: IconTheme.merge(
        data: IconThemeData(color: contentColor),
        child: widget.child,
      ),
    );
  }
}
