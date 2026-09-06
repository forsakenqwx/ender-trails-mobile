import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/telegram_launcher.dart';
import '../../../../shared/design_system/theme/app_colors.dart';
import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../../shared/design_system/widgets/block_button.dart';
import '../../../../shared/design_system/widgets/furnace_loader.dart';
import '../../../../shared/design_system/widgets/pixel_app_bar.dart';
import '../../../../shared/design_system/widgets/pixel_toast.dart';
import '../../../../shared/design_system/widgets/stone_panel.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _tokenController = TextEditingController();
  late final AppLifecycleListener _lifecycleListener;
  bool _isWaitingForTelegram = false;
  Timer? _pollTimer;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _checkClipboardForToken(autoSubmit: false);

    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (_currentSessionId != null && _isWaitingForTelegram) {
          _checkTelegramSession(_currentSessionId!);
        }
        _checkClipboardForToken(autoSubmit: true);
      },
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _lifecycleListener.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _startTelegramAuth() async {
    final sessionId = 'et_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    _currentSessionId = sessionId;

    setState(() {
      _isWaitingForTelegram = true;
    });

    final ok = await TelegramLauncher.openBot(startParam: 'app_$sessionId');
    if (!ok && mounted) {
      setState(() => _isWaitingForTelegram = false);
      PixelToast.show(
        context,
        message: 'Бот: @${AppConfig.supportBot}',
        variant: PixelToastVariant.info,
      );
      return;
    }

    _pollTimer?.cancel();
    int attempts = 0;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      attempts++;
      if (attempts > 60 || !mounted || !_isWaitingForTelegram) {
        timer.cancel();
        if (mounted) setState(() => _isWaitingForTelegram = false);
        return;
      }

      await _checkTelegramSession(sessionId);
    });
  }

  Future<void> _checkTelegramSession(String sessionId) async {
    try {
      final url = Uri.parse('https://${AppConfig.subDomain}/app-auth/poll?session=$sessionId');
      final resp = await http.get(url).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['status'] == 'confirmed') {
          _pollTimer?.cancel();

          final tokenToLogin = (data['shortUuid'] as String?)?.isNotEmpty == true
              ? data['shortUuid'] as String
              : (data['subscriptionUrl'] as String? ?? '');

          final success =
              await ref.read(authControllerProvider.notifier).loginWithToken(tokenToLogin);

          if (mounted) {
            setState(() => _isWaitingForTelegram = false);
            if (success) {
              PixelToast.show(
                context,
                message: '🎉 Успешный вход через Telegram!',
                variant: PixelToastVariant.success,
              );
              context.go('/');
            } else {
              PixelToast.show(
                context,
                message: 'Ошибка верификации подписки',
                variant: PixelToastVariant.error,
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _checkClipboardForToken({bool autoSubmit = false}) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty) {
        final extracted = ref.read(deepLinkServiceProvider).extractToken(text);
        if (extracted != null && extracted.isNotEmpty) {
          _tokenController.text = extracted;
          if (autoSubmit && mounted) {
            _submitToken();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _submitToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    final success =
        await ref.read(authControllerProvider.notifier).loginWithToken(token);

    if (mounted) {
      if (success) {
        PixelToast.show(
          context,
          message: 'Успешный вход в аккаунт!',
          variant: PixelToastVariant.success,
        );
        context.go('/');
      } else {
        PixelToast.show(
          context,
          message: 'Неверный токен или код',
          variant: PixelToastVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.isAuthenticated && mounted) {
        context.go('/');
      }
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.mcVoid,
      appBar: const PixelAppBar(title: 'ВХОД В АККАУНТ'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Text(
              'АВТОРИЗАЦИЯ ЧЕРЕЗ БОТА',
              style: AppTypography.title(AppColors.mcEnder),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Нажми кнопку ниже — бот автоматически привяжет твой ключ и авторизует приложение!',
              style: AppTypography.caption(AppColors.mcTextDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (_isWaitingForTelegram) ...[
              StonePanel(
                child: Column(
                  children: [
                    const FurnaceLoader(),
                    const SizedBox(height: 14),
                    Text(
                      'ОЖИДАНИЕ ВХОДА В TELEGRAM...',
                      style: AppTypography.label(AppColors.mcGold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Перейди в бота @${AppConfig.supportBot} — приложение автоматически подтянет твои данные!',
                      style: AppTypography.caption(AppColors.mcTextDim),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    BlockButton(
                      label: 'ОТМЕНА',
                      variant: BlockButtonVariant.stone,
                      onTap: () {
                        _pollTimer?.cancel();
                        setState(() => _isWaitingForTelegram = false);
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              BlockButton(
                label: 'ВОЙТИ ЧЕРЕЗ TELEGRAM БОТА',
                icon: const Icon(Icons.send_rounded),
                variant: BlockButtonVariant.ender,
                onTap: _startTelegramAuth,
              ),
            ],
            const SizedBox(height: 20),

            StonePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ИЛИ ВВЕДИ КОД ИЗ БОТА:',
                    style: AppTypography.label(AppColors.mcText),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _tokenController,
                    style: AppTypography.label(AppColors.mcText),
                    decoration: InputDecoration(
                      hintText: 'Вставь токен или sub-ссылку...',
                      hintStyle: AppTypography.caption(AppColors.mcTextDim),
                      filled: true,
                      fillColor: const Color(0x18FFFFFF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x22FFFFFF), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.mcEnder, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (authState.isAuthenticating)
                    const Center(child: FurnaceLoader())
                  else ...[
                    BlockButton(
                      label: 'ВОЙТИ ПО КОДУ',
                      icon: const Icon(Icons.login_rounded),
                      variant: BlockButtonVariant.grass,
                      onTap: _submitToken,
                    ),
                    const SizedBox(height: 10),
                    BlockButton(
                      label: 'ВСТАВИТЬ ИЗ БУФЕРА',
                      icon: const Icon(Icons.content_paste_rounded),
                      variant: BlockButtonVariant.stone,
                      onTap: () => _checkClipboardForToken(autoSubmit: true),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
