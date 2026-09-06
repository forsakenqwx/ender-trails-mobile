import 'outbound_ref.dart';
import '../parsers/subscription_userinfo_parser.dart';

/// Полные данные подписки пользователя и список серверов.
class SubscriptionProfile {
  const SubscriptionProfile({
    required this.userInfo,
    required this.outbounds,
    required this.singboxConfig,
    this.updateIntervalHours = 24,
    this.webPageUrl,
  });

  final SubscriptionUserInfo userInfo;
  final List<OutboundRef> outbounds;
  final String singboxConfig;
  final int updateIntervalHours;
  final String? webPageUrl;
}
