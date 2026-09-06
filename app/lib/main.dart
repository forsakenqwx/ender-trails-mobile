import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_singbox_client/flutter_singbox_client.dart' as sb;

import 'app.dart';
import 'core/logging/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('Ender Trails starting...');

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await sb.SingboxClient().initialize();
    } catch (e) {
      AppLogger.error('Singbox early init error: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: EnderTrailsApp(),
    ),
  );
}
