import 'package:flutter_test/flutter_test.dart';
import 'package:measurebox/services/vibration_service.dart';

void main() {
  group('VibrationService.computeMagnitude', () {
    test('device at rest (gravity already excluded) reads ~0', () {
      expect(VibrationService.computeMagnitude(0, 0, 0), 0.0);
    });

    test('single-axis movement returns that axis value', () {
      expect(VibrationService.computeMagnitude(3.0, 0, 0), 3.0);
      expect(VibrationService.computeMagnitude(0, -4.0, 0), 4.0);
    });

    test('classic 3-4-5 right triangle magnitude', () {
      expect(VibrationService.computeMagnitude(3.0, 4.0, 0), 5.0);
    });

    test('is independent of the sign of each axis (uses squares)', () {
      final positive = VibrationService.computeMagnitude(1.0, 2.0, 2.0);
      final negative = VibrationService.computeMagnitude(-1.0, -2.0, -2.0);
      expect(positive, negative);
      expect(positive, 3.0);
    });

    test('combines all three axes via Euclidean norm', () {
      // 2^2 + 3^2 + 6^2 = 4 + 9 + 36 = 49 -> sqrt(49) = 7
      expect(VibrationService.computeMagnitude(2.0, 3.0, 6.0), 7.0);
    });
  });
}
