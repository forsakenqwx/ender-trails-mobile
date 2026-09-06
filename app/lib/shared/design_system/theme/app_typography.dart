import 'package:flutter/material.dart';

/// Типографика.
///
/// `PixCyrillic` (SIL OFL 1.1) — единственный шрифт, у которого есть и пиксельная
/// эстетика, и полная кириллица. Классические пиксельные шрифты (Press Start 2P и др.)
/// кириллицы не содержат, поэтому приложение на них рассыпалось бы.
///
/// Размеры только кратные сетке (12/16/20/24/32), иначе шрифт мылит.
/// Для длинного текста используем [body] — системный sans, см. `docs/design-system.md` §1.
abstract final class AppTypography {
  /// Фирменный пиксельный шрифт PixCyrillic для игрового лора и атмосферы Minecraft/Ender.
  static const pixel = TextStyle(
    fontFamily: 'PixCyrillic',
    fontFamilyFallback: ['Roboto', 'sans-serif'],
    height: 1.0,
    letterSpacing: 1.0,
  );

  static TextStyle display(Color color) => pixel.copyWith(
        fontSize: 32,
        color: color,
      );

  static TextStyle headline(Color color) => pixel.copyWith(
        fontSize: 24,
        color: color,
      );

  static TextStyle title(Color color) => pixel.copyWith(
        fontSize: 20,
        color: color,
      );

  static TextStyle label(Color color) => pixel.copyWith(
        fontSize: 16,
        color: color,
      );

  static TextStyle caption(Color color) => pixel.copyWith(
        fontSize: 12,
        color: color,
      );

  /// Для абзацев, описаний и длинного текста используем чистый системный sans
  static TextStyle body(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: -0.1,
        color: color,
      );
}
