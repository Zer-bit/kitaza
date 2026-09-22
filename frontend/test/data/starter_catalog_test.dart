import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/catalog/starter_catalog.dart';

void main() {
  const items = StarterCatalog.items;

  test('offers about twenty everyday items', () {
    expect(items.length, inInclusiveRange(18, 30));
  });

  test('never suggests selling at a loss', () {
    for (final item in items) {
      expect(item.price, greaterThan(item.cost), reason: item.english);
    }
  });

  test('has a distinct name for every item in both languages', () {
    expect(items.map((item) => item.english).toSet(), hasLength(items.length));
    expect(items.map((item) => item.filipino).toSet(), hasLength(items.length));
  });

  test('uses the Filipino name for a Filipino store', () {
    final eggs = items.firstWhere((item) => item.english.startsWith('Eggs'));
    expect(eggs.nameFor('fil'), 'Itlog (bawat isa)');
    expect(eggs.nameFor('en'), 'Eggs (per piece)');
  });

  test('suggests no tobacco', () {
    for (final item in items) {
      expect(
        item.english.toLowerCase(),
        isNot(
          anyOf(contains('cigarette'), contains('tobacco'), contains('vape')),
        ),
      );
    }
  });
}
