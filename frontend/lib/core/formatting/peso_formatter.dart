import 'package:intl/intl.dart';

/// One place that decides how money looks, so a total on the dashboard and the
/// same total on a receipt can never disagree.
abstract final class PesoFormatter {
  static final NumberFormat _withSymbol = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );
  static final NumberFormat _plain = NumberFormat('#,##0.00', 'en_PH');
  static final NumberFormat _compactSymbol = NumberFormat.compactCurrency(
    locale: 'en_PH',
    symbol: '₱',
  );

  static String format(double amount) => _withSymbol.format(amount);

  static String plain(double amount) => _plain.format(amount);

  /// For tight spaces such as chart labels: 12.4K instead of 12,400.00.
  static String compact(double amount) => amount.abs() >= 10000
      ? _compactSymbol.format(amount)
      : _withSymbol.format(amount);

  /// Signed display for anything that can go either way, like cash movement.
  static String signed(double amount) {
    final formatted = format(amount.abs());
    if (amount > 0) return '+$formatted';
    if (amount < 0) return '-$formatted';
    return formatted;
  }
}
