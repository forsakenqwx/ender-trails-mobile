/// Структурированные данные из заголовка `subscription-userinfo`.
///
/// Пример: `upload=1073741824; download=2147483648; total=107374182400; expire=1735689600`
class SubscriptionUserInfo {
  const SubscriptionUserInfo({
    required this.uploadBytes,
    required this.downloadBytes,
    required this.totalBytes,
    this.expireDate,
  });

  final int uploadBytes;
  final int downloadBytes;
  final int totalBytes;
  final DateTime? expireDate;

  /// Суммарный израсходованный трафик.
  int get usedBytes => uploadBytes + downloadBytes;

  /// Безлимитный ли тариф (total == 0).
  bool get isUnlimited => totalBytes <= 0;

  /// Доля израсходованного трафика [0.0..1.0].
  double get usageRatio {
    if (isUnlimited) return 0.0;
    final ratio = usedBytes / totalBytes;
    return ratio.clamp(0.0, 1.0);
  }

  /// Истекла ли подписка.
  bool get isExpired {
    final exp = expireDate;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  /// Сколько целых дней осталось.
  int get daysRemaining {
    final exp = expireDate;
    if (exp == null) return 0;
    final diff = exp.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }
}

/// Парсер заголовка `subscription-userinfo`.
class SubscriptionUserInfoParser {
  const SubscriptionUserInfoParser();

  SubscriptionUserInfo? parse(String? headerValue) {
    if (headerValue == null || headerValue.trim().isEmpty) {
      return null;
    }

    int upload = 0;
    int download = 0;
    int total = 0;
    DateTime? expire;

    final parts = headerValue.split(';');
    for (final rawPart in parts) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;

      final kv = part.split('=');
      if (kv.length != 2) continue;

      final key = kv[0].trim().toLowerCase();
      final val = kv[1].trim();

      switch (key) {
        case 'upload':
          upload = int.tryParse(val) ?? 0;
          break;
        case 'download':
          download = int.tryParse(val) ?? 0;
          break;
        case 'total':
          total = int.tryParse(val) ?? 0;
          break;
        case 'expire':
          final epochSec = int.tryParse(val);
          if (epochSec != null && epochSec > 0) {
            expire = DateTime.fromMillisecondsSinceEpoch(
              epochSec * 1000,
              isUtc: true,
            );
          }
          break;
      }
    }

    return SubscriptionUserInfo(
      uploadBytes: upload,
      downloadBytes: download,
      totalBytes: total,
      expireDate: expire,
    );
  }
}
