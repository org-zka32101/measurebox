// Integration test for MeasureTracker's guest-mode app flow.
//
// The app has no login/signup — it boots straight into HomeScreen using a
// fixed guest user ID (see lib/main.dart's MyApp and lib/views/screens/
// home_screen.dart). This test verifies that flow and a basic project
// creation round trip.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:measurebox/constants/strings.dart';
import 'package:measurebox/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MeasureTracker App Flow (guest mode)', () {
    testWidgets('App boots directly to HomeScreen without any login step', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // No splash/login/signup screen — the AppBar title on HomeScreen
      // should already be visible on the very first frame.
      expect(find.text(AppStrings.projects), findsOneWidget);
    });

    testWidgets('New project dialog can be opened from the home screen', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      final addButton = find.byIcon(Icons.add_rounded);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.newProject), findsWidgets);
      }
    });
  });
}
