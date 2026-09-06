import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ender_trails/app.dart';

void main() {
  testWidgets('EnderTrailsApp smoke test - loads main screen and elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EnderTrailsApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ENDER TRAILS'), findsOneWidget);
    expect(find.text('ЛОКАЦИЯ ТУННЕЛЯ'), findsOneWidget);
    expect(find.text('СЕРВЕРЫ'), findsOneWidget);
  });
}
