import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/payment_method.dart';
import '../../data/models/product.dart';
import '../../data/repositories/sale_repository.dart';

/// The in-progress sale. Lives only as long as the record-sale screen.
class SaleCart extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => const [];

  double get total => state.fold(0, (sum, line) => sum + line.total);

  /// Tapping the same product again bumps its quantity instead of adding a
  /// second row, which is what a cashier expects.
  void addProduct(Product product) {
    final existing = state.indexWhere((line) => line.productId == product.id);

    if (existing >= 0) {
      final updated = [...state];
      updated[existing] = updated[existing].copyWith(
        quantity: updated[existing].quantity + 1,
      );
      state = updated;
      return;
    }

    state = [...state, CartLine.fromProduct(product)];
  }

  void addQuickAmount(double amount) {
    if (amount <= 0) return;
    state = [...state, CartLine.quick(amount)];
  }

  void changeQuantity(String key, double quantity) {
    if (quantity <= 0) {
      remove(key);
      return;
    }

    state = [
      for (final line in state)
        if (line.key == key) line.copyWith(quantity: quantity) else line,
    ];
  }

  void remove(String key) =>
      state = state.where((line) => line.key != key).toList(growable: false);

  void clear() => state = const [];
}

final saleCartProvider = NotifierProvider.autoDispose<SaleCart, List<CartLine>>(
  SaleCart.new,
);

final selectedPaymentMethodProvider =
    NotifierProvider.autoDispose<SelectedPaymentMethod, PaymentMethod>(
      SelectedPaymentMethod.new,
    );

class SelectedPaymentMethod extends Notifier<PaymentMethod> {
  @override
  PaymentMethod build() => PaymentMethod.cash;

  void select(PaymentMethod method) => state = method;
}
