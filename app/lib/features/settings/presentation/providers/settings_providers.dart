import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/app_list_service.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

final appListServiceProvider = Provider<AppListService>((ref) {
  return const AppListService();
});

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final service = ref.watch(appListServiceProvider);
  return service.getInstalledApps();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    storage: ref.watch(secureStorageProvider),
  );
});

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.getSettings();
  }

  Future<void> updateKillSwitch(bool enabled) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(killSwitch: enabled);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateBypassLan(bool enabled) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(bypassLan: enabled);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateAutoConnect(bool enabled) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(autoConnect: enabled);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateDnsProvider(DnsProvider provider) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(dnsProvider: provider);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> updateSplitTunneling(bool enabled) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(splitTunnelingEnabled: enabled);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> setBypassedPackages(List<String> packages) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(bypassedPackages: packages);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }
}

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
