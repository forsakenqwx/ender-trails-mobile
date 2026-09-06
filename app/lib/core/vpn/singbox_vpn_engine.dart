import 'dart:async';
import 'package:flutter_singbox_client/flutter_singbox_client.dart' as sb;

import '../error/failure.dart';
import '../error/result.dart';
import '../logging/app_logger.dart';
import 'vpn_engine.dart';

/// Реализация [VpnEngine] на базе sing-box ядра (flutter_singbox_client).
///
/// Документация: docs/vpn-core.md.
class SingboxVpnEngine implements VpnEngine {
  SingboxVpnEngine({
    sb.SingboxClient? client,
  }) : _client = client ?? sb.SingboxClient() {
    _initEngine();
  }

  final sb.SingboxClient _client;
  final _statusController = StreamController<VpnStatus>.broadcast();
  final _trafficController = StreamController<TrafficStats>.broadcast();

  StreamSubscription<sb.ServiceState>? _stateSub;
  StreamSubscription<sb.TrafficStats>? _trafficSub;
  StreamSubscription<String>? _faultSub;

  VpnStatus _currentStatus = VpnStatus.disconnected;
  bool _killSwitch = false;

  Future<void> _initEngine() async {
    try {
      await _client.initialize();
      _stateSub = _client.serviceStateStream.listen(_onServiceStateChanged);
      _trafficSub = _client.trafficStatsStream.listen(_onTrafficStatsChanged);
      _faultSub = _client.faultStream.listen(_onFault);
    } catch (e) {
      AppLogger.error('Failed to initialize SingboxClient subscriptions: $e');
    }
  }

  void _onServiceStateChanged(sb.ServiceState state) {
    final mapped = switch (state) {
      sb.ServiceState.stopped => VpnStatus.disconnected,
      sb.ServiceState.starting => VpnStatus.connecting,
      sb.ServiceState.started => VpnStatus.connected,
      sb.ServiceState.stopping => VpnStatus.disconnecting,
    };
    _updateStatus(mapped);
  }

  void _onTrafficStatsChanged(sb.TrafficStats stats) {
    if (_trafficController.isClosed) return;
    _trafficController.add(
      TrafficStats(
        uplinkBps: stats.uplinkBps,
        downlinkBps: stats.downlinkBps,
        sessionUploadBytes: stats.uplinkTotalBytes,
        sessionDownloadBytes: stats.downlinkTotalBytes,
      ),
    );
  }

  void _onFault(String faultMessage) {
    AppLogger.error('Singbox core fault: $faultMessage');
    _updateStatus(VpnStatus.error);
  }

  void _updateStatus(VpnStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  @override
  VpnStatus get currentStatus => _currentStatus;

  @override
  Stream<VpnStatus> get statusStream => _statusController.stream;

  @override
  Stream<TrafficStats> get trafficStream => _trafficController.stream;

  @override
  Future<Result<bool>> ensurePermission() async {
    try {
      await _client.initialize();
      final granted = await _client.requestVPNPermission();
      return ok(granted);
    } catch (e, st) {
      AppLogger.error('ensurePermission failed: $e', e, st);
      return fail(VpnFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<ResultUnit> connect(VpnSession session) async {
    try {
      _updateStatus(VpnStatus.preparing);
      await _client.initialize();

      // Проверяем разрешение VPN
      final hasPermission = await _client.requestVPNPermission();
      if (!hasPermission) {
        _updateStatus(VpnStatus.disconnected);
        return fail(const VpnFailure(debugMessage: 'VPN permission denied'));
      }

      // Валидируем конфиг
      try {
        await _client.checkConfig(session.configJson);
      } catch (e) {
        AppLogger.error('Invalid sing-box config: $e');
        _updateStatus(VpnStatus.error);
        return fail(ParseFailure(debugMessage: e.toString()));
      }

      _updateStatus(VpnStatus.connecting);

      await _client.connect(
        sb.SessionOptions(
          config: session.configJson,
          networkMode: sb.NetworkMode.vpn,
          killSwitch: _killSwitch,
          notification: sb.NotificationConfig(
            title: session.notificationTitle ?? 'Ender Trails',
            showTrafficStats: true,
          ),
        ),
      );

      return okUnit;
    } catch (e, st) {
      AppLogger.error('Singbox connect error: $e', e, st);
      _updateStatus(VpnStatus.error);
      return fail(VpnFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<ResultUnit> disconnect() async {
    try {
      _updateStatus(VpnStatus.disconnecting);
      await _client.disconnect();
      _updateStatus(VpnStatus.disconnected);
      if (!_trafficController.isClosed) {
        _trafficController.add(TrafficStats.zero);
      }
      return okUnit;
    } catch (e, st) {
      AppLogger.error('Singbox disconnect error: $e', e, st);
      return fail(VpnFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<ResultUnit> selectOutbound(String tag) async {
    try {
      await _client.selectOutbound('proxy', tag);
      return okUnit;
    } catch (e, st) {
      AppLogger.error('Singbox selectOutbound error: $e', e, st);
      return fail(VpnFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<ResultUnit> setKillSwitch(bool enabled) async {
    _killSwitch = enabled;
    return okUnit;
  }

  void dispose() {
    _stateSub?.cancel();
    _trafficSub?.cancel();
    _faultSub?.cancel();
    _statusController.close();
    _trafficController.close();
  }
}
