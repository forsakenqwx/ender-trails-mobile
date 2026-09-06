/// Утилита определения двухбуквенного кода страны (ISO 3166-1 alpha-2)
/// из названия ноды, эмодзи флага или тега.
class CountryDetector {
  const CountryDetector._();

  static const _flagMap = <String, String>{
    '🇩🇪': 'DE',
    '🇫🇮': 'FI',
    '🇸🇪': 'SE',
    '🇳🇱': 'NL',
    '🇰🇿': 'KZ',
    '🇷🇺': 'RU',
    '🇺🇸': 'US',
    '🇬🇧': 'GB',
    '🇵🇱': 'PL',
    '🇫🇷': 'FR',
    '🇪🇪': 'EE',
    '🇦🇹': 'AT',
    '🇮🇹': 'IT',
    '🇪🇸': 'ES',
    '🇨🇿': 'CZ',
    '🇱🇻': 'LV',
    '🇱🇹': 'LT',
    '🇮🇪': 'IE',
    '🇧🇪': 'BE',
    '🇭🇰': 'HK',
    '🇧🇷': 'BR',
    '🇨🇦': 'CA',
    '🇸🇬': 'SG',
    '🇯🇵': 'JP',
    '🇹🇷': 'TR',
    '🇺🇦': 'UA',
    '🇳🇴': 'NO',
    '🇩🇰': 'DK',
    '🇨🇭': 'CH',
    '🇧🇬': 'BG',
    '🇷🇴': 'RO',
    '🇭🇺': 'HU',
    '🇬🇷': 'GR',
    '🇮🇱': 'IL',
    '🇦🇪': 'AE',
    '🇦🇺': 'AU',
    '🇮🇳': 'IN',
    '🇰🇷': 'KR',
    '🇪🇺': 'EU',
  };

  static const _iso3Map = <String, String>{
    'EUR': 'EU',
    'EU': 'EU',
    'LVA': 'LV',
    'ITA': 'IT',
    'LTU': 'LT',
    'CZE': 'CZ',
    'IRL': 'IE',
    'BEL': 'BE',
    'ESP': 'ES',
    'HKG': 'HK',
    'AUT': 'AT',
    'BRA': 'BR',
    'NLD': 'NL',
    'DEU': 'DE',
    'FIN': 'FI',
    'SWE': 'SE',
    'KAZ': 'KZ',
    'RUS': 'RU',
    'USA': 'US',
    'GBR': 'GB',
    'FRA': 'FR',
    'POL': 'PL',
    'EST': 'EE',
    'CHE': 'CH',
    'SGP': 'SG',
    'TUR': 'TR',
    'JPN': 'JP',
    'CAN': 'CA',
    'UKR': 'UA',
    'NOR': 'NO',
    'DNK': 'DK',
    'BGR': 'BG',
    'ROU': 'RO',
    'HUN': 'HU',
    'GRC': 'GR',
    'ISR': 'IL',
    'ARE': 'AE',
    'AUS': 'AU',
    'IND': 'IN',
    'KOR': 'KR',
  };

  static const _textMap = <String, String>{
    // 🇱🇻 Латвия
    'латвия': 'LV',
    'латви': 'LV',
    'latvia': 'LV',
    'latvija': 'LV',
    'рига': 'LV',
    'riga': 'LV',

    // 🇮🇹 Италия
    'италия': 'IT',
    'итали': 'IT',
    'italy': 'IT',
    'italia': 'IT',
    'рим': 'IT',
    'rome': 'IT',
    'милан': 'IT',
    'milan': 'IT',

    // 🇱🇹 Литва
    'литва': 'LT',
    'литв': 'LT',
    'lithuania': 'LT',
    'lietuva': 'LT',
    'вильнюс': 'LT',
    'vilnius': 'LT',

    // 🇨🇿 Чехия
    'чехия': 'CZ',
    'чехи': 'CZ',
    'czech': 'CZ',
    'czechia': 'CZ',
    'прага': 'CZ',
    'prague': 'CZ',

    // 🇮🇪 Ирландия
    'ирландия': 'IE',
    'ирланди': 'IE',
    'ireland': 'IE',
    'дублин': 'IE',
    'dublin': 'IE',

    // 🇧🇪 Бельгия
    'бельгия': 'BE',
    'бельги': 'BE',
    'belgium': 'BE',
    'брюссель': 'BE',
    'brussels': 'BE',

    // 🇪🇸 Испания
    'испания': 'ES',
    'испани': 'ES',
    'spain': 'ES',
    'espana': 'ES',
    'españa': 'ES',
    'мадрид': 'ES',
    'madrid': 'ES',
    'барселона': 'ES',
    'barcelona': 'ES',

    // 🇭🇰 Гонконг
    'гонконг': 'HK',
    'гонгконг': 'HK',
    'hong kong': 'HK',
    'hongkong': 'HK',
    'hong-kong': 'HK',

    // 🇦🇹 Австрия
    'австрия': 'AT',
    'австри': 'AT',
    'austria': 'AT',
    'osterreich': 'AT',
    'österreich': 'AT',
    'вена': 'AT',
    'vienna': 'AT',

    // 🇧🇷 Бразилия
    'бразилия': 'BR',
    'бразили': 'BR',
    'brazil': 'BR',
    'brasil': 'BR',
    'сан-паулу': 'BR',
    'sao paulo': 'BR',
    'рио': 'BR',
    'rio': 'BR',

    // Другие популярные страны
    'германия': 'DE',
    'германи': 'DE',
    'germany': 'DE',
    'frankfurt': 'DE',
    'франкфурт': 'DE',
    'финляндия': 'FI',
    'финлянд': 'FI',
    'финля': 'FI',
    'finland': 'FI',
    'helsinki': 'FI',
    'хельсинки': 'FI',
    'швеция': 'SE',
    'швеци': 'SE',
    'sweden': 'SE',
    'stockholm': 'SE',
    'стокгольм': 'SE',
    'нидерланды': 'NL',
    'нидер': 'NL',
    'netherlands': 'NL',
    'amsterdam': 'NL',
    'амстердам': 'NL',
    'казахстан': 'KZ',
    'kazakhstan': 'KZ',
    'almaty': 'KZ',
    'алматы': 'KZ',
    'astana': 'KZ',
    'астана': 'KZ',
    'россия': 'RU',
    'russia': 'RU',
    'москва': 'RU',
    'питер': 'RU',
    'сша': 'US',
    'usa': 'US',
    'united states': 'US',
    'великобритания': 'GB',
    'london': 'GB',
    'лондон': 'GB',
    'польша': 'PL',
    'польш': 'PL',
    'poland': 'PL',
    'warsaw': 'PL',
    'варшава': 'PL',
    'франция': 'FR',
    'франци': 'FR',
    'france': 'FR',
    'paris': 'FR',
    'париж': 'FR',
    'эстония': 'EE',
    'эстони': 'EE',
    'estonia': 'EE',
    'tallinn': 'EE',
    'таллин': 'EE',
    'швейцария': 'CH',
    'швейцари': 'CH',
    'switzerland': 'CH',
    'zurich': 'CH',
    'цюрих': 'CH',
    'турция': 'TR',
    'turkey': 'TR',
    'istanbul': 'TR',
    'стамбул': 'TR',
    'сингапур': 'SG',
    'singapore': 'SG',
    'япония': 'JP',
    'japan': 'JP',
    'tokyo': 'JP',
    'токио': 'JP',
    'канада': 'CA',
    'canada': 'CA',
    'украина': 'UA',
    'ukraine': 'UA',
    'киев': 'UA',
    'kyiv': 'UA',
    'норвегия': 'NO',
    'norway': 'NO',
    'дания': 'DK',
    'denmark': 'DK',
    'болгария': 'BG',
    'bulgaria': 'BG',
    'румыния': 'RO',
    'romania': 'RO',
    'венгрия': 'HU',
    'hungary': 'HU',
    'греция': 'GR',
    'greece': 'GR',
    'израиль': 'IL',
    'israel': 'IL',
    'оаэ': 'AE',
    'uae': 'AE',
    'дубай': 'AE',
    'dubai': 'AE',

    // 🇪🇺 Евросоюз / Белые списки (БС)
    'европа': 'EU',
    'евросоюз': 'EU',
    'europe': 'EU',
    'бс': 'EU',
    'белые списки': 'EU',
  };

  /// Извлекает 2-буквенный код страны из тега/названия.
  static String detect(String tag) {
    final trimmed = tag.trim();

    // 1. Поиск эмодзи флагов
    for (final entry in _flagMap.entries) {
      if (trimmed.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2. Проверка 3-буквенного префикса вида "AUT-01", "LVA_02"
    final prefix3Match = RegExp(r'^([A-Za-z]{3})[-_0-9\s]').firstMatch(trimmed);
    if (prefix3Match != null) {
      final code3 = prefix3Match.group(1)!.toUpperCase();
      if (_iso3Map.containsKey(code3)) {
        return _iso3Map[code3]!;
      }
    }

    // 3. Проверка 2-буквенного префикса вида "NL-1", "DE_02", "AT-01"
    final prefixMatch = RegExp(r'^([A-Za-z]{2})[-_0-9\s]').firstMatch(trimmed);
    if (prefixMatch != null) {
      final code = prefixMatch.group(1)!.toUpperCase();
      if (_flagMap.values.contains(code)) {
        return code;
      }
    }

    // 4. Проверка кодов в скобках [LV], (LV), [LVA], (AUT)
    final bracketMatch = RegExp(r'[\[\(]([A-Za-z]{2,3})[\]\)]').firstMatch(trimmed);
    if (bracketMatch != null) {
      final code = bracketMatch.group(1)!.toUpperCase();
      if (code.length == 2 && _flagMap.values.contains(code)) {
        return code;
      }
      if (code.length == 3 && _iso3Map.containsKey(code)) {
        return _iso3Map[code]!;
      }
    }

    // 5. Поиск по ключевым словам городов и стран (без учета регистра)
    final lower = trimmed.toLowerCase();
    for (final entry in _textMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 6. Фолбэк: если точное совпадение с ISO-2 или ISO-3
    final upper = trimmed.toUpperCase();
    if (upper.length == 2 && _flagMap.values.contains(upper)) {
      return upper;
    }
    if (upper.length == 3 && _iso3Map.containsKey(upper)) {
      return _iso3Map[upper]!;
    }

    return 'UN';
  }

  /// Очищает название сервера от эмодзи-флагов, маркеров 📍, лишних скобок и дублирующих протоколов.
  static String cleanServerName(String raw) {
    if (raw.isEmpty) return 'Авто-выбор';
    var text = raw;

    // 1. Отрезаем декораторы агрегатора после символа | (например: " | 🧀", " | 🍺", " | 🧿", " | 🌐")
    if (text.contains('|')) {
      text = text.split('|').first;
    }

    // 2. Удаляем флаги из _flagMap (включая 🇪🇺)
    for (final flag in _flagMap.keys) {
      text = text.replaceAll(flag, ' ');
    }

    // 3. Удаляем любые Unicode Regional Indicator Symbols (эмодзи флагов \u{1F1E6}-\u{1F1FF}) с unicode: true!
    text = text.replaceAll(RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true), ' ');

    // 4. Удаляем маркеры 📍, 🚩, ⚡, ✨, 🌍, 🌐, 🔍, 📌 строго с unicode: true (предотвращает распил UTF-16 суррогатов)
    text = text.replaceAll(
      RegExp(r'[\u{1F4CD}\u{1F6A9}\u{26A1}\u{2728}\u{1F30D}\u{1F310}\u{1F50D}\u{1F4CC}]', unicode: true),
      ' ',
    );

    // 5. Удаляем любые оставшиеся emoji-символы, чтобы шрифт PixCyrillic не ломал глифы в ромбики с ?
    text = text.replaceAll(
      RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true),
      ' ',
    );

    // 6. Удаляем любые повреждённые висячие суррогаты (U+D800..U+DFFF) и символ замены U+FFFD (ромбик )
    text = text.replaceAll(RegExp(r'[\uD800-\uDFFF\uFFFD]'), '');

    // 7. Удаляем дублирующие квадратные скобки с протоколами: [VLESS], [Reality], [VLESS Reality] и т.п.
    text = text.replaceAll(
      RegExp(r'\[(VLESS|VMess|Trojan|Shadowsocks|Hysteria\s*2?|TUIC|Reality|Auto)[\s·•\-_/]*.*?\]', caseSensitive: false),
      ' ',
    );

    // 8. Удаляем круглые скобки с протоколами
    text = text.replaceAll(
      RegExp(r'\((VLESS|VMess|Trojan|Shadowsocks|Hysteria\s*2?|TUIC|Reality|Auto)[\s·•\-_/]*.*?\)', caseSensitive: false),
      ' ',
    );

    // 9. Нормализуем пробелы и спецсимволы по краям
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text.replaceAll(RegExp(r'^[·•\-–—|/]+\s*'), '').trim();
    text = text.replaceAll(RegExp(r'\s*[·•\-–—|/]+$'), '').trim();

    return text.isEmpty ? 'Авто-выбор' : text;
  }
}
