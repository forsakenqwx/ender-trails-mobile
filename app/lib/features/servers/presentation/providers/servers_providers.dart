import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/vpn/vpn_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../data/repositories/servers_repository_impl.dart';
import '../../domain/entities/server_item.dart';
import '../../domain/repositories/servers_repository.dart';

final serversRepositoryProvider = Provider<ServersRepository>((ref) {
  return ServersRepositoryImpl(
    storage: ref.watch(secureStorageProvider),
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
  );
});

class ServersNotifier extends AsyncNotifier<List<ServerModel>> {
  @override
  Future<List<ServerModel>> build() async {
    // Подписываемся на обновления профиля подписки
    ref.watch(subscriptionProfileProvider);

    final repo = ref.read(serversRepositoryProvider);
    final initialList = await repo.getServers();

    // Запускаем фоновый замер пинга без блокировки интерфейса
    _pingServersAsync(initialList);

    return initialList;
  }

  Future<void> _pingServersAsync(List<ServerModel> currentList) async {
    ref.read(isPingingProvider.notifier).setPinging(true);
    try {
      final repo = ref.read(serversRepositoryProvider);
      final withPings = await repo.pingAllServers(currentList);
      state = AsyncValue.data(withPings);
    } finally {
      ref.read(isPingingProvider.notifier).setPinging(false);
    }
  }

  Future<void> refreshPings() async {
    final current = state.value ?? [];
    if (current.isEmpty) return;
    await _pingServersAsync(current);
  }

  Future<void> selectServer(ServerModel server) async {
    final repo = ref.read(serversRepositoryProvider);
    await repo.switchServer(server.tag);

    ref.read(vpnConnectionControllerProvider.notifier).selectServer(
          name: server.name,
          country: server.countryCode,
          ping: server.pingMs ?? 50,
        );
  }
}

/// Состояние процесса замера пинга серверов (совместимо с Riverpod 3)
class IsPingingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setPinging(bool value) => state = value;
}

final isPingingProvider =
    NotifierProvider<IsPingingNotifier, bool>(IsPingingNotifier.new);

final serversNotifierProvider =
    AsyncNotifierProvider<ServersNotifier, List<ServerModel>>(
  ServersNotifier.new,
);
