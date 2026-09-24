import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/storage/preferences_store.dart';
import 'package:kitaza_app/core/utils/keep_for.dart';
import 'package:kitaza_app/data/repositories/store_scope.dart';
import 'package:kitaza_app/shared/widgets/async_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/localized.dart';

/// One store's takings, as a screen would load them.
class Takings {
  const Takings(this.store, this.amount);

  final String store;
  final int amount;
}

/// Bumped to stand in for a sale being recorded.
final revision = NotifierProvider<Revision, int>(Revision.new);

class Revision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

/// Loads slowly enough that the time between asking and answering shows.
const loadTime = Duration(milliseconds: 200);

final takingsProvider = FutureProvider.autoDispose<Takings>((ref) async {
  ref.keepFor(tabDataLifetime);
  final store = ref.watch(activeStoreIdProvider);
  final extra = ref.watch(revision);
  await Future<void>.delayed(loadTime);
  return Takings(store, 1000 + extra);
});

/// Stands in for a tab: shown or not, like a screen the owner moves away
/// from and back to.
final showTab = NotifierProvider<ShowTab, bool>(ShowTab.new);

class ShowTab extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool value) => state = value;
}

class TakingsScreen extends ConsumerWidget {
  const TakingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(showTab)) return const Text('another tab');
    return AsyncContent<Takings>(
      value: ref.watch(takingsProvider),
      builder: (takings) => ListView(
        children: [
          Text('${takings.store}: ${takings.amount}'),
          for (var row = 0; row < 60; row++)
            SizedBox(height: 40, child: Text('row $row')),
        ],
      ),
    );
  }
}

void main() {
  late ProviderContainer container;

  /// The screen inside a ProviderScope that is disposed with the widget tree,
  /// as in the app, which is also what cancels the keep-alive timers.
  Future<void> mount(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'kitaza.active_store_id': 'Nena'});
    final preferences = PreferencesStore(await SharedPreferences.getInstance());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesStoreProvider.overrideWithValue(preferences)],
        child: localized(const Scaffold(body: TakingsScreen())),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await mount(tester);
    await tester.pump(loadTime);
    await tester.pumpAndSettle();
  }

  Finder spinner() => find.byType(CircularProgressIndicator);

  testWidgets('the first load shows a spinner, then the figures', (
    tester,
  ) async {
    await mount(tester);

    expect(spinner(), findsOneWidget);
    await tester.pump(loadTime);
    await tester.pumpAndSettle();
    expect(find.text('Nena: 1000'), findsOneWidget);
  });

  testWidgets('a new sale updates the figures in place, with no spinner', (
    tester,
  ) async {
    await open(tester);

    container.read(revision.notifier).bump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(spinner(), findsNothing, reason: 'the screen must not blink');
    expect(find.text('Nena: 1000'), findsOneWidget, reason: 'old until new');

    await tester.pump(loadTime);
    await tester.pumpAndSettle();
    expect(find.text('Nena: 1001'), findsOneWidget);
  });

  testWidgets('and the owner keeps their place in a long list', (tester) async {
    await open(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    final scrolledTo = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(scrolledTo, greaterThan(0));

    container.read(revision.notifier).bump();
    await tester.pump();
    await tester.pump(loadTime);
    await tester.pumpAndSettle();

    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      scrolledTo,
      reason: 'updating in place must not cost the owner their place',
    );
  });

  testWidgets('another store never shows the last store\'s figures', (
    tester,
  ) async {
    await open(tester);

    container.read(activeStoreIdProvider.notifier).select('Carinderia');

    // Every frame until the new store's figures arrive.
    for (var elapsed = 0; elapsed < 260; elapsed += 20) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        find.textContaining('Nena:'),
        findsNothing,
        reason: 'at ${elapsed}ms the Carinderia would show Nena\'s takings',
      );
    }
    await tester.pumpAndSettle();
    expect(find.text('Carinderia: 1000'), findsOneWidget);
  });

  group('coming back to a tab', () {
    testWidgets('opens with its figures already there', (tester) async {
      await open(tester);

      container.read(showTab.notifier).set(false);
      await tester.pumpAndSettle();
      container.read(showTab.notifier).set(true);
      await tester.pump();

      expect(spinner(), findsNothing);
      expect(find.text('Nena: 1000'), findsOneWidget);
    });

    testWidgets('after a change while it was away, shows the new figures', (
      tester,
    ) async {
      // Riverpod forgets a result that changed while nobody was watching,
      // so this one loads afresh - a short spinner, as before. The tab the
      // owner records sales from stays open underneath the sale screen, so
      // it is updated in place and never gets here.
      await open(tester);

      container.read(showTab.notifier).set(false);
      await tester.pumpAndSettle();
      container.read(revision.notifier).bump(); // a sale on another tab
      container.read(showTab.notifier).set(true);
      await tester.pump();

      expect(
        find.text('Nena: 1000'),
        findsNothing,
        reason: 'figures from before the sale are never shown as current',
      );
      await tester.pump(loadTime);
      await tester.pumpAndSettle();
      expect(find.text('Nena: 1001'), findsOneWidget);
    });

    testWidgets('but not with another store\'s, if the store changed', (
      tester,
    ) async {
      await open(tester);

      container.read(showTab.notifier).set(false);
      await tester.pumpAndSettle();
      container.read(activeStoreIdProvider.notifier).select('Carinderia');
      container.read(showTab.notifier).set(true);
      await tester.pump();

      expect(find.textContaining('Nena:'), findsNothing);
      await tester.pump(loadTime);
      await tester.pumpAndSettle();
      expect(find.text('Carinderia: 1000'), findsOneWidget);
    });

    testWidgets('is let go after a while, rather than held forever', (
      tester,
    ) async {
      await open(tester);

      container.read(showTab.notifier).set(false);
      await tester.pumpAndSettle();
      await tester.pump(tabDataLifetime + const Duration(seconds: 1));
      container.read(showTab.notifier).set(true);
      await tester.pump();

      expect(spinner(), findsOneWidget, reason: 'loaded afresh');
      await tester.pump(loadTime);
      await tester.pumpAndSettle();
    });
  });
}
