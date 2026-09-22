import 'receipt_layout.dart';

/// Turns receipt lines into ESC/POS, the command language nearly every
/// thermal receipt printer understands.
///
/// Only the handful of commands every printer supports are used: reset,
/// alignment, bold, double height, feed and cut. Printers without a cutter
/// ignore the cut command, so it is always sent.
abstract final class EscPosEncoder {
  static const List<int> reset = [0x1B, 0x40];
  static const List<int> alignLeft = [0x1B, 0x61, 0x00];
  static const List<int> alignCenter = [0x1B, 0x61, 0x01];
  static const List<int> boldOn = [0x1B, 0x45, 0x01];
  static const List<int> boldOff = [0x1B, 0x45, 0x00];
  static const List<int> doubleHeight = [0x1D, 0x21, 0x01];
  static const List<int> normalSize = [0x1D, 0x21, 0x00];
  static const List<int> feedAndCut = [
    0x1B,
    0x64,
    0x04,
    0x1D,
    0x56,
    0x42,
    0x00,
  ];
  static const int lineFeed = 0x0A;

  static List<int> encode(List<ReceiptLine> lines) {
    final bytes = <int>[...reset];

    for (final line in lines) {
      bytes
        ..addAll(line.align == ReceiptAlign.center ? alignCenter : alignLeft)
        ..addAll(line.bold ? boldOn : boldOff)
        ..addAll(line.large ? doubleHeight : normalSize)
        ..addAll(ascii(line.text).codeUnits)
        ..add(lineFeed);
    }

    return bytes
      ..addAll(boldOff)
      ..addAll(normalSize)
      ..addAll(alignLeft)
      ..addAll(feedAndCut);
  }

  static const Map<String, String> _replacements = {
    '₱': 'P',
    'ñ': 'n',
    'Ñ': 'N',
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'Á': 'A',
    'É': 'E',
    'Í': 'I',
    'Ó': 'O',
    'Ú': 'U',
    '·': '-',
    '×': 'x',
    '–': '-',
    '—': '-',
    '…': '...',
    '‘': "'",
    '’': "'",
    '“': '"',
    '”': '"',
  };

  /// Printers use a single-byte character set, so anything outside plain
  /// ASCII is spelled out or replaced. "Niño" prints as "Nino" rather than
  /// as two garbage characters.
  static String ascii(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (rune >= 0x20 && rune < 0x7F) {
        buffer.write(char);
      } else {
        buffer.write(_replacements[char] ?? '?');
      }
    }
    return buffer.toString();
  }
}
