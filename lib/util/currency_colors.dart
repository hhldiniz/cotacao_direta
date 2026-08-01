import 'package:flutter/material.dart';

/// Paleta vibrante do app: mais saturada que o Material padrão para atrair um
/// público mais jovem, mas ainda construída em cima de `ColorScheme.fromSeed`
/// (Material 3), o que preserva contraste e os padrões de navegação
/// familiares para quem já usa qualquer outro app Material.
class CurrencyColors {
  CurrencyColors._();

  /// Cor semente do tema do app (usada em `ColorScheme.fromSeed`).
  static const seed = Color(0xFF6C4DFF);

  /// Cores de destaque por moeda, usadas nos cartões da tela inicial.
  /// Mantêm a mesma associação moeda->cor do design anterior (dólar em
  /// amber, euro em azul, dólar canadense em laranja/coral, iene em rosa),
  /// só que em tons mais vivos.
  static const usd = Color(0xFFFFB300);
  static const eur = Color(0xFF3D5AFE);
  static const cad = Color(0xFFFF5252);
  static const jpy = Color(0xFFE91E8C);
}
