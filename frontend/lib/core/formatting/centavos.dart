/// Money crosses three boundaries in this app: JSON (decimal), SQLite
/// (integer) and the UI (double). Rounding rules live here so the same peso
/// value survives every round trip.
abstract final class Centavos {
  static int fromPesos(double pesos) => (pesos * 100).round();

  static double toPesos(int centavos) => centavos / 100;

  /// JSON numbers arrive as int or double depending on the value.
  static int fromJson(Object? value) => switch (value) {
    final int v => v * 100,
    final double v => (v * 100).round(),
    final String v => fromPesos(double.tryParse(v) ?? 0),
    _ => 0,
  };

  static double readPesos(Object? value) => toPesos(fromJson(value));
}

double readDouble(Object? value) => switch (value) {
  final int v => v.toDouble(),
  final double v => v,
  final String v => double.tryParse(v) ?? 0,
  _ => 0,
};

DateTime readDate(Object? value) => switch (value) {
  final String v => DateTime.tryParse(v)?.toUtc() ?? DateTime.now().toUtc(),
  final int v => DateTime.fromMillisecondsSinceEpoch(v, isUtc: true),
  _ => DateTime.now().toUtc(),
};
