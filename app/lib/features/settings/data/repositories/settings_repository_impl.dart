import 'dart:convert';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({required this.storage});

  final AppSecureStorage storage;

  @override
  Future<AppSettings> getSettings() async {
    try {
      final jsonStr = await storage.getSettingsJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return AppSettings.fromJson(map);
      }
    } catch (e) {
      AppLogger.warning('Failed to parse saved settings: $e');
    }
    return const AppSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final jsonStr = jsonEncode(settings.toJson());
      await storage.saveSettingsJson(jsonStr);
    } catch (e) {
      AppLogger.error('Failed to save settings: $e');
    }
  }
}
