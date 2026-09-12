import 'package:flutter/painting.dart';

/// **Utilidade de pintura** — deriva tons de sombra/luz de uma cor mantendo o
/// matiz. Compartilhada pelos desenhos à mão (`Star3D`, `Trophy3D`,
/// `_ChestPainter`).
///
/// [shade]: `amount` 0 = cor original; 1 = quase preto.
/// [lighten]: `amount` 0 = cor original; 1 = quase branco.
Color shade(Color base, double amount) {
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0))
      .toColor();
}

Color lighten(Color base, double amount) {
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withLightness(
        (hsl.lightness + (1 - hsl.lightness) * amount).clamp(0.0, 1.0),
      )
      .toColor();
}
