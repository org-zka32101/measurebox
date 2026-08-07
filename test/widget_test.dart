// Basic smoke test for MeasureTracker.
//
// Verifies the app boots (guest mode, straight to HomeScreen per
// lib/main.dart's MyApp) without crashing. Firebase isn't initialized in
// this test environment, so HomeScreen's projectsStreamProvider never
// resolves to data — only the AppBar title (which doesn't depend on the
// stream) is safe to assert on here.

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:measurebox/constants/strings.dart';
import 'package:measurebox/main.dart';

void main() {
  testWidgets('App boots to HomeScreen in guest mode', (WidgetTester tester) async {
    // MyApp is a ConsumerWidget, so it needs a ProviderScope ancestor.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    expect(find.text(AppStrings.projects), findsOneWidget);
  });
}
