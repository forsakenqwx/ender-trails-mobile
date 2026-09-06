import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Модель элемента нижнего меню.
class MinecraftMenuItem {
  const MinecraftMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
  });

  final String id;
  final String label;
  final IconData icon;
  final String route;
}

/// Парящее нижнее меню в стиле Minecraft (Glassmorphic Hotbar Pill Menu).
///
/// Вдохновлено концептом mymiamo с Uiverse.io и стилизовано под эстетику
/// блоков и обсидианового стекла Minecraft:
/// - Парящая капсула (Pill Dock) с размытием заднего плана (`BackdropFilter`).
/// - 3D-фаска блоков (верхний световой блик, нижний теневой срез).
/// - Активный таб в стиле слота инвентаря с изумрудным свечением опыта.
/// - Пружинный тактильный отклик при нажатии.
class MinecraftBottomMenu extends StatelessWidget {
  const MinecraftBottomMenu({
    super.key,
    this.currentRoute = '/',
    this.currentIndex,
    this.onTabSelected,
  });

  final String currentRoute;
  final int? currentIndex;
  final ValueChanged<int>? onTabSelected;

  static const List<MinecraftMenuItem> items = [
    MinecraftMenuItem(
      id: 'portal',
      label: 'ПОРТАЛ',
      icon: Icons.shield_rounded,
      route: '/',
    ),
    MinecraftMenuItem(
      id: 'servers',
      label: 'СЕРВЕРЫ',
      icon: Icons.public_rounded,
      route: '/servers',
    ),
    MinecraftMenuItem(
      id: 'referral',
      label: 'БОНУСЫ',
      icon: Icons.card_giftcard_rounded,
      route: '/referral',
    ),
    MinecraftMenuItem(
      id: 'settings',
      label: 'НАСТРОЙКИ',
      icon: Icons.tune_rounded,
      route: '/settings',
    ),
  ];

  int _getActiveIndex() {
    if (currentIndex != null) return currentIndex!;
    for (int i = 0; i < items.length; i++) {
      if (items[i].route == currentRoute) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _getActiveIndex();

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xDD0D0E16), // глубокое обсидиановое стекло
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: const Color(0x33FFFFFF), // верхний стеклянный кант
                      width: 1.2,
                    ),
                    boxShadow: [
                      // Объемная тень парения меню над фоном
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.60),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      // Деликатный неоновый ореол Края
                      BoxShadow(
                        color: AppColors.mcEnder.withValues(alpha: 0.12),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _MinecraftBevelPainter(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final tabWidth = totalWidth / items.length;

                        return Stack(
                          children: [
                            // 1. Скользящая тёмная 3D-капсула активного таба (Marcelodolza Glass Pill)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              left: activeIndex * tabWidth,
                              top: 0,
                              bottom: 0,
                              width: tabWidth,
                              child: const _SlidingActiveIndicator(),
                            ),

                            // 2. Интерактивные вкладки поверх скользящей капсулы
                            Row(
                              children: List.generate(items.length, (index) {
                                final item = items[index];
                                final isActive = activeIndex == index;

                                return Expanded(
                                  child: _MinecraftMenuTab(
                                    item: item,
                                    isActive: isActive,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      if (onTabSelected != null) {
                                        onTabSelected!(index);
                                      } else if (currentRoute != item.route) {
                                        context.go(item.route);
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Скользящая стеклянная 3D-капсула активного таба
class _SlidingActiveIndicator extends StatelessWidget {
  const _SlidingActiveIndicator();

  @override
  Widget build(BuildContext context) {
    const radius = 24.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: const Color(0xFF0A0A0E),
        border: Border.all(
          color: const Color(0x38FFFFFF),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.60),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: -1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // Зеркальный блик линзы сверху (Marcelodolza style)
            Positioned(
              top: 2,
              left: 6,
              right: 6,
              height: 10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Мягкий световой срез снизу
            Positioned(
              bottom: 2,
              left: 8,
              right: 8,
              height: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Интерактивный слот таба с пружинной анимацией
class _MinecraftMenuTab extends StatefulWidget {
  const _MinecraftMenuTab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final MinecraftMenuItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_MinecraftMenuTab> createState() => _MinecraftMenuTabState();
}

class _MinecraftMenuTabState extends State<_MinecraftMenuTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final color = active ? const Color(0xFFFFFFFF) : AppColors.mcTextDim;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.item.icon,
                  size: 20,
                  color: color,
                  shadows: active
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: AppTypography.label(color).copyWith(
                  fontSize: 10,
                  letterSpacing: 0.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  shadows: active
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Отрисовка внутренней 3D-фаски в стиле блоков Minecraft (свет сверху, тень снизу)
class _MinecraftBevelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Верхний тонкий световой блик (Top Inner Highlight)
    final topHighlight = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0x35FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0.05, 0.5, 0.95],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(
      const Offset(24, 1.0),
      Offset(size.width - 24, 1.0),
      topHighlight,
    );

    // Нижняя обсидиановая тень (Bottom Bevel Shadow)
    final bottomShadow = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x00000000),
          Color(0x60000000),
          Color(0x00000000),
        ],
        stops: [0.05, 0.5, 0.95],
      ).createShader(Rect.fromLTWH(0, size.height - 2, size.width, 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawLine(
      Offset(24, size.height - 1.0),
      Offset(size.width - 24, size.height - 1.0),
      bottomShadow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
