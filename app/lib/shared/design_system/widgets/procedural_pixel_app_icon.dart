import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Виджет пиксельной иконки приложения в стиле Minecraft.
///
/// Если доступны байты иконки [iconBytes], отображает их с [FilterQuality.none]
/// (nearest-neighbor), что превращает миниатюрное 20x20 превью в четкий пиксель-арт.
///
/// Если иконка отсутствует, процедурно генерирует уникальный симметричный
/// 5x5 пиксельный герб Minecraft на основе хэша [packageName].
class ProceduralPixelAppIcon extends StatelessWidget {
  const ProceduralPixelAppIcon({
    super.key,
    required this.name,
    required this.packageName,
    this.iconBytes,
    this.size = 38.0,
    this.isSelected = false,
  });

  final String name;
  final String packageName;
  final Uint8List? iconBytes;
  final double size;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF141622),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? AppColors.mcGrass.withValues(alpha: 0.7)
              : const Color(0x33FFFFFF),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Иконка приложения (реальная пиксельная или процедурная)
          if (iconBytes != null && iconBytes!.isNotEmpty)
            Image.memory(
              iconBytes!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none, // Четкие пиксельные грани Minecraft
              errorBuilder: (_, _, _) => _buildProceduralFallback(),
            )
          else
            _buildProceduralFallback(),

          // 2. Верхняя 3D-фаска пиксельного блока (световой блик)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1.5,
            child: Container(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),

          // 3. Нижняя 3D-тень пиксельного блока
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 1.5,
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProceduralFallback() {
    return CustomPaint(
      size: Size(size, size),
      painter: _ProceduralEmblemPainter(
        seed: packageName.isNotEmpty ? packageName.hashCode : name.hashCode,
      ),
    );
  }
}

/// Процедурный генератор 5x5 пиксельного герба Minecraft
class _ProceduralEmblemPainter extends CustomPainter {
  const _ProceduralEmblemPainter({required this.seed});

  final int seed;

  static const _palette = [
    Color(0xFF8B5CF6), // Ender Purple
    Color(0xFF10B981), // Emerald
    Color(0xFF38BDF8), // Diamond Cyan
    Color(0xFFF59E0B), // Gold
    Color(0xFFEF4444), // Redstone
    Color(0xFFEC4899), // Amethyst
    Color(0xFF06B6D4), // Prismarine
    Color(0xFF84CC16), // Slime
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final absSeed = seed.abs();
    final primaryColor = _palette[absSeed % _palette.length];
    final bgPaint = Paint()..color = const Color(0xFF10121C);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final pixelPaint = Paint()..color = primaryColor;
    const grid = 5;
    final cellW = size.width / grid;
    final cellH = size.height / grid;

    // Генерируем зеркально-симметричный 5x5 узор
    for (int y = 0; y < grid; y++) {
      for (int x = 0; x <= grid ~/ 2; x++) {
        final bit = ((absSeed >> (y * 3 + x)) & 1) == 1;
        if (bit) {
          // Рисуем левую половину
          canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.1, cellH + 0.1),
            pixelPaint,
          );
          // Зеркалим на правую половину
          final mirroredX = grid - 1 - x;
          if (mirroredX != x) {
            canvas.drawRect(
              Rect.fromLTWH(mirroredX * cellW, y * cellH, cellW + 0.1, cellH + 0.1),
              pixelPaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProceduralEmblemPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
