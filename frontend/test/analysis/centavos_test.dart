import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/formatting/centavos.dart';

void main() {
  group('Centavos', () {
    test('survives a peso round trip without drift', () {
      for (final amount in [0.0, 0.01, 12.34, 999.99, 15250.75]) {
        expect(Centavos.toPesos(Centavos.fromPesos(amount)), amount);
      }
    });

    test('rounds the classic floating point cases correctly', () {
      // 0.1 + 0.2 is 0.30000000000000004 in binary floating point.
      expect(Centavos.fromPesos(0.1 + 0.2), 30);
      expect(Centavos.fromPesos(1.005), 100);
    });

    test('reads JSON numbers whether they arrive as int, double or string', () {
      expect(Centavos.fromJson(12), 1200);
      expect(Centavos.fromJson(12.5), 1250);
      expect(Centavos.fromJson('12.50'), 1250);
      expect(Centavos.fromJson(null), 0);
    });

    test('a hundred small amounts sum exactly', () {
      final total = List.filled(
        100,
        0.07,
      ).map(Centavos.fromPesos).reduce((a, b) => a + b);

      expect(Centavos.toPesos(total), 7.0);
    });
  });
}
