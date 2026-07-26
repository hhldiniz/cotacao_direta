import 'package:flutter/material.dart';

/// As telas do app foram desenhadas com tamanhos fixos (padding, fontes,
/// ícones) pensados para celular. Em telas grandes (tablet/desktop) esses
/// valores fixos ficam desproporcionalmente pequenos, então usamos um fator
/// de escala baseado na largura da tela para aumentá-los proporcionalmente.
///
/// Os breakpoints seguem as faixas "compact/medium/expanded" do Material 3.
class Responsive {
  static const double _mediumBreakpoint = 600;
  static const double _expandedBreakpoint = 840;

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= _mediumBreakpoint;

  /// Multiplicador a ser aplicado sobre tamanhos pensados para celular.
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= _expandedBreakpoint) return 1.8;
    if (width >= _mediumBreakpoint) return 1.35;
    return 1.0;
  }

  /// Largura máxima de conteúdo para páginas com formulários/listas, para
  /// que não fiquem esticadas de ponta a ponta em janelas muito largas.
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= _expandedBreakpoint) return 720;
    return width;
  }
}
