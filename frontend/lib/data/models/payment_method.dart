/// The ways a Philippine small business actually gets paid. `utang` is credit
/// extended to a regular customer, which is money owed rather than money in.
enum PaymentMethod {
  cash('cash', 'Cash'),
  gcash('gcash', 'GCash'),
  maya('maya', 'Maya'),
  bankTransfer('bank_transfer', 'Bank transfer'),
  utang('utang', 'Utang (credit)');

  const PaymentMethod(this.wireName, this.label);

  final String wireName;
  final String label;

  static PaymentMethod parse(String? raw) => values.firstWhere(
    (method) => method.wireName == raw,
    orElse: () => PaymentMethod.cash,
  );
}
