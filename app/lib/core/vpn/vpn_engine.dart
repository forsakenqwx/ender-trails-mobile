import '../error/result.dart';

/// Состояние туннеля.
enum VpnStatus {
  disconnected,
  preparing,
  connecting,
  connected,
  reconnecting,
  disconnecting,
  error,
}

/// Трафик за сессию и мгновенные скорости (байты/с).
class TrafficStats {
  const TrafficStats({
    required this.uplinkBps,
    required this.downlinkBps,
    required this.sessionUploadBytes,
    required this.sessionDownloadBytes,
  });

  static const zero = TrafficStats(
    uplinkBps: 0,
    downlinkBps: 0,
    sessionUploadBytes: 0,
    sessionDownloadBytes: 0,
  );

  final int uplinkBps;
  final int downlinkBps;
  final int sessionUploadBytes;
  final int sessionDownloadBytes;

  int get sessionTotalBytes => sessionUploadBytes + sessionDownloadBytes;
}

/// Параметры подключения.
class VpnSession {
  const VpnSession({
    required this.configJson,
    required this.outboundTag,
    this.notificationTitle,
  });

  /// Готовый sing-box конфиг (как отдал сервер, возможно минимально пропатченный).
  final String configJson;

  /// Выбранный outbound. `null` — «авто» (urltest).
  final String? outboundTag;

  final String? notificationTitle;
}

/// Абстракция над VPN-ядром.
///
/// MASTER-PROMPT §3.6: реализация (sing-box плагин, свой libbox-плагин, фейк)
/// меняется без переписывания фич. Ни один экран не импортирует пакет ядра.
abstract interface class VpnEngine {
  /// Разрешение системы на VPN. На Android — диалог VpnService.
  Future<Result<bool>> ensurePermission();

  /// Поднять туннель.
  Future<ResultUnit> connect(VpnSession session);

  /// Опустить туннель.
  Future<ResultUnit> disconnect();

  /// Переключить outbound без разрыва туннеля (через selector/urltest).
  Future<ResultUnit> selectOutbound(String tag);

  Future<ResultUnit> setKillSwitch(bool enabled);

  VpnStatus get currentStatus;

  Stream<VpnStatus> get statusStream;

  Stream<TrafficStats> get trafficStream;
}
