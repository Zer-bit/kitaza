/// One suggested product for a new store.
class StarterItem {
  const StarterItem({
    required this.english,
    required this.filipino,
    required this.cost,
    required this.price,
    this.unit = 'pc',
  });

  /// Brand names read the same in both languages; generic goods do not.
  final String english;
  final String filipino;
  final double cost;
  final double price;
  final String unit;

  String nameFor(String languageCode) =>
      languageCode == 'fil' ? filipino : english;
}

/// Goods almost every sari-sari store carries, so a new store's catalogue is
/// not empty on day one.
///
/// The prices are typical Metro Manila retail as of 2026 and will be wrong for
/// plenty of stores. They are offered for review, never added silently: a
/// wrong cost price quietly distorts every profit figure the app shows.
/// Tobacco is deliberately absent.
abstract final class StarterCatalog {
  static const List<StarterItem> items = [
    StarterItem(
      english: 'Coke Mismo 295ml',
      filipino: 'Coke Mismo 295ml',
      cost: 17,
      price: 20,
    ),
    StarterItem(
      english: 'Royal Mismo 295ml',
      filipino: 'Royal Mismo 295ml',
      cost: 17,
      price: 20,
    ),
    StarterItem(
      english: 'Bottled water 500ml',
      filipino: 'Tubig 500ml',
      cost: 10,
      price: 15,
    ),
    StarterItem(
      english: 'Lucky Me! Pancit Canton',
      filipino: 'Lucky Me! Pancit Canton',
      cost: 16,
      price: 19,
    ),
    StarterItem(
      english: 'Lucky Me! Beef Mami',
      filipino: 'Lucky Me! Beef Mami',
      cost: 12,
      price: 15,
    ),
    StarterItem(
      english: 'Argentina Corned Beef 150g',
      filipino: 'Argentina Corned Beef 150g',
      cost: 33,
      price: 38,
    ),
    StarterItem(
      english: '555 Sardines 155g',
      filipino: '555 Sardinas 155g',
      cost: 22,
      price: 26,
    ),
    StarterItem(
      english: 'Century Tuna Flakes 155g',
      filipino: 'Century Tuna Flakes 155g',
      cost: 36,
      price: 42,
    ),
    StarterItem(
      english: 'Kopiko Brown 3-in-1',
      filipino: 'Kopiko Brown 3-in-1',
      cost: 8,
      price: 10,
    ),
    StarterItem(
      english: 'Milo sachet 24g',
      filipino: 'Milo sachet 24g',
      cost: 9,
      price: 11,
    ),
    StarterItem(
      english: 'Bear Brand Swak 33g',
      filipino: 'Bear Brand Swak 33g',
      cost: 13,
      price: 15,
    ),
    StarterItem(
      english: 'SkyFlakes (single pack)',
      filipino: 'SkyFlakes (isang pack)',
      cost: 7,
      price: 9,
    ),
    StarterItem(
      english: 'Eggs (per piece)',
      filipino: 'Itlog (bawat isa)',
      cost: 8,
      price: 10,
    ),
    StarterItem(
      english: 'Rice (per kilo)',
      filipino: 'Bigas (bawat kilo)',
      cost: 48,
      price: 55,
      unit: 'kg',
    ),
    StarterItem(
      english: 'Sugar (1/4 kilo)',
      filipino: 'Asukal (1/4 kilo)',
      cost: 20,
      price: 24,
    ),
    StarterItem(
      english: 'Cooking oil (1/4 liter)',
      filipino: 'Mantika (1/4 litro)',
      cost: 22,
      price: 26,
    ),
    StarterItem(
      english: 'Salt (1/4 kilo)',
      filipino: 'Asin (1/4 kilo)',
      cost: 8,
      price: 10,
    ),
    StarterItem(
      english: 'Soy sauce (sachet)',
      filipino: 'Toyo (sachet)',
      cost: 8,
      price: 10,
    ),
    StarterItem(
      english: 'Vinegar (sachet)',
      filipino: 'Suka (sachet)',
      cost: 8,
      price: 10,
    ),
    StarterItem(
      english: 'Shampoo (sachet)',
      filipino: 'Shampoo (sachet)',
      cost: 6,
      price: 8,
    ),
    StarterItem(
      english: 'Laundry powder (sachet)',
      filipino: 'Sabong panlaba (sachet)',
      cost: 8,
      price: 10,
    ),
    StarterItem(
      english: 'Bath soap (bar)',
      filipino: 'Sabong pampaligo',
      cost: 38,
      price: 44,
    ),
    StarterItem(
      english: 'Candy (per piece)',
      filipino: 'Kendi (bawat isa)',
      cost: 0.7,
      price: 1,
    ),
  ];
}
