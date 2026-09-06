import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/app_colors.dart';
import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../../shared/design_system/widgets/block_button.dart';
import '../../../../shared/design_system/widgets/enchanting_matrix_background.dart';
import '../../../../shared/design_system/widgets/stone_panel.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _slides = const [
    (
      icon: Icons.shield_rounded,
      title: 'ENDER TRAILS',
      subtitle: 'Твой персональный портал в свободный интернет без ограничений и блокировок.',
    ),
    (
      icon: Icons.bolt_rounded,
      title: 'VLESS REALITY',
      subtitle: 'Трафик полностью маскируется под легитимный HTTPS. Максимальная скорость и надёжность.',
    ),
    (
      icon: Icons.smart_toy_rounded,
      title: 'ВХОД ЧЕРЕЗ БОТА',
      subtitle: 'Никаких логинов и паролей. Достаточно нажать одну кнопку в нашем Telegram-боте.',
    ),
  ];

  Future<void> _finish() async {
    final storage = ref.read(secureStorageProvider);
    await storage.setOnboardingSeen(true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Живая матрица рун Стола Зачарования Minecraft (SGA Matrix)
          const EnchantingMatrixBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Индикаторы страниц
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (idx) {
                      final active = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.mcEnder : const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),

                  // Слайдер
                  SizedBox(
                    height: 320,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (idx) => setState(() => _currentPage = idx),
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              slide.icon,
                              size: 64,
                              color: AppColors.mcEnder,
                              shadows: [
                                BoxShadow(
                                  color: AppColors.mcEnder.withValues(alpha: 0.5),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              slide.title,
                              style: AppTypography.headline(AppColors.mcEnder),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            StonePanel(
                              child: Text(
                                slide.subtitle,
                                style: AppTypography.label(AppColors.mcText),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const Spacer(),

                  // Кнопки управления
                  if (_currentPage < _slides.length - 1)
                    BlockButton(
                      label: 'ДАЛЕЕ',
                      icon: const Icon(Icons.arrow_forward_rounded),
                      variant: BlockButtonVariant.stone,
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      },
                    )
                  else
                    BlockButton(
                      label: 'ВОЙТИ В ЭНД',
                      icon: const Icon(Icons.rocket_launch_rounded),
                      variant: BlockButtonVariant.grass,
                      onTap: _finish,
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
