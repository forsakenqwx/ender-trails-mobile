import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Application name shown in the app bar
  ///
  /// In en, this message translates to:
  /// **'Ender Trails'**
  String get appTitle;

  /// VPN is off
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get statusDisconnected;

  /// VPN is establishing a tunnel
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get statusConnecting;

  /// VPN tunnel is up
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// Tunnel dropped, retrying
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get statusReconnecting;

  /// Tunnel failed
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// Hint below the lever when disconnected
  ///
  /// In en, this message translates to:
  /// **'Pull the lever to enter the End'**
  String get hintConnect;

  /// Hint below the lever when connected
  ///
  /// In en, this message translates to:
  /// **'Tunnel is up, traffic is protected'**
  String get hintConnected;

  /// Hint below the lever while connecting
  ///
  /// In en, this message translates to:
  /// **'Building the tunnel...'**
  String get hintConnecting;

  /// Label for used/available traffic
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get traffic;

  /// Shown when traffic is not limited
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get trafficUnlimited;

  /// Label for subscription expiry
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// How many days are left on the subscription
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysLeft(int days);

  /// Subscription is over
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subscriptionExpired;

  /// Label above the current server row
  ///
  /// In en, this message translates to:
  /// **'Selected server'**
  String get selectedServer;

  /// Servers screen title
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get servers;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Server does not answer
  ///
  /// In en, this message translates to:
  /// **'no reply'**
  String get pingUnknown;

  /// Server is down
  ///
  /// In en, this message translates to:
  /// **'unavailable'**
  String get serverUnavailable;

  /// Title of the component showcase screen
  ///
  /// In en, this message translates to:
  /// **'Design system'**
  String get designSystem;

  /// Short label for upload speed
  ///
  /// In en, this message translates to:
  /// **'up'**
  String get uplink;

  /// Short label for download speed
  ///
  /// In en, this message translates to:
  /// **'down'**
  String get downlink;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
