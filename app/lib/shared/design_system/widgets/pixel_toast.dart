import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Вариант уведомления (тоста).
enum PixelToastVariant { info, success, error }

/// Премиальное плавающее уведомление в стиле Dynamic Island (Apple).
class PixelToast extends StatelessWidget {
  const PixelToast({
    super.key,
    required this.message,
    this.variant = PixelToastVariant.info,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final PixelToastVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;

  static void show(
    BuildContext context, {
    required String message,
    PixelToastVariant variant = PixelToastVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _PixelToastEntry(
        message: message,
        variant: variant,
        actionLabel: actionLabel,
        onAction: () {
          entry.remove();
          onAction?.call();
        },
        duration: duration,
        onDismissed: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (variant) {
      PixelToastVariant.info => AppColors.mcDiamond,
      PixelToastVariant.success => AppColors.mcGrass,
      PixelToastVariant.error => AppColors.mcRedstone,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xEB161722),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: dotColor.withOpacity(0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: dotColor.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Светодиодный кругляш статуса
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withOpacity(0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message,
                  style: AppTypography.label(Colors.white).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x24FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      actionLabel!,
                      style: AppTypography.caption(AppColors.mcGold).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PixelToastEntry extends StatefulWidget {
  const _PixelToastEntry({
    required this.message,
    required this.variant,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final PixelToastVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_PixelToastEntry> createState() => _PixelToastEntryState();
}

class _PixelToastEntryState extends State<_PixelToastEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    if (!mounted) return;
    await _anim.forward();
    await Future<void>.delayed(widget.duration);
    if (!mounted) return;
    await _anim.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 36,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Center(
              child: PixelToast(
                message: widget.message,
                variant: widget.variant,
                actionLabel: widget.actionLabel,
                onAction: widget.onAction,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
