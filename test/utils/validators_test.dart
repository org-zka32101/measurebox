import 'package:flutter_test/flutter_test.dart';

class Validators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidProjectName(String name) {
    return name.isNotEmpty && name.length <= 50;
  }
}

void main() {
  group('Validators', () {
    group('isValidEmail', () {
      test('valid email addresses', () {
        expect(Validators.isValidEmail('user@example.com'), true);
        expect(Validators.isValidEmail('test.email@domain.co.jp'), true);
        expect(Validators.isValidEmail('a@b.com'), true);
      });

      test('invalid email addresses', () {
        expect(Validators.isValidEmail('invalid'), false);
        expect(Validators.isValidEmail('invalid@'), false);
        expect(Validators.isValidEmail('@example.com'), false);
        expect(Validators.isValidEmail('user@.com'), false);
        expect(Validators.isValidEmail('user @example.com'), false);
      });

      test('empty email', () {
        expect(Validators.isValidEmail(''), false);
      });
    });

    group('isValidPassword', () {
      test('valid passwords', () {
        expect(Validators.isValidPassword('123456'), true);
        expect(Validators.isValidPassword('password123'), true);
        expect(Validators.isValidPassword('a' * 20), true);
      });

      test('invalid passwords (too short)', () {
        expect(Validators.isValidPassword(''), false);
        expect(Validators.isValidPassword('12345'), false);
        expect(Validators.isValidPassword('abc'), false);
      });

      test('password with 6 characters (boundary)', () {
        expect(Validators.isValidPassword('abc123'), true);
      });
    });

    group('isValidProjectName', () {
      test('valid project names', () {
        expect(Validators.isValidProjectName('My Project'), true);
        expect(Validators.isValidProjectName('防音対策'), true);
        expect(Validators.isValidProjectName('a'), true);
      });

      test('invalid project names', () {
        expect(Validators.isValidProjectName(''), false);
        expect(Validators.isValidProjectName('x' * 51), false);
      });

      test('project name with 50 characters (boundary)', () {
        expect(Validators.isValidProjectName('x' * 50), true);
      });
    });
  });
}
