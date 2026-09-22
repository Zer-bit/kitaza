/// Shows a stock quantity exactly as stored: "12" for whole units, "2.5" for
/// goods sold by weight, never rounded.
///
/// Rounding matters more than it looks. The product editor pre-fills the
/// count, and saving records whatever is in the field as a stock count - so a
/// 2.5kg sack displayed as "3" would silently become three.
abstract final class QuantityFormatter {
  static String exact(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();

    // Quantities are stored to three decimal places.
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
