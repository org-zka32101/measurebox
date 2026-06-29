import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:measurebox/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MeasureBox App Integration Tests', () {
    testWidgets('Splash screen loads and navigates to login', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check splash screen is displayed
      expect(find.text('MeasureBox'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for splash screen to disappear
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check login screen appears
      expect(find.text('ログイン'), findsOneWidget);
    });

    testWidgets('Login form validation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for login screen
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Try to submit empty form
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Check error message appears
      expect(find.text('メールアドレスとパスワードを入力してください'), findsOneWidget);
    });

    testWidgets('Email and password input works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for login screen
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and fill email field
      final emailFields = find.byType(TextField);
      await tester.enterText(emailFields.first, 'test@example.com');

      // Find and fill password field
      await tester.enterText(emailFields.at(1), 'password123');

      await tester.pumpAndSettle();

      // Verify input was entered
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Signup link navigates to signup screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for login screen
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap signup link
      final signupLink = find.text('こちらからサインアップ');
      await tester.tap(signupLink);
      await tester.pumpAndSettle();

      // Check signup screen appears
      expect(find.text('サインアップ'), findsOneWidget);
    });

    testWidgets('Signup form has required fields', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for login screen
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap signup link
      final signupLink = find.text('こちらからサインアップ');
      await tester.tap(signupLink);
      await tester.pumpAndSettle();

      // Check for required fields
      expect(find.text('お名前'), findsOneWidget);
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('パスワード（確認）'), findsOneWidget);
    });

    testWidgets('Back button on signup returns to login', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for login screen
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap signup link
      final signupLink = find.text('こちらからサインアップ');
      await tester.tap(signupLink);
      await tester.pumpAndSettle();

      // Find and tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Check login screen appears again
        expect(find.text('ログイン'), findsOneWidget);
      }
    });
  });
}
