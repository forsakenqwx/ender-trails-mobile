import '../entities/app_settings.dart';

/// Контракт постоянного хранения настроек приложения.
abstract interface class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}
