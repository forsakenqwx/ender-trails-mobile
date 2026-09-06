import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Информация об установленном приложении для раздельного туннелирования
class AppInfo {
  const AppInfo({
    required this.name,
    required this.packageName,
    this.isSystem = false,
    this.iconBytes,
  });

  final String name;
  final String packageName;
  final bool isSystem;
  final Uint8List? iconBytes;

  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    final rawIcon = map['icon'];
    Uint8List? icon;
    if (rawIcon is Uint8List) {
      icon = rawIcon;
    } else if (rawIcon is List) {
      icon = Uint8List.fromList(rawIcon.cast<int>());
    }

    return AppInfo(
      name: map['name'] as String? ?? 'Приложение',
      packageName: map['package'] as String? ?? '',
      isSystem: map['isSystem'] as bool? ?? false,
      iconBytes: icon,
    );
  }
}

/// Сервис получения списка приложений Android для Split Tunneling
class AppListService {
  const AppListService();

  static const _channel = MethodChannel('online.endertrails.vpn/apps');

  /// Популярный пресет российских банков и критических сервисов для обхода VPN
  static const popularRussianApps = <AppInfo>[
    AppInfo(name: 'Сбербанк Онлайн', packageName: 'ru.sberbankmobile'),
    AppInfo(name: 'Т-Банк (Тинькофф)', packageName: 'com.idamob.tinkoff.android'),
    AppInfo(name: 'Альфа-Банк', packageName: 'ru.alfabank.mobile.android'),
    AppInfo(name: 'ВТБ Онлайн', packageName: 'ru.vtb24.mobilebanking'),
    AppInfo(name: 'Госуслуги', packageName: 'ru.gosuslugi.layout'),
    AppInfo(name: 'Яндекс Браузер / Поиск', packageName: 'ru.yandex.searchplugin'),
    AppInfo(name: 'Яндекс Карты', packageName: 'ru.yandex.yandexmaps'),
    AppInfo(name: 'Яндекс GO / Такси', packageName: 'ru.yandex.taxi'),
    AppInfo(name: 'ВКонтакте', packageName: 'com.vkontakte.android'),
    AppInfo(name: 'Wildberries', packageName: 'ru.wb.shop'),
    AppInfo(name: 'Ozon', packageName: 'ru.ozon.app.android'),
    AppInfo(name: 'Авито', packageName: 'com.avito.android'),
    AppInfo(name: '2ГИС', packageName: 'ru.dublgis.dgismobile'),
    AppInfo(name: 'Кинопоиск', packageName: 'ru.kinopoisk'),
    AppInfo(name: 'Telegram', packageName: 'org.telegram.messenger'),
    AppInfo(name: 'WhatsApp', packageName: 'com.whatsapp'),
    AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube'),
    AppInfo(name: 'Google Chrome', packageName: 'com.android.chrome'),
  ];

  /// Список пакетов российских сервисов для быстрого выделения в 1 клик
  static const Set<String> defaultBypassPackages = {
    'ru.sberbankmobile',
    'com.idamob.tinkoff.android',
    'ru.alfabank.mobile.android',
    'ru.vtb24.mobilebanking',
    'ru.gosuslugi.layout',
    'ru.yandex.searchplugin',
    'ru.yandex.yandexmaps',
    'ru.yandex.taxi',
    'com.vkontakte.android',
    'ru.wb.shop',
    'ru.ozon.app.android',
    'com.avito.android',
    'ru.dublgis.dgismobile',
    'ru.kinopoisk',
  };

  /// Получает установленные приложения (на Android через Platform Channel,
  /// с фолбэком на популярные приложения в эмуляторах/тестах).
  Future<List<AppInfo>> getInstalledApps() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
        if (res != null && res.isNotEmpty) {
          final list = res
              .whereType<Map<dynamic, dynamic>>()
              .map(AppInfo.fromMap)
              .where((a) =>
                  a.packageName.isNotEmpty &&
                  a.packageName != 'online.endertrails.vpn' &&
                  a.packageName != 'com.endertrails.ender_trails')
              .toList();

          if (list.isNotEmpty) {
            return list;
          }
        }
      } catch (e) {
        debugPrint('Failed to get installed apps via channel: $e');
      }
    }

    return popularRussianApps;
  }
}
