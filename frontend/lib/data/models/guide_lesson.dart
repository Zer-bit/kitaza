import 'package:flutter/material.dart';

import '../../app/route_paths.dart';
import 'access_grant.dart';

/// One lesson in the guide, in the order someone new should read them.
///
/// The text lives in the translations, not here: a lesson knows only what it
/// is about, what the reader needs to be allowed to do to see it, and which
/// screen it is teaching, so the lesson can offer to open it.
///
/// A lesson is shown only to someone who could use what it teaches. Teaching
/// a cashier to export the books, on a phone with no export button, would
/// read as the app being broken.
enum GuideLesson {
  firstDay(icon: Icons.wb_twilight_outlined, stepCount: 4),
  recordingSales(
    icon: Icons.point_of_sale_outlined,
    stepCount: 5,
    opens: RoutePaths.recordSale,
  ),
  whatYouSell(
    icon: Icons.inventory_2_outlined,
    stepCount: 5,
    opens: RoutePaths.products,
    needs: Permission.manageProducts,
  ),
  moneyGoingOut(
    icon: Icons.south_east_outlined,
    stepCount: 4,
    opens: RoutePaths.recordExpense,
    needs: Permission.recordExpenses,
  ),
  readingYourNumbers(
    icon: Icons.assessment_outlined,
    stepCount: 4,
    opens: RoutePaths.dashboard,
  ),
  whatKitazaSuggests(
    icon: Icons.lightbulb_outline,
    stepCount: 4,
    opens: RoutePaths.reports,
    needs: Permission.viewProfit,
  ),
  keepingRecordsSafe(
    icon: Icons.shield_outlined,
    stepCount: 4,
    opens: RoutePaths.settings,
    ownerOnly: true,
  ),
  yourHelpers(
    icon: Icons.groups_outlined,
    stepCount: 4,
    opens: RoutePaths.staff,
    ownerOnly: true,
  );

  const GuideLesson({
    required this.icon,
    required this.stepCount,
    this.opens,
    this.needs,
    this.ownerOnly = false,
  });

  final IconData icon;
  final int stepCount;

  /// The screen this lesson teaches, offered at the end of it.
  final String? opens;

  final Permission? needs;
  final bool ownerOnly;

  /// Where this lesson lives. Named in the path rather than numbered, so a
  /// link still points at the same lesson after the order changes.
  String get path => '${RoutePaths.guide}/$name';

  /// Lessons about things this person cannot do are left out rather than
  /// shown and then refused.
  bool isFor(AccessGrant access) {
    if (ownerOnly && !access.isOwner) return false;
    return needs == null || access.can(needs!);
  }

  /// The lesson a path names, or null for a link to one that no longer
  /// exists.
  static GuideLesson? named(String? name) {
    for (final lesson in values) {
      if (lesson.name == name) return lesson;
    }
    return null;
  }

  static List<GuideLesson> forReader(AccessGrant access) =>
      values.where((lesson) => lesson.isFor(access)).toList(growable: false);

  GuideLesson? nextFor(AccessGrant access) {
    final visible = forReader(access);
    final position = visible.indexOf(this);
    return position < 0 || position + 1 >= visible.length
        ? null
        : visible[position + 1];
  }
}

/// One numbered instruction: what to do, and why it is worth doing.
class GuideStep {
  const GuideStep({required this.title, required this.body});

  final String title;
  final String body;
}
