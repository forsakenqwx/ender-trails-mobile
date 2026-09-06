import 'package:flutter/material.dart';

/// Виджет флага страны в аутентичном пиксельном стиле Minecraft.
///
/// Рисует процедурный пиксель-арт 18x12 блоков с текстурой шерсти,
/// 3D-фаской блока и четкой пиксельной окантовкой.
class MinecraftFlag extends StatelessWidget {
  const MinecraftFlag({
    super.key,
    required this.countryCode,
    this.width = 36.0,
    this.height = 24.0,
    this.borderRadius = 4.0,
    this.showBorder = true,
  });

  final String countryCode;
  final double width;
  final double height;
  final double borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              offset: Offset(0, 1.5),
              blurRadius: 2.0,
            ),
          ],
          border: showBorder
              ? Border.all(
                  color: const Color(0xFF161722),
                  width: 1.2,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius > 1 ? borderRadius - 1 : 0),
          child: CustomPaint(
            size: Size(width, height),
            painter: MinecraftFlagPainter(countryCode: countryCode.toUpperCase()),
          ),
        ),
      ),
    );
  }
}

/// Художник пиксельной сетки флага (18x12 блоков).
class MinecraftFlagPainter extends CustomPainter {
  const MinecraftFlagPainter({required this.countryCode});

  final String countryCode;

  static const int cols = 18;
  static const int rows = 12;

  // Базовая палитра майнкрафтовской шерсти и флагов
  static const cWhite = Color(0xFFE4E4E4);
  static const cRed = Color(0xFFC02626);
  static const cDarkRed = Color(0xFF8F1818);
  static const cBlue = Color(0xFF1E439B);
  static const cNavy = Color(0xFF0F1E4A);
  static const cCyan = Color(0xFF009EA8);
  static const cYellow = Color(0xFFF6BC1A);
  static const cBlack = Color(0xFF222226);
  static const cOrange = Color(0xFFE26A18);
  static const cGreen = Color(0xFF388E3C);
  static const cDirtBrown = Color(0xFF6B4527);
  static const cGrassGreen = Color(0xFF4C982C);
  static const cEnderPurple = Color(0xFF6D28D9);
  static const cEnderDark = Color(0xFF1E1035);

  static const cLatviaRed = Color(0xFF7A202A);
  static const cEmeraldGreen = Color(0xFF169B62);
  static const cBrazilGreen = Color(0xFF009C3B);
  static const cBrazilBlue = Color(0xFF002776);
  static const cHongKongRed = Color(0xFFC01525);
  static const cSpainRed = Color(0xFFC60B1E);
  static const cSpainGold = Color(0xFFFFC400);

  Color _getColor(int x, int y) {
    switch (countryCode) {
      // 🇱🇻 Латвия (LV / LVA): карминово-бордовый, узкая белая полоса по центру (пропорция 5:2:5)
      case 'LV':
      case 'LVA':
        if (y >= 5 && y <= 6) return cWhite;
        return cLatviaRed;

      // 🇮🇹 Италия (IT / ITA): зеленый, белый, красный вертикальный триколор
      case 'IT':
      case 'ITA':
        if (x < 6) return cEmeraldGreen;
        if (x < 12) return cWhite;
        return cRed;

      // 🇱🇹 Литва (LT / LTU): желтый, зеленый, красный горизонтальный триколор
      case 'LT':
      case 'LTU':
        if (y < 4) return cYellow;
        if (y < 8) return cGreen;
        return cRed;

      // 🇨🇿 Чехия (CZ / CZE): синий шеврон слева, белый верх, красный низ
      case 'CZ':
      case 'CZE':
        final isTriangle = (y <= 5 && x <= (y + 1) * 1.4) ||
            (y >= 6 && x <= (12 - y) * 1.4);
        if (isTriangle) return cBlue;
        if (y < 6) return cWhite;
        return cRed;

      // 🇮🇪 Ирландия (IE / IRL): зеленый, белый, оранжевый
      case 'IE':
      case 'IRL':
        if (x < 6) return cEmeraldGreen;
        if (x < 12) return cWhite;
        return cOrange;

      // 🇧🇪 Бельгия (BE / BEL): черный, желтый, красный
      case 'BE':
      case 'BEL':
        if (x < 6) return cBlack;
        if (x < 12) return cYellow;
        return cRed;

      // 🇪🇸 Испания (ES / ESP): красный, широкий золотой с гербом, красный
      case 'ES':
      case 'ESP':
        if (y < 3 || y >= 9) return cSpainRed;
        if (x >= 4 && x <= 6 && y >= 4 && y <= 7) {
          if (y == 4) return cRed;
          if (x == 5 && y == 5) return cWhite;
          return cDarkRed;
        }
        return cSpainGold;

      // 🇭🇰 Гонконг (HK / HKG): алый фон, белая орхидея Баугиния
      case 'HK':
      case 'HKG':
        final isOrchid = (x >= 8 && x <= 9 && y >= 5 && y <= 6) ||
            (x >= 8 && x <= 9 && y >= 3 && y <= 4) ||
            (x >= 11 && x <= 12 && y >= 4 && y <= 5) ||
            (x >= 10 && x <= 11 && y >= 7 && y <= 8) ||
            (x >= 6 && x <= 7 && y >= 7 && y <= 8) ||
            (x >= 5 && x <= 6 && y >= 4 && y <= 5);
        if (isOrchid) return cWhite;
        return cHongKongRed;

      // 🇦🇹 Австрия (AT / AUT): красный, белый, красный
      case 'AT':
      case 'AUT':
        if (y >= 4 && y < 8) return cWhite;
        return cRed;

      // 🇧🇷 Бразилия (BR / BRA): зеленый, золотой ромб, синий круг с белой дугой
      case 'BR':
      case 'BRA':
        final dx = (x - 8.5).abs();
        final dy = (y - 5.5).abs();
        final inDiamond = (dx / 6.5 + dy / 4.2) <= 1.0;
        if (inDiamond) {
          final inCircle = (dx * dx + dy * dy * 1.4) <= 7.0;
          if (inCircle) {
            if (y == 5 && (x == 8 || x == 9 || x == 10)) return cWhite;
            return cBrazilBlue;
          }
          return cYellow;
        }
        return cBrazilGreen;

      // 🇳🇱 Нидерланды: красный, белый, синий
      case 'NL':
      case 'NLD':
        if (y < 4) return cRed;
        if (y < 8) return cWhite;
        return cBlue;

      // 🇩🇪 Германия: черный, красный, золото
      case 'DE':
      case 'DEU':
        if (y < 4) return cBlack;
        if (y < 8) return cRed;
        return cYellow;

      // 🇫🇮 Финляндия: белый фон, синий скандинавский крест
      case 'FI':
      case 'FIN':
        if (x >= 5 && x <= 7) return cBlue;
        if (y >= 4 && y <= 7) return cBlue;
        return cWhite;

      // 🇸🇪 Швеция: синий фон, золотой скандинавский крест
      case 'SE':
      case 'SWE':
        if (x >= 5 && x <= 7) return cYellow;
        if (y >= 4 && y <= 7) return cYellow;
        return cBlue;

      // 🇰🇿 Казахстан: бирюзовый, золотой орнамент и солнце с беркутом
      case 'KZ':
      case 'KAZ':
        if (x < 2) return cYellow;
        if (x >= 8 && x <= 10 && y >= 4 && y <= 6) return cYellow;
        if (y == 8 && (x >= 7 && x <= 11)) return cYellow;
        if (y == 7 && (x == 6 || x == 12)) return cYellow;
        return cCyan;

      // 🇷🇺 Россия: белый, синий, красный
      case 'RU':
      case 'RUS':
        if (y < 4) return cWhite;
        if (y < 8) return cBlue;
        return cRed;

      // 🇺🇸 США: полосы и синий кантон со звездами
      case 'US':
      case 'USA':
        final isRedStripe = (y % 2) == 0;
        if (x < 8 && y < 7) {
          if ((x == 2 || x == 5) && (y == 2 || y == 4)) return cWhite;
          return cNavy;
        }
        return isRedStripe ? cRed : cWhite;

      // 🇬🇧 Великобритания (Union Jack)
      case 'GB':
      case 'UK':
      case 'GBR':
        if (x >= 8 && x <= 9) return cRed;
        if (y >= 5 && y <= 6) return cRed;
        if (x >= 7 && x <= 10) return cWhite;
        if (y >= 4 && y <= 7) return cWhite;
        if ((x - y).abs() <= 1 || ((cols - 1 - x) - y).abs() <= 1) return cWhite;
        return cNavy;

      // 🇫🇷 Франция: вертикальные синий, белый, красный
      case 'FR':
      case 'FRA':
        if (x < 6) return cBlue;
        if (x < 12) return cWhite;
        return cRed;

      // 🇵🇱 Польша: белый верх, красный низ
      case 'PL':
      case 'POL':
        if (y < 6) return cWhite;
        return cRed;

      // 🇪🇪 Эстония: синий, черный, белый
      case 'EE':
      case 'EST':
        if (y < 4) return const Color(0xFF0072CE);
        if (y < 8) return cBlack;
        return cWhite;

      // 🇨🇭 Швейцария: красный фон, белый прямой крест
      case 'CH':
      case 'CHE':
        if (x >= 7 && x <= 10 && y >= 3 && y <= 8) return cWhite;
        if (x >= 5 && x <= 12 && y >= 4 && y <= 7) return cWhite;
        return cRed;

      // 🇸🇬 Сингапур: красный верх с полумесяцем, белый низ
      case 'SG':
      case 'SGP':
        if (y < 6) {
          if (x >= 3 && x <= 5 && y >= 2 && y <= 4) return cWhite;
          return cRed;
        }
        return cWhite;

      // 🇹🇷 Турция: красный фон, полумесяц и звезда
      case 'TR':
      case 'TUR':
        final isMoon = (x >= 5 && x <= 8 && y >= 3 && y <= 8) &&
            !(x >= 7 && y >= 4 && y <= 7);
        final isStar = (x == 11 && y >= 5 && y <= 6) ||
            (x == 10 && y == 5) ||
            (x == 12 && y == 5);
        if (isMoon || isStar) return cWhite;
        return cRed;

      // 🇯🇵 Япония: белый фон, красный диск солнца
      case 'JP':
      case 'JPN':
        final dx = x - 8.5;
        final dy = y - 5.5;
        if ((dx * dx + dy * dy * 1.5) <= 7.5) return cRed;
        return cWhite;

      // 🇨🇦 Канада: красные края, белый центр с кленовым листом
      case 'CA':
      case 'CAN':
        if (x < 4 || x >= 14) return cRed;
        final isLeaf = (x == 8 || x == 9) && (y >= 4 && y <= 8) ||
            (x >= 6 && x <= 11 && y == 6) ||
            (x == 7 || x == 10) && (y == 5 || y == 7);
        if (isLeaf) return cRed;
        return cWhite;

      // 🇺🇦 Украина: синий верх, желтый низ
      case 'UA':
      case 'UKR':
        if (y < 6) return cBlue;
        return cYellow;

      // 🇳🇴 Норвегия: красный фон, сине-белый скандинавский крест
      case 'NO':
      case 'NOR':
        if (x >= 5 && x <= 7 || y >= 4 && y <= 7) {
          if (x == 6 || y == 5 || y == 6) return cNavy;
          return cWhite;
        }
        return cRed;

      // 🇩🇰 Дания: красный фон, белый крест
      case 'DK':
      case 'DNK':
        if (x >= 5 && x <= 7 || y >= 5 && y <= 6) return cWhite;
        return cRed;

      // 🇦🇺 Австралия: синий фон, Union Jack в кантоне, звезды Южного Креста
      case 'AU':
      case 'AUS':
        if (x < 8 && y < 6) {
          if (x == 4 || y == 2 || y == 3) return cRed;
          if ((x - y).abs() <= 1 || ((7 - x) - y).abs() <= 1) return cWhite;
          return cNavy;
        }
        // Звезды Южного Креста и звезда Содружества
        if ((x == 13 && y == 2) ||
            (x == 15 && y == 5) ||
            (x == 11 && y == 5) ||
            (x == 13 && y == 9) ||
            (x == 14 && y == 7) ||
            (x == 4 && y == 9)) {
          return cWhite;
        }
        return cNavy;

      // 🇪🇺 Евросоюз / Белые списки (синий фон с золотыми звездами)
      case 'EU':
      case 'EUR':
        final dx = x - 8.5;
        final dy = y - 5.5;
        final distSq = dx * dx + dy * dy * 1.5;
        // Звезды по кругу
        if (distSq >= 9.0 && distSq <= 17.0 && ((x + y) % 2 == 0)) {
          return cYellow;
        }
        return cBlue;

      // ⚡ Авто-выбор / Оптимальный
      case 'AUTO':
        final isBolt = (x == 10 && y == 2) ||
            (x == 9 && y == 3) ||
            (x >= 8 && x <= 11 && y == 4) ||
            (x == 8 && y == 5) ||
            (x == 7 && y == 6) ||
            (x >= 6 && x <= 10 && y == 7) ||
            (x == 7 && y == 8) ||
            (x == 6 && y == 9);
        if (isBolt) return cYellow;
        return (x + y) % 2 == 0 ? cEnderDark : cEnderPurple;

      // Дефолт / Неизвестно: блок земли с травой из майна
      default:
        if (y < 4) return cGrassGreen;
        if (y == 4 && (x % 3 == 0)) return cGrassGreen;
        return cDirtBrown;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final baseColor = _getColor(x, y);

        // Микро-текстура шерсти Minecraft (шум волокон)
        // Детерминированная легкая вариация яркости для эффекта ткани
        final noise = ((x * 13 + y * 29) % 7);
        Color pixelColor = baseColor;
        if (noise == 0) {
          pixelColor = _adjustBrightness(baseColor, 0.08); // чуть светлее
        } else if (noise == 1) {
          pixelColor = _adjustBrightness(baseColor, -0.08); // чуть темнее
        }

        paint.color = pixelColor;
        canvas.drawRect(
          Rect.fromLTWH(
            x * cellW,
            y * cellH,
            cellW + 0.2, // микро-перекрытие против щелей субпикселей
            cellH + 0.2,
          ),
          paint,
        );
      }
    }

    // Верхняя световая фаска (1px 3D bevel)
    final bevelPaint = Paint()..style = PaintingStyle.fill;
    bevelPaint.color = Colors.white.withValues(alpha: 0.18);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cellH * 0.7), bevelPaint);

    // Нижняя теневая фаска (1px 3D shadow)
    bevelPaint.color = Colors.black.withValues(alpha: 0.25);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - (cellH * 0.7), size.width, cellH * 0.7),
      bevelPaint,
    );
  }

  Color _adjustBrightness(Color color, double amount) {
    final m = 1.0 + amount;
    return Color.from(
      alpha: color.a,
      red: (color.r * m).clamp(0.0, 1.0),
      green: (color.g * m).clamp(0.0, 1.0),
      blue: (color.b * m).clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldRepaint(covariant MinecraftFlagPainter oldDelegate) {
    return oldDelegate.countryCode != countryCode;
  }
}
