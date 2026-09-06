// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Ender Trails';

  @override
  String get statusDisconnected => 'Отключено';

  @override
  String get statusConnecting => 'Подключаемся...';

  @override
  String get statusConnected => 'Подключено';

  @override
  String get statusReconnecting => 'Переподключение';

  @override
  String get statusError => 'Ошибка';

  @override
  String get hintConnect => 'Дёрни рычаг, чтобы войти в Энд';

  @override
  String get hintConnected => 'Туннель поднят, трафик защищён';

  @override
  String get hintConnecting => 'Строим туннель...';

  @override
  String get traffic => 'Трафик';

  @override
  String get trafficUnlimited => 'Безлимит';

  @override
  String get subscription => 'Подписка';

  @override
  String daysLeft(int days) {
    return 'Осталось $days дн.';
  }

  @override
  String get subscriptionExpired => 'Истекла';

  @override
  String get selectedServer => 'Выбранный сервер';

  @override
  String get servers => 'Серверы';

  @override
  String get settings => 'Настройки';

  @override
  String get pingUnknown => 'нет ответа';

  @override
  String get serverUnavailable => 'недоступен';

  @override
  String get designSystem => 'Дизайн-система';

  @override
  String get uplink => 'отдача';

  @override
  String get downlink => 'загрузка';
}
