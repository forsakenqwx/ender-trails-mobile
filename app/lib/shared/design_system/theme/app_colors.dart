import 'package:flutter/material.dart';

/// Палитра Ender Trails.
///
/// Полное описание — `docs/design-system.md` §2.
/// Правило: цвета берутся только отсюда, голых `Color(0xFF...)` в фичах быть не должно.
abstract final class AppColors {
  // Фон и поверхности (Apple Deep Dark & Glass)
  static const mcVoid = Color(0xFF08080C);
  static const mcDeepslate = Color(0xFF12131A);
  static const mcStone = Color(0xFF1A1B26);
  static const mcStoneLight = Color(0xFF2C2D3C);
  static const mcStoneDark = Color(0xFF0E0F16);

  /// Контур: в премиум-стиле это тонкий полупрозрачный стеклянный кант
  static const mcInk = Color(0x24FFFFFF);

  // Текст (Apple SF Pro Legibility)
  static const mcText = Color(0xFFF8FAFC);
  static const mcTextDim = Color(0xFF94A3B8);
  static const mcTextMuted = Color(0xFF64748B);

  // Премиум-акценты (Apple System Vibrancy)
  static const mcGrass = Color(0xFF10B981);
  static const mcEmerald = Color(0xFF10B981);
  static const mcGrassDark = Color(0xFF059669);
  static const mcGold = Color(0xFFF59E0B);
  static const mcRedstone = Color(0xFFEF4444);
  static const mcRedstoneHot = Color(0xFFFF453A);
  static const mcDiamond = Color(0xFF06B6D4);
  static const mcEnder = Color(0xFF8B5CF6);
  static const mcEnderLight = Color(0xFFA78BFA);
  static const mcPurple = Color(0xFF8B5CF6);
  static const mcPurpleLight = Color(0xFFA78BFA);
  static const mcPearl = Color(0xFF14B8A6);
  static const mcLapis = Color(0xFF3B82F6);

  // Глассморфизм
  static const glassSurface = Color(0x12FFFFFF);
  static const glassCard = Color(0x18FFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);
  static const glassBorderHighlight = Color(0x33FFFFFF);

  /// Цвет лампы/акцента для статуса туннеля.
  static Color statusColor(bool connected, {bool busy = false, bool failed = false}) {
    if (failed) return mcRedstone;
    if (busy) return mcGold;
    if (connected) return mcGrass;
    return const Color(0xFF64748B);
  }
}
