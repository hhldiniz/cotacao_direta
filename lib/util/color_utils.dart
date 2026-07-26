import 'package:flutter/material.dart';

/// Ajusta a cor-base de um círculo de cotação conforme o brilho do tema: no
/// modo escuro reduzimos um pouco a luminosidade para a cor não "gritar"
/// contra o fundo preto, mantendo a identidade visual de cada moeda.
Color circleBackgroundColor(BuildContext context, Color baseColor) {
  if (Theme.of(context).brightness != Brightness.dark) return baseColor;
  final hsl = HSLColor.fromColor(baseColor);
  return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
}

/// Cor de texto (preto ou branco) com contraste adequado para ser usada
/// sobre [background], calculada a partir do brilho estimado da cor.
Color contrastingTextColor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : Colors.black87;
}
