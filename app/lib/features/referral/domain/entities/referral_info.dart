/// Модель данных реферальной программы пользователя.
class ReferralInfo {
  const ReferralInfo({
    required this.code,
    required this.link,
    required this.invitedCount,
    required this.activeCount,
    required this.bonusDaysEarned,
    this.rewardText = '+7 дней подписки за каждого приглашённого друга',
  });

  final String code;
  final String link;
  final int invitedCount;
  final int activeCount;
  final int bonusDaysEarned;
  final String rewardText;

  ReferralInfo copyWith({
    String? code,
    String? link,
    int? invitedCount,
    int? activeCount,
    int? bonusDaysEarned,
    String? rewardText,
  }) {
    return ReferralInfo(
      code: code ?? this.code,
      link: link ?? this.link,
      invitedCount: invitedCount ?? this.invitedCount,
      activeCount: activeCount ?? this.activeCount,
      bonusDaysEarned: bonusDaysEarned ?? this.bonusDaysEarned,
      rewardText: rewardText ?? this.rewardText,
    );
  }
}
