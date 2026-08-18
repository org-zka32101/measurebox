import 'package:flutter_test/flutter_test.dart';
import 'package:measurebox/utils/error_messages.dart';

void main() {
  group('friendlyErrorMessage', () {
    test('maps Firestore permission errors to a friendly message', () {
      final message = friendlyErrorMessage(
        Exception('[cloud_firestore/permission-denied] Missing or insufficient permissions.'),
      );
      expect(message, contains('アクセスが拒否'));
      expect(message, isNot(contains('cloud_firestore')));
    });

    test('maps network-related errors to a friendly message', () {
      expect(friendlyErrorMessage(Exception('SocketException: Failed host lookup')),
          contains('ネットワーク'));
      expect(friendlyErrorMessage(Exception('network unavailable')),
          contains('ネットワーク'));
    });

    test('maps not-found errors to a friendly message', () {
      expect(friendlyErrorMessage(Exception('[cloud_firestore/not-found] No document to update')),
          contains('見つかりません'));
    });

    test('falls back to a generic friendly message for unknown errors', () {
      final message = friendlyErrorMessage(Exception('some completely unrelated internal detail'));
      expect(message, isNot(contains('some completely unrelated internal detail')));
      expect(message, isNotEmpty);
    });
  });
}
