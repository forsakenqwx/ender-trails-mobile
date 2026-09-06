import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/announcements/domain/entities/remote_banner.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Интерактивная онлайн-плашка анонсов и новостей между карточкой трафика и меню.
class RemoteAnnouncementCard extends StatefulWidget {
  const RemoteAnnouncementCard({
    super.key,
    required this.banner,
    required this.onClose,
  });

  final RemoteBanner banner;
  final VoidCallback onClose;

  @override
  State<RemoteAnnouncementCard> createState() => _RemoteAnnouncementCardState();
}

class _RemoteAnnouncementCardState extends State<RemoteAnnouncementCard> {
  bool _closing = false;

  Color get _accentColor {
    switch (widget.banner.type) {
      case 'promo':
        return const Color(0xFF00E676);
      case 'warning':
        return const Color(0xFFFFB300);
      case 'info':
      default:
        return const Color(0xFF9D4EDD);
    }
  }

  IconData get _icon {
    switch (widget.banner.type) {
      case 'promo':
        return Icons.auto_awesome_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'info':
      default:
        return Icons.campaign_rounded;
    }
  }

  Future<void> _handleTap() async {
    final urlStr = widget.banner.actionUrl;
    if (urlStr == null || urlStr.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    final uri = Uri.tryParse(urlStr.trim());
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  void _handleClose() {
    HapticFeedback.selectionClick();
    setState(() => _closing = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;

    return AnimatedOpacity(
      opacity: _closing ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: _closing
            ? const SizedBox(width: double.infinity, height: 0)
            : Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.banner.actionUrl != null ? _handleTap : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: const Color(0x2212121A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                          const BoxShadow(
                            color: Color(0x80000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // Иконка типа анонса
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _icon,
                                color: accent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Текстовый блок
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.banner.title.toUpperCase(),
                                        style: AppTypography.caption(accent).copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          letterSpacing: 1.0,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.banner.actionUrl != null) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_outward_rounded,
                                          size: 11,
                                          color: accent.withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.banner.text,
                                    style: AppTypography.label(AppColors.mcText).copyWith(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Кнопка закрытия
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _handleClose,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
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
