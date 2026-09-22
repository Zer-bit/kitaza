import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/formatting/quantity_formatter.dart';

void main() {
  test('whole units show without a decimal point', () {
    expect(QuantityFormatter.exact(12), '12');
    expect(QuantityFormatter.exact(0), '0');
  });

  test('goods sold by weight are never rounded', () {
    expect(QuantityFormatter.exact(2.5), '2.5');
    expect(QuantityFormatter.exact(0.125), '0.125');
    expect(QuantityFormatter.exact(1.25), '1.25');
  });

  test('re-reading a pre-filled count gives back the same number', () {
    for (final stored in [2.5, 0.75, 10.0, 3.333]) {
      expect(double.parse(QuantityFormatter.exact(stored)), stored);
    }
  });
}
