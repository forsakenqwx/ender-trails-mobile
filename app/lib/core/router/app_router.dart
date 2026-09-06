import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/connection/presentation/screens/main_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/referral/presentation/screens/referral_screen.dart';
import '../../features/servers/presentation/screens/servers_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/logs_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/split_tunneling_screen.dart';
import '../../shared/design_system/showcase/design_system_showcase_screen.dart';
import '../../shared/design_system/theme/app_colors.dart';
import '../../shared/design_system/widgets/minecraft_bottom_menu.dart';

/// Маршрутизация приложения (go_router) с постоянным нижним меню на ключевых экранах.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          backgroundColor: AppColors.mcVoid,
          extendBody: true,
          body: _FadingShellBody(
            navigationShell: navigationShell,
            currentIndex: navigationShell.currentIndex,
          ),
          bottomNavigationBar: MinecraftBottomMenu(
            currentIndex: navigationShell.currentIndex,
            onTabSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'main',
              builder: (context, state) => const MainScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/servers',
              name: 'servers',
              builder: (context, state) => const ServersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/referral',
              name: 'referral',
              builder: (context, state) => const ReferralScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/logs',
      name: 'logs',
      builder: (context, state) => const LogsScreen(),
    ),
    GoRoute(
      path: '/showcase',
      name: 'showcase',
      builder: (context, state) => const DesignSystemShowcaseScreen(),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/settings/split-tunneling',
      name: 'split-tunneling',
      builder: (context, state) => const SplitTunnelingScreen(),
    ),
  ],
);

class _FadingShellBody extends StatefulWidget {
  const _FadingShellBody({
    required this.navigationShell,
    required this.currentIndex,
  });

  final StatefulNavigationShell navigationShell;
  final int currentIndex;

  @override
  State<_FadingShellBody> createState() => _FadingShellBodyState();
}

class _FadingShellBodyState extends State<_FadingShellBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _opacity = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_FadingShellBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.navigationShell,
    );
  }
}
