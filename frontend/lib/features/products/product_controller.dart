import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../../data/repositories/data_revision.dart';
import '../../data/repositories/product_repository.dart';

final productSearchTermProvider =
    NotifierProvider.autoDispose<ProductSearchTerm, String>(
      ProductSearchTerm.new,
    );

class ProductSearchTerm extends Notifier<String> {
  @override
  String build() => '';

  void update(String term) => state = term;
}

final productListProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  ref.watch(dataRevisionProvider);
  final term = ref.watch(productSearchTermProvider);

  return ref.watch(productRepositoryProvider).search(term: term);
});

final lowStockProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) {
  ref.watch(dataRevisionProvider);
  return ref.watch(productRepositoryProvider).lowStock();
});

final productByIdProvider = FutureProvider.autoDispose.family<Product?, String>(
  (ref, productId) {
    ref.watch(dataRevisionProvider);
    return ref.watch(productRepositoryProvider).find(productId);
  },
);

final productCountProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.watch(productRepositoryProvider).count();
});
