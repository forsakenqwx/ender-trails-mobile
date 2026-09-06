import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Верхняя панель в стиле iOS (Translucent Glass Navigation Bar).
class PixelAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PixelAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.leading,
    this.actions = const <Widget>[],
  });

  final String title;
  final Widget? titleWidget;
  final Widget? leading;

  /// Уже обёрнутые в [PixelIconButton] или [SizedBox] виджеты.
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xD908080C),
            border: Border(
              bottom: BorderSide(color: Color(0x14FFFFFF), width: 0.8),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            toolbarHeight: 56,
            leading: leading,
            titleSpacing: leading == null ? 16 : 0,
            title: titleWidget ??
                Text(
                  title,
                  style: AppTypography.label(AppColors.mcText).copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            actions: [
              ...actions,
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Круглая стеклянная кнопка в верхней панели (iOS Circular Glass Button).
class PixelIconButton extends StatelessWidget {
  const PixelIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final String icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x18FFFFFF),
            border: Border.all(color: const Color(0x22FFFFFF), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
