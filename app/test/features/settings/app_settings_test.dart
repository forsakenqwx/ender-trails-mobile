import 'package:flutter_test/flutter_test.dart';

import 'package:ender_trails/features/settings/domain/entities/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('default values match security requirements', () {
      const settings = AppSettings();

      expect(settings.killSwitch, isFalse);
      expect(settings.bypassLan, isTrue);
      expect(settings.autoConnect, isFalse);
      expect(settings.dnsProvider, equals(DnsProvider.cloudflare));
      expect(settings.splitTunnelingEnabled, isFalse);
      expect(settings.bypassedPackages, isEmpty);
    });

    test('serializes and deserializes JSON cleanly', () {
      const original = AppSettings(
        killSwitch: false,
        bypassLan: true,
        autoConnect: true,
        dnsProvider: DnsProvider.adguard,
        splitTunnelingEnabled: true,
        bypassedPackages: ['ru.sberbankmobile', 'ru.vtb24.mobilebanking'],
      );

      final json = original.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.killSwitch, isFalse);
      expect(restored.bypassLan, isTrue);
      expect(restored.autoConnect, isTrue);
      expect(restored.dnsProvider, equals(DnsProvider.adguard));
      expect(restored.splitTunnelingEnabled, isTrue);
      expect(restored.bypassedPackages, contains('ru.sberbankmobile'));
    });

    test('copyWith properly updates individual fields', () {
      const settings = AppSettings();
      final updated = settings.copyWith(
        killSwitch: true,
        dnsProvider: DnsProvider.google,
      );

      expect(updated.killSwitch, isTrue);
      expect(updated.dnsProvider, equals(DnsProvider.google));
      expect(updated.bypassLan, isTrue); // remains default
    });
  });
}
