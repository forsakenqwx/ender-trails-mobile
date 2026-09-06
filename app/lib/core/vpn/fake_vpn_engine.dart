import 'dart:async';
import 'dart:math';

import '../error/result.dart';
import 'vpn_engine.dart';

/// Фейковое ядро для разработки UI и тестов.
///
/// Не поднимает настоящий туннель: эмулирует задержку подключения,
/// статусы и трафик. Позволяет разрабатывать весь интерфейс до того,
/// как собрано реальное ядро (MASTER-PROMPT §7, roadmap E0).
class FakeVpnEngine implements VpnEngine {
  FakeVpnEngine({this.connectDelay = const Duration(milliseconds: 1200)});

  final Duration connectDelay;

  final _status = StreamController<VpnStatus>.broadcast();
  final _traffic = StreamController<TrafficStats>.broadcast();

  Timer? _trafficTimer;
  VpnStatus _current = VpnStatus.disconnected;
  int _up = 0;
  int _down = 0;
  final _random = Random();

  @override
  VpnStatus get currentStatus => _current;

  @override
  Future<Result<bool>> ensurePermission() async => ok(true);

  @override
  Future<ResultUnit> connect(VpnSession session) async {
    _emitStatus(VpnStatus.preparing);
    await Future<void>.delayed(const Duration(milliseconds: 240));

    _emitStatus(VpnStatus.connecting);
    await Future<void>.delayed(connectDelay);

    _emitStatus(VpnStatus.connected);
    _startTrafficTicking();
    return okUnit;
  }

  @override
  Future<ResultUnit> disconnect() async {
    _emitStatus(VpnStatus.disconnecting);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _stopTrafficTicking();
    _up = 0;
    _down = 0;
    _emit(_traffic, TrafficStats.zero);
    _emitStatus(VpnStatus.disconnected);
    return okUnit;
  }

  @override
  Future<ResultUnit> selectOutbound(String tag) async => okUnit;

  @override
  Future<ResultUnit> setKillSwitch(bool enabled) async => okUnit;

  @override
  Stream<VpnStatus> get statusStream => _status.stream;

  @override
  Stream<TrafficStats> get trafficStream => _traffic.stream;

  void _startTrafficTicking() {
    _trafficTimer?.cancel();
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final upBps = 200 * 1024 + _random.nextInt(600 * 1024);
      final downBps = 800 * 1024 + _random.nextInt(6 * 1024 * 1024);
      _up += upBps;
      _down += downBps;
      _emit(
        _traffic,
        TrafficStats(
          uplinkBps: upBps,
          downlinkBps: downBps,
          sessionUploadBytes: _up,
          sessionDownloadBytes: _down,
        ),
      );
    });
  }

  void _stopTrafficTicking() {
    _trafficTimer?.cancel();
    _trafficTimer = null;
  }

  void _emitStatus(VpnStatus status) {
    _current = status;
    _emit(_status, status);
  }

  void _emit<T>(StreamController<T> controller, T value) {
    if (!controller.isClosed) controller.add(value);
  }

  void dispose() {
    _stopTrafficTicking();
    _status.close();
    _traffic.close();
  }
}
