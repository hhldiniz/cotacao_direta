import 'package:cotacao_direta/util/color_utils.dart';
import 'package:cotacao_direta/util/responsive.dart';
import 'package:flutter/material.dart';

/// Cartão "bento" de cotação, usado na grade da tela inicial.
///
/// Reúne as micro-interações do novo layout (feedback de toque e um pequeno
/// indicador de atualização) em um único lugar, mas deixa a obtenção do valor
/// em si a cargo do widget passado em [valueWidget] (DollarExchangeRate,
/// EuroExchangeRate etc.) — a camada de dados (blocs/streams) não muda.
class CurrencyRateCard extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String code;
  final String label;
  final Widget valueWidget;

  /// Cartão de destaque (maior, no topo da grade) ou cartão compacto.
  final bool hero;

  /// true enquanto a tela está buscando cotações novas. É só feedback do
  /// estado real de carregamento, não representa nenhum dado inventado.
  final bool isRefreshing;

  final VoidCallback? onTap;

  const CurrencyRateCard({
    super.key,
    required this.color,
    required this.icon,
    required this.code,
    required this.label,
    required this.valueWidget,
    this.hero = false,
    this.isRefreshing = false,
    this.onTap,
  });

  @override
  State<CurrencyRateCard> createState() => _CurrencyRateCardState();
}

class _CurrencyRateCardState extends State<CurrencyRateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed || widget.onTap == null) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final scale = Responsive.scaleFactor(context);
    final backgroundColor = circleBackgroundColor(context, widget.color);
    final contentColor = contrastingTextColor(backgroundColor);
    final radius = widget.hero ? 24.0 : 18.0;

    final card = AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: (widget.hero ? 18 : 14) * scale,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.35),
              blurRadius: _pressed ? 4 : 12,
              offset: Offset(0, _pressed ? 1 : 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.icon,
                  color: contentColor,
                  size: (widget.hero ? 20 : 16) * scale,
                ),
                SizedBox(width: 6 * scale),
                Expanded(
                  child: Text(
                    widget.hero ? "${widget.label} · ${widget.code}" : widget.code,
                    style: TextStyle(
                      color: contentColor.withValues(alpha: 0.85),
                      fontSize: (widget.hero ? 13 : 12) * scale,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 6 * scale),
                _RefreshDot(animation: _pulseController, color: contentColor, active: widget.isRefreshing),
              ],
            ),
            SizedBox(height: (widget.hero ? 10 : 6) * scale),
            widget.valueWidget,
          ],
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: card,
    );
  }
}

/// Pontinho que pulsa enquanto [active] é true (tela buscando cotações
/// novas) e fica estático, discreto, no resto do tempo.
class _RefreshDot extends AnimatedWidget {
  final Color color;
  final bool active;

  const _RefreshDot({
    required Animation<double> animation,
    required this.color,
    required this.active,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final pulse = listenable as Animation<double>;
    final opacity = active ? 0.35 + pulse.value * 0.5 : 0.3;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}
