/// The ways a Philippine small business actually gets paid. `utang` is credit
/// extended to a regular customer, which is money owed rather than money in.
enum PaymentMethod {
  cash('cash'),
  gcash('gcash'),
  maya('maya'),
  bankTransfer('bank_transfer'),
  utang('utang');

  const PaymentMethod(this.wireName);

  final String wireName;

  static PaymentMethod parse(String? raw) => values.firstWhere(
    (method) => method.wireName == raw,
    orElse: () => PaymentMethod.cash,
  );
}
