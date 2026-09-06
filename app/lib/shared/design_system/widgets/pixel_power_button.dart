import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/vpn/vpn_engine.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 3D Гиперкуб Активации Портала (Dual Rotating Hypercube Power Button).
///
/// Вдохновлён концептом 3D-куба dexter-st с Uiverse.io:
/// - Внешний куб: полупрозрачный парящий кристалл Края (End Crystal) с мягким 3D-наклоном.
/// - Внутренний куб: блок Рамки портала в Край (End Portal Frame block) с аутентичной текстурой,
///   вращающийся в противоположную сторону (гироскопический эффект гиперкуба).
/// - В гнезде портала при подключении плавно материализуется и зажигается «Око Края» (Eye of Ender).
/// - Статусы: «Нажмите для подключения» (idle) / «Нажмите для выключения» (connected).
class PixelPowerButton extends StatefulWidget {
  const PixelPowerButton({
    super.key,
    required this.status,
    required this.onTap,
  });

  final VpnStatus status;
  final VoidCallback onTap;

  @override
  State<PixelPowerButton> createState() => _PixelPowerButtonState();
}

class _PixelPowerButtonState extends State<PixelPowerButton>
    with TickerProviderStateMixin {
  bool _pressed = false;

  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final AnimationController _eyeController;

  @override
  void initState() {
    super.initState();

    // Непрерывное гипнотическое вращение 3D куба
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();

    // Мягкое дыхание неонового свечения
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Анимация проявления Ока Края (0.0 = пустое гнездо, 1.0 = Око полностью в сокете)
    final initialEyeValue = widget.status == VpnStatus.connected ? 1.0 : 0.0;
    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      value: initialEyeValue,
    );
  }

  @override
  void didUpdateWidget(PixelPowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      if (_isConnected) {
        _eyeController.animateTo(1.0, curve: Curves.easeOutBack);
      } else if (_isConnecting) {
        _eyeController.animateTo(0.70, curve: Curves.easeInOut);
      } else {
        _eyeController.animateTo(0.0, curve: Curves.easeInCubic);
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _eyeController.dispose();
    super.dispose();
  }

  bool get _isConnected => widget.status == VpnStatus.connected;
  bool get _isConnecting =>
      widget.status == VpnStatus.connecting ||
      widget.status == VpnStatus.preparing ||
      widget.status == VpnStatus.reconnecting;
  bool get _isError => widget.status == VpnStatus.error;

  Color get _glowColor {
    if (_isConnected) return AppColors.mcGrass;
    if (_isConnecting) return AppColors.mcGold;
    if (_isError) return AppColors.mcRedstone;
    return AppColors.mcEnder;
  }

  String get _actionLabel {
    if (_isConnected) return 'Нажмите для выключения';
    if (_isConnecting) return 'Подключение...';
    if (_isError) return 'Нажмите для повтора';
    return 'Нажмите для подключения';
  }

  Color get _actionTextColor {
    if (_isConnected) return const Color(0xFF34D399);
    if (_isConnecting) return const Color(0xFFFBBF24);
    if (_isError) return const Color(0xFFF87171);
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    const double sceneSize = 138.0;
    const double outerCubeSize = 112.0;
    const double innerCubeSize = 56.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3D Scene Viewport
            SizedBox(
              width: sceneSize,
              height: sceneSize,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _rotationController,
                  _pulseController,
                  _eyeController,
                ]),
                builder: (context, child) {
                  final rotProgress = _rotationController.value;
                  final pulse = _pulseController.value;
                  final eyeProgress = _eyeController.value;

                  // Угол вращения (точное зацикливание без рывков на границе повтора)
                  final outerAngle = rotProgress * 2 * math.pi;
                  final innerAngle = -outerAngle; // плавное обратное вращение (период строго 2π)

                  // Фиксированный наклон по X (изометрия сверху) + лёгкое парение
                  final tiltX = (-14.0 + (math.sin(outerAngle * 2) * 1.5)) *
                      math.pi /
                      180.0;

                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Внешний рассеянный неон (Ambient Aura)
                      Container(
                        width: sceneSize - 10,
                        height: sceneSize - 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _glowColor.withValues(
                                alpha: _isConnected
                                    ? 0.35 + (pulse * 0.20)
                                    : _isConnecting
                                        ? 0.30 + (pulse * 0.25)
                                        : 0.14,
                              ),
                              blurRadius: _isConnected ? 34 + (pulse * 10) : 22,
                              spreadRadius: _isConnected ? 4 : 0,
                            ),
                          ],
                        ),
                      ),

                      // 2. Фоновые грани внешнего куба (обратная сторона стекла)
                      ..._buildOuterCubeFaces(
                        size: outerCubeSize,
                        rotY: outerAngle,
                        tiltX: tiltX,
                        frontFacing: false,
                        glowColor: _glowColor,
                        pulse: pulse,
                      ),

                      // 3. Внутренний блок «Рамка портала в Край» + Око Края
                      ..._buildInnerPortalFrameBlock(
                        size: innerCubeSize,
                        rotY: innerAngle,
                        tiltX: tiltX,
                        eyeProgress: eyeProgress,
                        pulse: pulse,
                        glowColor: _glowColor,
                      ),

                      // 4. Передние грани внешнего куба (лицевое стекло с бликами)
                      ..._buildOuterCubeFaces(
                        size: outerCubeSize,
                        rotY: outerAngle,
                        tiltX: tiltX,
                        frontFacing: true,
                        glowColor: _glowColor,
                        pulse: pulse,
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Текстовая подсказка действия
            AnimatedOpacity(
              opacity: _isConnecting ? 0.70 + (_pulseController.value * 0.30) : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _actionLabel,
                style: AppTypography.label(_actionTextColor).copyWith(
                  fontSize: 13,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                  shadows: _isConnected
                      ? [
                          BoxShadow(
                            color: _actionTextColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Генерация граней внешнего кристаллического куба
  List<Widget> _buildOuterCubeFaces({
    required double size,
    required double rotY,
    required double tiltX,
    required bool frontFacing,
    required Color glowColor,
    required double pulse,
  }) {
    final faces = _generateCubeFaces(
      size: size,
      rotY: rotY,
      tiltX: tiltX,
    );

    final filtered = faces.where((f) => f.isFrontFacing == frontFacing).toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));

    return filtered.map((face) {
      return Transform(
        alignment: Alignment.center,
        transform: face.transform,
        child: SizedBox(
          width: size,
          height: size,
          child: _OuterCrystalFaceWidget(
            isFrontFacing: frontFacing,
            glowColor: glowColor,
            pulse: pulse,
            isConnected: _isConnected,
            isConnecting: _isConnecting,
          ),
        ),
      );
    }).toList();
  }

  /// Генерация граней внутреннего блока «Рамка портала в Край»
  List<Widget> _buildInnerPortalFrameBlock({
    required double size,
    required double rotY,
    required double tiltX,
    required double eyeProgress,
    required double pulse,
    required Color glowColor,
  }) {
    final faces = _generateCubeFaces(
      size: size,
      rotY: rotY,
      tiltX: tiltX,
    );

    // Для непрозрачного блока рисуем только лицевые грани (Backface Culling)
    // и сортируем их от дальних к ближним
    final visibleFaces = faces.where((f) => f.isFrontFacing).toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));

    return visibleFaces.map((face) {
      return Transform(
        alignment: Alignment.center,
        transform: face.transform,
        child: SizedBox(
          width: size,
          height: size,
          child: _PortalFrameFaceWidget(
            faceType: face.type,
            eyeProgress: eyeProgress,
            pulse: pulse,
            glowColor: glowColor,
            isConnected: _isConnected,
            isConnecting: _isConnecting,
          ),
        ),
      );
    }).toList();
  }

  /// Математика 3D проекции 6 граней куба
  List<_Face3D> _generateCubeFaces({
    required double size,
    required double rotY,
    required double tiltX,
  }) {
    const double perspective = 0.0014;
    final h = size / 2;

    const faceConfigs = [
      // Front
      _FaceConfig(
        type: _CubeFaceType.front,
        yaw: 0.0,
        pitch: 0.0,
        nx: 0.0,
        ny: 0.0,
        nz: 1.0,
        cx: 0.0,
        cy: 0.0,
        cz: 1.0,
      ),
      // Back
      _FaceConfig(
        type: _CubeFaceType.back,
        yaw: math.pi,
        pitch: 0.0,
        nx: 0.0,
        ny: 0.0,
        nz: -1.0,
        cx: 0.0,
        cy: 0.0,
        cz: -1.0,
      ),
      // Right
      _FaceConfig(
        type: _CubeFaceType.right,
        yaw: math.pi / 2,
        pitch: 0.0,
        nx: 1.0,
        ny: 0.0,
        nz: 0.0,
        cx: 1.0,
        cy: 0.0,
        cz: 0.0,
      ),
      // Left
      _FaceConfig(
        type: _CubeFaceType.left,
        yaw: -math.pi / 2,
        pitch: 0.0,
        nx: -1.0,
        ny: 0.0,
        nz: 0.0,
        cx: -1.0,
        cy: 0.0,
        cz: 0.0,
      ),
      // Top
      _FaceConfig(
        type: _CubeFaceType.top,
        yaw: 0.0,
        pitch: math.pi / 2,
        nx: 0.0,
        ny: -1.0,
        nz: 0.0,
        cx: 0.0,
        cy: -1.0,
        cz: 0.0,
      ),
      // Bottom
      _FaceConfig(
        type: _CubeFaceType.bottom,
        yaw: 0.0,
        pitch: -math.pi / 2,
        nx: 0.0,
        ny: 1.0,
        nz: 0.0,
        cx: 0.0,
        cy: 1.0,
        cz: 0.0,
      ),
    ];

    final cosT = math.cos(rotY);
    final sinT = math.sin(rotY);
    final cosP = math.cos(tiltX);
    final sinP = math.sin(tiltX);

    final result = <_Face3D>[];

    for (final cfg in faceConfigs) {
      // 1. Поворот нормали: сначала вокруг Y, затем вокруг X
      final nz1 = -cfg.nx * sinT + cfg.nz * cosT;
      final nz2 = cfg.ny * sinP + nz1 * cosP;

      // nz2 > 0 означает, что грань направлена в сторону зрителя (+Z)
      final isFrontFacing = nz2 > 0.001;

      // 2. Поворот центра грани для расчета глубины (Z-сортировка)
      final cz0 = cfg.cz * h;
      final cz1 = -cfg.cx * h * sinT + cz0 * cosT;
      final cz2 = cfg.cy * h * sinP + cz1 * cosP;

      // 3. Матрица трансформации для Flutter
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, perspective)
        ..rotateX(tiltX)
        ..rotateY(rotY);

      if (cfg.yaw != 0) matrix.rotateY(cfg.yaw);
      if (cfg.pitch != 0) matrix.rotateX(cfg.pitch);
      // ignore: deprecated_member_use
      matrix.translate(0.0, 0.0, h);

      result.add(
        _Face3D(
          type: cfg.type,
          depth: cz2,
          isFrontFacing: isFrontFacing,
          transform: matrix,
        ),
      );
    }

    return result;
  }
}

enum _CubeFaceType { front, back, right, left, top, bottom }

class _FaceConfig {
  const _FaceConfig({
    required this.type,
    required this.yaw,
    required this.pitch,
    required this.nx,
    required this.ny,
    required this.nz,
    required this.cx,
    required this.cy,
    required this.cz,
  });

  final _CubeFaceType type;
  final double yaw;
  final double pitch;
  final double nx;
  final double ny;
  final double nz;
  final double cx;
  final double cy;
  final double cz;
}

class _Face3D {
  const _Face3D({
    required this.type,
    required this.depth,
    required this.isFrontFacing,
    required this.transform,
  });

  final _CubeFaceType type;
  final double depth;
  final bool isFrontFacing;
  final Matrix4 transform;
}

/// Полупрозрачная грань внешнего кристалла Края (End Crystal Glass Face)
class _OuterCrystalFaceWidget extends StatelessWidget {
  const _OuterCrystalFaceWidget({
    required this.isFrontFacing,
    required this.glowColor,
    required this.pulse,
    required this.isConnected,
    required this.isConnecting,
  });

  final bool isFrontFacing;
  final Color glowColor;
  final double pulse;
  final bool isConnected;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    final edgeOpacity = isFrontFacing
        ? (isConnected ? 0.85 : 0.60)
        : (isConnected ? 0.35 : 0.20);

    final bgAlpha = isFrontFacing
        ? (isConnected ? 0.22 : 0.12)
        : (isConnected ? 0.08 : 0.04);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: glowColor.withValues(alpha: edgeOpacity),
          width: isFrontFacing ? 1.4 : 0.8,
        ),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.82,
          colors: [
            Colors.transparent,
            glowColor.withValues(alpha: bgAlpha * 0.4),
            glowColor.withValues(alpha: bgAlpha),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: isFrontFacing
            ? [
                BoxShadow(
                  color: glowColor.withValues(
                    alpha: isConnected ? 0.35 + (pulse * 0.15) : 0.15,
                  ),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: isFrontFacing
          ? CustomPaint(
              painter: _CrystalGlintPainter(
                color: glowColor,
                highlight: isConnected || isConnecting,
              ),
            )
          : null,
    );
  }
}

/// Кристаллический диагональный блик света на лицевых гранях
class _CrystalGlintPainter extends CustomPainter {
  const _CrystalGlintPainter({
    required this.color,
    required this.highlight,
  });

  final Color color;
  final bool highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: highlight ? 0.35 : 0.15),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.55, 0)
      ..lineTo(0, size.height * 0.55)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CrystalGlintPainter oldDelegate) =>
      oldDelegate.highlight != highlight;
}

/// Аутентичная грань блока «Рамка портала в Край» (End Portal Frame Block)
class _PortalFrameFaceWidget extends StatelessWidget {
  const _PortalFrameFaceWidget({
    required this.faceType,
    required this.eyeProgress,
    required this.pulse,
    required this.glowColor,
    required this.isConnected,
    required this.isConnecting,
  });

  final _CubeFaceType faceType;
  final double eyeProgress;
  final double pulse;
  final Color glowColor;
  final bool isConnected;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: CustomPaint(
        painter: _PortalFramePainter(
          faceType: faceType,
          eyeProgress: eyeProgress,
          pulse: pulse,
          glowColor: glowColor,
          isConnected: isConnected,
          isConnecting: isConnecting,
        ),
      ),
    );
  }
}

/// Художественный отрисовщик текстур Minecraft блока Рамки портала в Край
class _PortalFramePainter extends CustomPainter {
  const _PortalFramePainter({
    required this.faceType,
    required this.eyeProgress,
    required this.pulse,
    required this.glowColor,
    required this.isConnected,
    required this.isConnecting,
  });

  final _CubeFaceType faceType;
  final double eyeProgress;
  final double pulse;
  final Color glowColor;
  final bool isConnected;
  final bool isConnecting;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (faceType) {
      case _CubeFaceType.top:
        _paintTopFace(canvas, w, h);
        break;
      case _CubeFaceType.bottom:
        _paintEndStone(canvas, Rect.fromLTWH(0, 0, w, h));
        break;
      case _CubeFaceType.front:
      case _CubeFaceType.back:
      case _CubeFaceType.left:
      case _CubeFaceType.right:
        _paintSideFace(canvas, w, h);
        break;
    }
  }

  /// Отрисовка верхней грани (End Portal Frame Top Socket)
  void _paintTopFace(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h);

    // 1. Базовый бордюр из камня Края (End Stone border)
    _paintEndStone(canvas, rect);

    // 2. Внутренняя оправа гнезда портала (темно-изумрудная рамка)
    final socketInset = w * 0.14;
    final socketRect = Rect.fromLTRB(
      socketInset,
      socketInset,
      w - socketInset,
      h - socketInset,
    );

    final frameRimPaint = Paint()
      ..color = const Color(0xFF163226)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(socketRect, const Radius.circular(3)),
      frameRimPaint,
    );

    // 3. Золотые угловые заклёпки (Brass corner studs)
    final studPaint = Paint()..color = const Color(0xFFD4AF37);
    final studDarkPaint = Paint()..color = const Color(0xFF8C6D1F);
    final studSize = w * 0.08;

    final corners = [
      Offset(socketInset + 2, socketInset + 2),
      Offset(w - socketInset - studSize - 2, socketInset + 2),
      Offset(socketInset + 2, h - socketInset - studSize - 2),
      Offset(w - socketInset - studSize - 2, h - socketInset - studSize - 2),
    ];

    for (final c in corners) {
      canvas.drawRect(Rect.fromLTWH(c.dx, c.dy, studSize, studSize), studPaint);
      canvas.drawRect(
        Rect.fromLTWH(c.dx + 1, c.dy + 1, studSize - 2, studSize - 2),
        studDarkPaint,
      );
    }

    // 4. Глубокий кратер гнезда (Recessed Void Socket)
    final wellInset = w * 0.22;
    final wellRect = Rect.fromLTRB(
      wellInset,
      wellInset,
      w - wellInset,
      h - wellInset,
    );

    final wellPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF030705),
          Color(0xFF0A1C14),
        ],
      ).createShader(wellRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(wellRect, const Radius.circular(4)),
      wellPaint,
    );

    // 5. Око Края (Eye of Ender)
    final center = Offset(w / 2, h / 2);
    final baseRadius = w * 0.24;

    if (eyeProgress > 0.01) {
      _paintEyeOfEnder(canvas, center, baseRadius);
    } else {
      // Когда сокет пустой — тонкое загадочное мерцание пустоты
      final dimWellGlow = Paint()
        ..color = const Color(0xFF0D3323).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(center, baseRadius * 0.6, dimWellGlow);
    }
  }

  /// Отрисовка боковой грани (Side Face: Mossy Rim + End Stone Base)
  void _paintSideFace(Canvas canvas, double w, double h) {
    // Верхняя часть (28%): тёмно-изумрудная пластина рамки портала
    final topBandHeight = h * 0.28;
    final topBandRect = Rect.fromLTWH(0, 0, w, topBandHeight);

    final topBandPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E3F30),
          Color(0xFF163226),
          Color(0xFF0C1F16),
        ],
      ).createShader(topBandRect);
    canvas.drawRect(topBandRect, topBandPaint);

    // Золотой орнаментальный кант по низу пластины
    final trimPaint = Paint()..color = const Color(0xFF9E822B);
    canvas.drawRect(Rect.fromLTWH(0, topBandHeight - 2, w, 2), trimPaint);

    // Тень под кантом
    final shadowPaint = Paint()..color = const Color(0xFF070F0B);
    canvas.drawRect(Rect.fromLTWH(0, topBandHeight, w, 2), shadowPaint);

    // Нижняя часть (72%): аутентичный камень Края (End Stone)
    final endStoneRect =
        Rect.fromLTWH(0, topBandHeight + 2, w, h - topBandHeight - 2);
    _paintEndStone(canvas, endStoneRect);
  }

  /// Текстурирование камня Края (End Stone Procedural Texture)
  void _paintEndStone(Canvas canvas, Rect rect) {
    // Базовый цвет камня Края (песочно-оливковый светлый оттенок)
    final basePaint = Paint()..color = const Color(0xFFD6D7A8);
    canvas.drawRect(rect, basePaint);

    // Пиксельные вкрапления минералов камня Края
    final p1 = Paint()..color = const Color(0xFFBCBE8E);
    final p2 = Paint()..color = const Color(0xFFA2A574);
    final p3 = Paint()..color = const Color(0xFF86895A);

    final step = rect.width / 8.0;
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        final seed = (i * 13 + j * 7 + (rect.top * 0.1).toInt()) % 11;
        final pixelRect = Rect.fromLTWH(
          rect.left + i * step,
          rect.top + j * step,
          step,
          step,
        );

        if (seed == 1 || seed == 5) {
          canvas.drawRect(pixelRect, p1);
        } else if (seed == 2 || seed == 8) {
          canvas.drawRect(pixelRect, p2);
        } else if (seed == 3) {
          canvas.drawRect(pixelRect, p3);
        }
      }
    }
  }

  /// Живописная прорисовка легендарного «Ока Края» (Eye of Ender)
  void _paintEyeOfEnder(Canvas canvas, Offset center, double baseRadius) {
    final scale = 0.50 + (0.50 * eyeProgress);
    final radius = baseRadius * scale;
    final alpha = eyeProgress.clamp(0.0, 1.0);

    // 1. Внешняя аура энергии Края (Cosmic Emerald Halo)
    if (isConnected || isConnecting) {
      final haloPaint = Paint()
        ..color = (isConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
            .withValues(alpha: (0.35 + (pulse * 0.30)) * alpha)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          isConnected ? 12.0 : 8.0,
        );
      canvas.drawCircle(center, radius * 1.5, haloPaint);
    }

    // 2. 3D сфера Ока Края со светотенью
    final eyePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.90,
        colors: isConnected
            ? [
                const Color(0xFF86EFAC).withValues(alpha: alpha),
                const Color(0xFF10B981).withValues(alpha: alpha),
                const Color(0xFF047857).withValues(alpha: alpha),
                const Color(0xFF064E3B).withValues(alpha: alpha),
                const Color(0xFF02231A).withValues(alpha: alpha),
              ]
            : isConnecting
                ? [
                    const Color(0xFFFDE68A).withValues(alpha: alpha),
                    const Color(0xFFF59E0B).withValues(alpha: alpha),
                    const Color(0xFF7C3AED).withValues(alpha: alpha),
                    const Color(0xFF4C1D95).withValues(alpha: alpha),
                    const Color(0xFF1E0A3C).withValues(alpha: alpha),
                  ]
                : [
                    const Color(0xFF5EEAD4).withValues(alpha: alpha),
                    const Color(0xFF0D9488).withValues(alpha: alpha),
                    const Color(0xFF5B21B6).withValues(alpha: alpha),
                    const Color(0xFF1F0E38).withValues(alpha: alpha),
                    const Color(0xFF090312).withValues(alpha: alpha),
                  ],
        stops: const [0.0, 0.35, 0.65, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, eyePaint);

    // 3. Зрачок Бездны (Void Slit Pupil)
    final pupilW = radius * 0.34;
    final pupilH = radius * 0.72;

    final pupilPath = Path()
      ..moveTo(center.dx, center.dy - pupilH)
      ..quadraticBezierTo(
        center.dx + pupilW,
        center.dy,
        center.dx,
        center.dy + pupilH,
      )
      ..quadraticBezierTo(
        center.dx - pupilW,
        center.dy,
        center.dx,
        center.dy - pupilH,
      )
      ..close();

    // Огненное свечение вокруг зрачка при подключении
    if (isConnected || isConnecting) {
      final pupilGlowPaint = Paint()
        ..color = (isConnected ? const Color(0xFF34D399) : const Color(0xFFFBBF24))
            .withValues(alpha: 0.6 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(pupilPath, pupilGlowPaint);
    }

    final pupilPaint = Paint()
      ..color = const Color(0xFF040608).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    canvas.drawPath(pupilPath, pupilPaint);

    // 4. Пиксельные блики света на поверхности Ока
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: (isConnected ? 0.95 : 0.70) * alpha);

    final glintSize1 = radius * 0.18;
    final glintSize2 = radius * 0.10;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.22, center.dy - radius * 0.24),
        width: glintSize1,
        height: glintSize1,
      ),
      glintPaint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.10, center.dy - radius * 0.10),
        width: glintSize2,
        height: glintSize2,
      ),
      glintPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PortalFramePainter oldDelegate) =>
      oldDelegate.faceType != faceType ||
      oldDelegate.eyeProgress != eyeProgress ||
      oldDelegate.pulse != pulse ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.isConnected != isConnected ||
      oldDelegate.isConnecting != isConnecting;
}
