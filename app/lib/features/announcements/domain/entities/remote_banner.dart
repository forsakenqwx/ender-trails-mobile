/// Модель удалённого онлайн-баннера анонсов и новостей.
class RemoteBanner {
  const RemoteBanner({
    required this.id,
    required this.enabled,
    required this.title,
    required this.text,
    this.actionUrl,
    this.type = 'info',
  });

  final String id;
  final bool enabled;
  final String title;
  final String text;
  final String? actionUrl;
  final String type; // 'info' | 'promo' | 'warning'

  factory RemoteBanner.fromJson(Map<String, dynamic> json) {
    return RemoteBanner(
      id: json['id'] as String? ?? 'default',
      enabled: json['enabled'] as bool? ?? true,
      title: json['title'] as String? ?? 'НОВОСТИ',
      text: json['text'] as String? ?? '',
      actionUrl: json['action_url'] as String? ?? json['actionUrl'] as String?,
      type: json['type'] as String? ?? 'info',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'enabled': enabled,
        'title': title,
        'text': text,
        'action_url': actionUrl,
        'type': type,
      };
}
