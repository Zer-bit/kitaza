import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/core/localization/locale_controller.dart';
import 'package:kitaza_app/data/models/business_health.dart';
import 'package:kitaza_app/data/repositories/sale_repository.dart';
import 'package:kitaza_app/l10n/l10n.dart';

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholdersIn(String text) =>
    RegExp(r'\{(\w+)[,}]').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  countMessagesShowTheirNumber();

  group('the Filipino translation', () {
    final english = _arb('app_en.arb');
    final filipino = _arb('app_fil.arb');
    final keys = english.keys.where((key) => !key.startsWith('@'));

    test('covers every English string', () {
      final missing = keys.where((key) => !filipino.containsKey(key)).toList();
      expect(missing, isEmpty);
    });

    test(
      'keeps every placeholder, so no amount or name silently disappears',
      () {
        for (final key in keys) {
          expect(
            _placeholdersIn(filipino[key] as String),
            _placeholdersIn(english[key] as String),
            reason: key,
          );
        }
      },
    );
  });

  group('choosing a language from the phone settings', () {
    test('Filipino is recognised under both of its codes', () {
      expect(
        LocaleController.resolve([const Locale('fil')]),
        LocaleController.filipino,
      );
      // Older Android versions report Filipino as Tagalog.
      expect(
        LocaleController.resolve([const Locale('tl')]),
        LocaleController.filipino,
      );
    });

    test('the first supported language in the phone list wins', () {
      expect(
        LocaleController.resolve([
          const Locale('ja'),
          const Locale('fil'),
          const Locale('en'),
        ]),
        LocaleController.filipino,
      );
    });

    test('an unsupported language falls back to English', () {
      expect(
        LocaleController.resolve([const Locale('ja')]),
        LocaleController.english,
      );
      expect(LocaleController.resolve(null), LocaleController.english);
    });
  });

  group('health reasons read naturally in both languages', () {
    final english = lookupAppLocalizations(const Locale('en'));
    final filipino = lookupAppLocalizations(const Locale('fil'));
    const health = BusinessHealth(
      rating: HealthRating.red,
      score: 20,
      reasons: [SpentMoreThanSold(1200), NeedsRestock(1), NeedsRestock(3)],
    );

    test('in English', () {
      expect(english.healthHeadline(health), 'Your store needs attention');
      expect(english.healthReasons(health), [
        'You spent ₱1,200.00 more than you sold.',
        '1 product needs restocking.',
        '3 products need restocking.',
      ]);
    });

    test('in Filipino', () {
      expect(
        filipino.healthHeadline(health),
        'Kailangan ng pansin ang tindahan mo',
      );
      expect(
        filipino.healthReasons(health).first,
        'Mas malaki ng ₱1,200.00 ang gastos mo kaysa sa benta.',
      );
    });

    test('a store with no sales is encouraged, not judged', () {
      expect(
        english.healthHeadline(BusinessHealth.unknown),
        'No sales recorded yet',
      );
      expect(english.healthReasons(BusinessHealth.unknown), hasLength(1));
    });
  });

  test(
    'a keypad sale is shown in the owner\'s language but stored the same way',
    () {
      final filipino = lookupAppLocalizations(const Locale('fil'));

      expect(CartLine.quick(20).productName, CartLine.quickSaleName);
      expect(
        filipino.displayProductName(CartLine.quickSaleName),
        'Mabilisang benta',
      );
      expect(filipino.displayProductName('Coke 290ml'), 'Coke 290ml');
    },
  );
}

/// Every count message, rendered for 1 to 30, must show the real number.
///
/// Guards a bug that shipped once: Filipino grammar files 1, 2, 3, 5, 7, 8,
/// 11, 23... under the same "one" category, so a branch written as "=1{1
/// benta}" showed "1" for most counts.
void countMessagesShowTheirNumber() {
  for (final code in ['en', 'fil']) {
    final l10n = lookupAppLocalizations(Locale(code));
    final messages = <String, String Function(int)>{
      'dashboardSaleCount': l10n.dashboardSaleCount,
      'dashboardLowStock': l10n.dashboardLowStock,
      'healthReasonRestock': l10n.healthReasonRestock,
      'saleItemCount': l10n.saleItemCount,
      'storagePending': l10n.storagePending,
      'storageParked': l10n.storageParked,
      'syncWaiting': l10n.syncWaiting,
      'accountSignOutUnsent': l10n.accountSignOutUnsent,
      'starterAdd': l10n.starterAdd,
      'starterAdded': l10n.starterAdded,
      'sessionEndedUnsent': l10n.sessionEndedUnsent,
      'sessionEndedClearMessage': l10n.sessionEndedClearMessage,
      'staffDevices': l10n.staffDevices,
      'problemsWillRetry': l10n.problemsWillRetry,
      'reportsTitle': l10n.reportsTitle,
      'backupConfirmSummary': (count) =>
          l10n.backupConfirmSummary('Store', count, count),
    };

    // English says "once" rather than "1 time"; the number is still right.
    const spelledOutAtOne = {'problemsWillRetry'};

    if (code == 'en') {
      test('every count message is checked here', () {
        // Filipino groups numbers differently from English, which is how
        // "1 benta" once showed for 3 sales. A new count message must be
        // added to the list above to be checked.
        final plural = _arb('app_en.arb').entries
            .where((entry) => '${entry.value}'.contains(', plural,'))
            .map((entry) => entry.key)
            .toSet();
        expect(messages.keys.toSet(), plural);
      });
    }

    test('$code count messages show the real number', () {
      messages.forEach((key, render) {
        for (var count = 2; count <= 30; count++) {
          expect(
            render(count),
            contains('$count'),
            reason: '$code $key($count)',
          );
        }
        if (code != 'en' || !spelledOutAtOne.contains(key)) {
          expect(render(1), contains('1'), reason: '$code $key(1)');
        }
      });
    });
  }
}
