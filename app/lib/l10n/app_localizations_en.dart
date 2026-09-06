// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ender Trails';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get statusConnecting => 'Connecting...';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusReconnecting => 'Reconnecting';

  @override
  String get statusError => 'Error';

  @override
  String get hintConnect => 'Pull the lever to enter the End';

  @override
  String get hintConnected => 'Tunnel is up, traffic is protected';

  @override
  String get hintConnecting => 'Building the tunnel...';

  @override
  String get traffic => 'Traffic';

  @override
  String get trafficUnlimited => 'Unlimited';

  @override
  String get subscription => 'Subscription';

  @override
  String daysLeft(int days) {
    return '$days days left';
  }

  @override
  String get subscriptionExpired => 'Expired';

  @override
  String get selectedServer => 'Selected server';

  @override
  String get servers => 'Servers';

  @override
  String get settings => 'Settings';

  @override
  String get pingUnknown => 'no reply';

  @override
  String get serverUnavailable => 'unavailable';

  @override
  String get designSystem => 'Design system';

  @override
  String get uplink => 'up';

  @override
  String get downlink => 'down';
}
