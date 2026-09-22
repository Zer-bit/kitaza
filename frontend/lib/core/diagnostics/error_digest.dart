/// Shapes a raw error into something small, stable and safe to keep.
abstract final class ErrorDigest {
  static const int maxMessageLength = 500;
  static const int maxStackLines = 40;
  static const int _framesInFingerprint = 5;

  static String message(Object error) {
    final text = error.toString().trim();
    return text.length <= maxMessageLength
        ? text
        : '${text.substring(0, maxMessageLength)}…';
  }

  static String? stack(StackTrace? trace) {
    if (trace == null) return null;
    final lines = trace.toString().trim().split('\n');
    return lines.take(maxStackLines).join('\n');
  }

  /// Identifies "the same bug" across occurrences: the error type plus the
  /// first few frames of the app's own code. Two crashes in the same place
  /// share a fingerprint and are counted rather than stored twice.
  static String fingerprint(Object error, StackTrace? trace) {
    final frames = (trace?.toString() ?? '').split('\n');
    final ours = frames.where((frame) => frame.contains('package:kitaza_app/'));
    final chosen = (ours.isNotEmpty ? ours : frames).take(_framesInFingerprint);
    // Frame numbers (#0, #1...) shift with async gaps and say nothing about
    // where the error is, so they are dropped.
    final location = chosen
        .map((frame) => frame.replaceFirst(RegExp(r'^#\d+\s+'), '').trim())
        .join('|');
    return _fnv1a('${error.runtimeType}|$location');
  }

  /// FNV-1a over 32 bits: stable across runs and platforms, unlike
  /// `String.hashCode`, and within the integer range the web supports.
  static String _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
