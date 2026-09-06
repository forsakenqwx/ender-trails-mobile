import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ender_trails/shared/design_system/widgets/minecraft_flag.dart';

void main() {
  group('MinecraftFlag', () {
    testWidgets('renders CustomPaint with correct country codes', (tester) async {
      const testCodes = [
        'NL', 'DE', 'FI', 'SE', 'KZ', 'RU', 'US', 'GB', 'UK',
        'FR', 'PL', 'EE', 'CH', 'SG', 'AT', 'AUT',
        'LV', 'LVA', 'IT', 'ITA', 'LT', 'LTU', 'CZ', 'CZE',
        'IE', 'IRL', 'BE', 'BEL', 'ES', 'ESP', 'HK', 'HKG',
        'BR', 'BRA', 'TR', 'TUR', 'JP', 'JPN', 'CA', 'CAN',
        'UA', 'UKR', 'NO', 'NOR', 'DK', 'DNK', 'AUTO', 'UNKNOWN'
      ];

      for (final code in testCodes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: MinecraftFlag(
                  countryCode: code,
                  width: 44,
                  height: 30,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(MinecraftFlag), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      }
    });

    test('MinecraftFlagPainter repaints when countryCode changes', () {
      const painter1 = MinecraftFlagPainter(countryCode: 'NL');
      const painter2 = MinecraftFlagPainter(countryCode: 'DE');
      const painter3 = MinecraftFlagPainter(countryCode: 'NL');

      expect(painter1.shouldRepaint(painter2), isTrue);
      expect(painter1.shouldRepaint(painter3), isFalse);
    });
  });
}
