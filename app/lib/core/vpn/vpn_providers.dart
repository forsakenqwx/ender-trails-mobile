import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/servers/domain/utils/country_detector.dart';
import '../../features/settings/domain/entities/app_settings.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';
import '../../features/subscription/domain/builder/singbox_config_builder.dart';
import '../../features/subscription/domain/entities/outbound_ref.dart';
import '../../features/subscription/presentation/providers/subscription_providers.dart';
import '../logging/app_logger.dart';
import 'fake_vpn_engine.dart';
import 'singbox_vpn_engine.dart';
import 'vpn_engine.dart';

/// Провайдер экземпляра VPN-ядра.
///
/// На Android используется реальное ядро [SingboxVpnEngine],
/// на других платформах и в тестах — [FakeVpnEngine].
final vpnEngineProvider = Provider<VpnEngine>((ref) {
  final VpnEngine engine;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    engine = SingboxVpnEngine();
  } else {
    engine = FakeVpnEngine();
  }

  ref.onDispose(() {
    if (engine is SingboxVpnEngine) {
      engine.dispose();
    } else if (engine is FakeVpnEngine) {
      engine.dispose();
    }
  });

  return engine;
});

/// Поток статусов туннеля.
final vpnStatusStreamProvider = StreamProvider<VpnStatus>((ref) {
  final engine = ref.watch(vpnEngineProvider);
  return engine.statusStream;
});

/// Поток статистики трафика.
final vpnTrafficStreamProvider = StreamProvider<TrafficStats>((ref) {
  final engine = ref.watch(vpnEngineProvider);
  return engine.trafficStream;
});

/// Состояние подключения на главном экране.
class VpnConnectionState {
  const VpnConnectionState({
    required this.status,
    required this.traffic,
    required this.duration,
    this.selectedServerName = 'Нидерланды · Amsterdam',
    this.selectedServerCountry = 'NL',
    this.selectedServerPing = 42,
  });

  final VpnStatus status;
  final TrafficStats traffic;
  final Duration duration;
  final String selectedServerName;
  final String selectedServerCountry;
  final int? selectedServerPing;

  VpnConnectionState copyWith({
    VpnStatus? status,
    TrafficStats? traffic,
    Duration? duration,
    String? selectedServerName,
    String? selectedServerCountry,
    int? selectedServerPing,
  }) {
    return VpnConnectionState(
      status: status ?? this.status,
      traffic: traffic ?? this.traffic,
      duration: duration ?? this.duration,
      selectedServerName: selectedServerName ?? this.selectedServerName,
      selectedServerCountry: selectedServerCountry ?? this.selectedServerCountry,
      selectedServerPing: selectedServerPing ?? this.selectedServerPing,
    );
  }
}

/// Контроллер управления туннелем на главном экране.
class VpnConnectionController extends Notifier<VpnConnectionState> {
  StreamSubscription<VpnStatus>? _statusSub;
  StreamSubscription<TrafficStats>? _trafficSub;
  Timer? _timer;

  @override
  VpnConnectionState build() {
    final engine = ref.watch(vpnEngineProvider);

    _statusSub?.cancel();
    _statusSub = engine.statusStream.listen(_onStatusChanged);

    _trafficSub?.cancel();
    _trafficSub = engine.trafficStream.listen(_onTrafficChanged);

    ref.onDispose(() {
      _statusSub?.cancel();
      _trafficSub?.cancel();
      _timer?.cancel();
    });

    return VpnConnectionState(
      status: engine.currentStatus,
      traffic: TrafficStats.zero,
      duration: Duration.zero,
    );
  }

  void _onStatusChanged(VpnStatus newStatus) {
    if (newStatus == VpnStatus.connected) {
      _startTimer();
    } else if (newStatus == VpnStatus.disconnected || newStatus == VpnStatus.error) {
      _stopTimer();
    }

    state = state.copyWith(status: newStatus);
  }

  void _onTrafficChanged(TrafficStats newTraffic) {
    state = state.copyWith(traffic: newTraffic);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(duration: state.duration + const Duration(seconds: 1));
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(duration: Duration.zero);
  }

  void selectServer({
    required String name,
    required String country,
    int? ping,
  }) {
    state = state.copyWith(
      selectedServerName: name,
      selectedServerCountry: country,
      selectedServerPing: ping,
    );
  }

  Future<bool> toggle() async {
    final engine = ref.read(vpnEngineProvider);
    if (state.status == VpnStatus.connected ||
        state.status == VpnStatus.connecting ||
        state.status == VpnStatus.preparing ||
        state.status == VpnStatus.reconnecting) {
      await engine.disconnect();
      return true;
    }

    // 1. Получаем профиль подписки (актуальный или из кэша)
    var profile = ref.read(subscriptionProfileProvider).value;
    if (profile == null || profile.outbounds.isEmpty) {
      final repo = ref.read(subscriptionRepositoryProvider);
      profile = await repo.getCachedProfile();
    }

    // 2. Если профиля всё ещё нет или в нём нет доступных узлов — пробуем резерв
    if (profile == null || profile.outbounds.isEmpty) {
      final repo = ref.read(subscriptionRepositoryProvider);
      final fallbackRes = await repo.fetchSubscription('txhbm_QWJD9a6zfk');
      profile = fallbackRes.fold((l) => null, (r) => r);
    }

    if (profile == null || profile.outbounds.isEmpty) {
      AppLogger.warning('Cannot connect: no subscription or outbounds loaded');
      return false;
    }

    // 3. Выбираем рабочий зарубежный сервер (фильтруем заглушки, промо-карточки и внутренние RU-мосты)
    final validOutbounds = profile.outbounds.where((o) {
      if (o.server == '127.0.0.1' || o.server == 'localhost') return false;
      if (o.server == '31.76.240.210' || o.server == '2.26.124.209' || o.tag.contains('Gemini ✨')) return false;
      if (o.rawConfig['uuid'] == '00000000-0000-0000-0000-000000000000') return false;
      final tagLower = o.tag.toLowerCase();
      if (tagLower.contains('lte') ||
          tagLower.contains('запасной') ||
          tagLower.contains('белых спис') ||
          tagLower.contains('промокод') ||
          o.server == '31.129.42.172' ||
          o.server.contains('ru-bridge')) {
        return false;
      }
      return true;
    }).toList();

    final candidateList = validOutbounds.isNotEmpty ? validOutbounds : profile.outbounds;

    String selectedTag;
    final matchedOutbound = candidateList.cast<OutboundRef?>().firstWhere(
      (o) {
        if (o == null) return false;
        if (state.selectedServerName == 'Авто-выбор' ||
            state.selectedServerName == '⚡ Авто-выбор') {
          return false;
        }
        if (o.tag == state.selectedServerName) return true;
        if (CountryDetector.cleanServerName(o.tag) == state.selectedServerName) {
          return true;
        }
        return false;
      },
      orElse: () => null,
    );

    if (matchedOutbound != null) {
      selectedTag = matchedOutbound.tag;
    } else {
      final preferred = candidateList.firstWhere(
        (o) =>
            o.tag.contains('Швеция') ||
            o.tag.contains('Германия') ||
            o.tag.contains('Нидерланды') ||
            o.tag.contains('Финляндия'),
        orElse: () => candidateList.first,
      );
      selectedTag = preferred.tag;
    }

    // 4. Сборка валидной конфигурации sing-box с гарантированным выбором рабочего сервера
    final settings = ref.read(settingsNotifierProvider).value;
    final killSwitch = settings?.killSwitch ?? false;
    final bypassLan = settings?.bypassLan ?? true;
    final dnsProvider = settings?.dnsProvider ?? DnsProvider.cloudflare;
    final splitTunnelingEnabled = settings?.splitTunnelingEnabled ?? false;
    final bypassedPackages = settings?.bypassedPackages ?? const <String>[];
    const configBuilder = SingboxConfigBuilder();

    await engine.setKillSwitch(killSwitch);

    final configJson = configBuilder.buildFromOutbounds(
      candidateList,
      selectedTag: selectedTag,
      bypassLan: bypassLan,
      dnsProvider: dnsProvider,
      splitTunnelingEnabled: splitTunnelingEnabled,
      bypassedPackages: bypassedPackages,
    );

    // 5. Запуск туннеля через реальное ядро sing-box
    final res = await engine.connect(
      VpnSession(
        configJson: configJson,
        outboundTag: selectedTag,
        notificationTitle: 'Ender Trails: $selectedTag',
      ),
    );

    return res.isRight();
  }
}

final vpnConnectionControllerProvider =
    NotifierProvider<VpnConnectionController, VpnConnectionState>(
  VpnConnectionController.new,
);
