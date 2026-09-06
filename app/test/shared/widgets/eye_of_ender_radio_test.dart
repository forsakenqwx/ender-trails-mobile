import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ender_trails/shared/design_system/widgets/eye_of_ender_radio.dart';

void main() {
  group('EyeOfEnderRadio tests', () {
    testWidgets('renders socket in unselected state without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EyeOfEnderRadio(selected: false),
            ),
          ),
        ),
      );

      expect(find.byType(EyeOfEnderRadio), findsOneWidget);
    });

    testWidgets('renders EyeOfEnder and animates on selected: true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EyeOfEnderRadio(selected: true),
            ),
          ),
        ),
      );

      // EyeOfEnderPainter should be rendered
      expect(find.byType(CustomPaint), findsWidgets);

      // Pump through animation
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byType(EyeOfEnderRadio), findsOneWidget);
    });

    testWidgets('handles selection transitions smoothly', (tester) async {
      bool selected = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: GestureDetector(
                  onTap: () => setState(() => selected = !selected),
                  child: EyeOfEnderRadio(selected: selected),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(EyeOfEnderRadio), findsOneWidget);

      // Tap to trigger selection
      await tester.tap(find.byType(EyeOfEnderRadio));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(EyeOfEnderRadio), findsOneWidget);
    });
  });
}
