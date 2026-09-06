import 'package:flutter/material.dart';

/// Аутентичная пиксельная кирка из Minecraft (16×16 пиксельная сетка).
class MinecraftPickaxeIcon extends StatelessWidget {
  const MinecraftPickaxeIcon({
    super.key,
    this.size = 20,
    this.isEnder = false,
  });

  final double size;
  final bool isEnder;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PickaxePainter(isEnder: isEnder),
    );
  }
}

class _PickaxePainter extends CustomPainter {
  const _PickaxePainter({required this.isEnder});

  final bool isEnder;

  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / 16.0;
    final paint = Paint()..style = PaintingStyle.fill;

    // Палитра
    // Рукоять палки
    final stickLight = const Color(0xFF8F6826);
    final stickDark = const Color(0xFF563B12);

    // Лезвие (Эндер фиолетовый или Алмазный циан)
    final bladeLight = isEnder ? const Color(0xFFD8B4FE) : const Color(0xFF8CF4E2);
    final bladeMain = isEnder ? const Color(0xFFA855F7) : const Color(0xFF4AEDD7);
    final bladeDark = isEnder ? const Color(0xFF7E22CE) : const Color(0xFF2CBAA8);
    final bladeShadow = isEnder ? const Color(0xFF4A0E4E) : const Color(0xFF1B4E49);

    void drawPx(int x, int y, Color color) {
      paint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize + 0.1, pixelSize + 0.1),
        paint,
      );
    }

    // Лезвие кирки (форма дуги в верхней правой части)
    // Верхняя горизонталь лезвия
    drawPx(7, 1, bladeShadow);
    drawPx(8, 1, bladeLight);
    drawPx(9, 1, bladeLight);
    drawPx(10, 1, bladeMain);
    drawPx(11, 1, bladeShadow);

    drawPx(6, 2, bladeShadow);
    drawPx(7, 2, bladeLight);
    drawPx(8, 2, bladeMain);
    drawPx(9, 2, bladeMain);
    drawPx(10, 2, bladeDark);
    drawPx(11, 2, bladeDark);
    drawPx(12, 2, bladeShadow);

    drawPx(5, 3, bladeShadow);
    drawPx(6, 3, bladeLight);
    drawPx(7, 3, bladeMain);
    drawPx(8, 3, bladeDark);
    drawPx(9, 3, bladeShadow);
    drawPx(10, 3, bladeMain);
    drawPx(11, 3, bladeDark);
    drawPx(12, 3, bladeShadow);

    drawPx(4, 4, bladeShadow);
    drawPx(5, 4, bladeLight);
    drawPx(6, 4, bladeDark);
    drawPx(7, 4, bladeShadow);
    drawPx(11, 4, bladeDark);
    drawPx(12, 4, bladeShadow);

    drawPx(3, 5, bladeShadow);
    drawPx(4, 5, bladeLight);
    drawPx(5, 5, bladeShadow);
    drawPx(11, 5, bladeDark);
    drawPx(12, 5, bladeShadow);

    drawPx(2, 6, bladeShadow);
    drawPx(3, 6, bladeDark);
    drawPx(4, 6, bladeShadow);
    drawPx(10, 6, bladeDark);
    drawPx(11, 6, bladeShadow);

    drawPx(1, 7, bladeShadow);
    drawPx(2, 7, bladeDark);
    drawPx(3, 7, bladeShadow);

    // Палка (диагональ от (2, 13) до (9, 6))
    drawPx(2, 13, stickDark);
    drawPx(3, 13, stickDark);

    drawPx(3, 12, stickLight);
    drawPx(4, 12, stickDark);

    drawPx(4, 11, stickLight);
    drawPx(5, 11, stickDark);

    drawPx(5, 10, stickLight);
    drawPx(6, 10, stickDark);

    drawPx(6, 9, stickLight);
    drawPx(7, 9, stickDark);

    drawPx(7, 8, stickLight);
    drawPx(8, 8, stickDark);

    drawPx(8, 7, stickLight);
    drawPx(9, 7, stickDark);

    drawPx(9, 6, stickLight);
    drawPx(10, 6, stickDark);
  }

  @override
  bool shouldRepaint(covariant _PickaxePainter oldDelegate) =>
      oldDelegate.isEnder != isEnder;
}
