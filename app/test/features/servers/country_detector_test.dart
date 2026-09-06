import 'package:flutter_test/flutter_test.dart';

import 'package:ender_trails/features/servers/domain/utils/country_detector.dart';

void main() {
  group('CountryDetector', () {
    test('detects country code from emoji flag', () {
      expect(CountryDetector.detect('🇩🇪 Германия · Франкфурт'), equals('DE'));
      expect(CountryDetector.detect('🇳🇱 Amsterdam #1'), equals('NL'));
      expect(CountryDetector.detect('🇫🇮 Helsinki Fast'), equals('FI'));
      expect(CountryDetector.detect('🇰🇿 Almaty Premium'), equals('KZ'));
    });

    test('detects country code from prefix tag', () {
      expect(CountryDetector.detect('NL-01'), equals('NL'));
      expect(CountryDetector.detect('FI_02'), equals('FI'));
      expect(CountryDetector.detect('DE-Frankfurt'), equals('DE'));
    });

    test('detects country code from text words', () {
      expect(CountryDetector.detect('Sweden Stockholm 10G'), equals('SE'));
      expect(CountryDetector.detect('Россия Selectel'), equals('RU'));
      expect(CountryDetector.detect('Казахстан Телеком'), equals('KZ'));
    });

    test('detects all requested countries from emoji, names, and codes', () {
      expect(CountryDetector.detect('🇱🇻 Латвия · Рига'), equals('LV'));
      expect(CountryDetector.detect('🇮🇹 Италия · Милан'), equals('IT'));
      expect(CountryDetector.detect('🇱🇹 Литва · Вильнюс'), equals('LT'));
      expect(CountryDetector.detect('🇨🇿 Чехия · Прага'), equals('CZ'));
      expect(CountryDetector.detect('🇮🇪 Ирландия · Дублин'), equals('IE'));
      expect(CountryDetector.detect('🇧🇪 Бельгия · Брюссель'), equals('BE'));
      expect(CountryDetector.detect('🇪🇸 Испания · Мадрид'), equals('ES'));
      expect(CountryDetector.detect('🇭🇰 Гонконг Fast'), equals('HK'));
      expect(CountryDetector.detect('🇦🇹 Австрия · Вена'), equals('AT'));
      expect(CountryDetector.detect('🇧🇷 Бразилия · Сан-Паулу'), equals('BR'));
      expect(CountryDetector.detect('AUT-01'), equals('AT'));
      expect(CountryDetector.detect('LVA-01'), equals('LV'));
      expect(CountryDetector.detect('[BRA] Rio'), equals('BR'));
    });

    test('returns UN for unknown location', () {
      expect(CountryDetector.detect('Custom Node 999'), equals('UN'));
    });

    test('cleanServerName removes all emojis, pins, and pipe decorators without orphan surrogates', () {
      expect(CountryDetector.cleanServerName('🇩🇪 Германия · Франкфурт'), equals('Германия · Франкфурт'));
      expect(CountryDetector.cleanServerName('🇳🇱 📍Нидерланды | 🧀'), equals('Нидерланды'));
      expect(CountryDetector.cleanServerName('🇩🇪 📍Германия | 🍺'), equals('Германия'));
      expect(CountryDetector.cleanServerName('📍 Нидерланды | 🇳🇱'), equals('Нидерланды'));
      expect(CountryDetector.cleanServerName('🇪🇺 📍БС 1 | 🧿'), equals('БС 1'));
      expect(CountryDetector.cleanServerName('📍 Россия | 🇷🇺'), equals('Россия'));
      expect(CountryDetector.cleanServerName('Нидерланды · Amsterdam'), equals('Нидерланды · Amsterdam'));
      expect(CountryDetector.detect('🇪🇺 📍БС 1 | 🧿'), equals('EU'));
    });
  });
}
