import '../core/formatting/peso_formatter.dart';
import '../core/formatting/quantity_formatter.dart';
import '../data/models/access_grant.dart';
import '../data/models/activity_event.dart';
import '../data/models/expense_category.dart';
import 'generated/app_localizations.dart';
import 'model_labels.dart';

extension ActivityText on AppLocalizations {
  /// One line of the activity log, in the owner's language. The server only
  /// sends what happened and the figures; the wording is made here.
  String activitySentence(ActivityEvent event) {
    final name = event.actorName;
    String money(String key) => PesoFormatter.format(event.amount(key));
    String quantity(String key) => QuantityFormatter.exact(event.amount(key));
    String product() => displayProductName(event.text('name'));
    String category() =>
        expenseCategory(ExpenseCategory.parse(event.text('category')));

    return switch (event.action) {
      ActivityAction.saleRecorded => activitySaleRecorded(name, money('total')),
      ActivityAction.saleVoided => activitySaleVoided(name, money('total')),
      ActivityAction.expenseRecorded => activityExpenseRecorded(
        name,
        money('amount'),
        category(),
      ),
      ActivityAction.expenseDeleted => activityExpenseDeleted(
        name,
        money('amount'),
        category(),
      ),
      ActivityAction.withdrawalRecorded => activityWithdrawalRecorded(
        name,
        money('amount'),
      ),
      ActivityAction.withdrawalDeleted => activityWithdrawalDeleted(
        name,
        money('amount'),
      ),
      ActivityAction.productAdded => activityProductAdded(
        name,
        product(),
        money('selling_price'),
      ),
      ActivityAction.productChanged => activityProductChanged(name, product()),
      ActivityAction.productRemoved => activityProductRemoved(name, product()),
      ActivityAction.stockReceived => activityStockReceived(
        name,
        quantity('quantity'),
        product(),
      ),
      ActivityAction.stockRemoved => activityStockRemoved(
        name,
        quantity('quantity'),
        product(),
      ),
      ActivityAction.stockCounted => activityStockCounted(
        name,
        quantity('counted'),
        product(),
      ),
      ActivityAction.stockSpoiled => activityStockSpoiled(
        name,
        quantity('quantity'),
        product(),
      ),
      ActivityAction.staffAdded => activityStaffAdded(name, event.text('name')),
      ActivityAction.staffChanged => activityStaffChanged(
        name,
        event.text('name'),
      ),
      ActivityAction.staffRemoved => activityStaffRemoved(
        name,
        event.text('name'),
      ),
      ActivityAction.staffInvited => activityStaffInvited(
        name,
        event.text('name'),
      ),
      ActivityAction.staffJoined => activityStaffJoined(
        name,
        event.text('device'),
      ),
      ActivityAction.deviceSignedOut => activityDeviceSignedOut(
        name,
        event.text('name'),
        event.text('device'),
      ),
      ActivityAction.storeAdded => activityStoreAdded(name, event.text('name')),
      ActivityAction.storeRenamed => activityStoreRenamed(
        name,
        event.text('old_name'),
        event.text('name'),
      ),
      ActivityAction.subscriptionPaid => activitySubscriptionPaid(
        name,
        money('amount'),
        event.text('plan') == 'basic' ? planBasic : planPro,
      ),
      ActivityAction.other => activityOther(name),
    };
  }

  /// A second line where the sentence alone leaves out what matters: which
  /// price changed, how far a count was off, what a staff member may do.
  String? activityDetail(ActivityEvent event) {
    switch (event.action) {
      case ActivityAction.productChanged:
        final changes = (event.details['changes'] as Map?) ?? const {};
        String? pair(String key, String Function(String, String) phrase) {
          final values = changes[key];
          if (values is! List || values.length != 2) return null;
          return phrase(
            PesoFormatter.format((values[0] as num).toDouble()),
            PesoFormatter.format((values[1] as num).toDouble()),
          );
        }

        final lines = [
          ?pair('selling_price', activityPriceChange),
          ?pair('cost_price', activityCostChange),
          if (changes['name'] case [final String before, _])
            activityRenamedFrom(before),
        ];
        return lines.isEmpty ? null : lines.join('\n');
      case ActivityAction.stockCounted:
        final change = event.amount('change');
        if (change == 0) return null;
        final signed = change > 0
            ? '+${QuantityFormatter.exact(change)}'
            : QuantityFormatter.exact(change);
        return activityStockDifference(signed);
      case ActivityAction.staffAdded || ActivityAction.staffChanged:
        final granted = {
          for (final raw in (event.details['permissions'] as List?) ?? const [])
            ?Permission.parse(raw as String),
        };
        return staffAbilities(granted);
      default:
        return null;
    }
  }

  /// "Sells, products, profit": what a staff member may do, in brief.
  String staffAbilities(Set<Permission> permissions) => [
    staffSells,
    for (final permission in Permission.values)
      if (permissions.contains(permission)) staffPermissionShort(permission),
  ].join(', ');

  String staffPermissionShort(Permission permission) => switch (permission) {
    Permission.manageProducts => staffShortProducts,
    Permission.recordExpenses => staffShortExpenses,
    Permission.viewProfit => staffShortProfit,
    Permission.deleteRecords => staffShortDelete,
  };

  String permissionTitle(Permission permission) => switch (permission) {
    Permission.manageProducts => permissionManageProducts,
    Permission.recordExpenses => permissionRecordExpenses,
    Permission.viewProfit => permissionViewProfit,
    Permission.deleteRecords => permissionDeleteRecords,
  };

  String permissionHint(Permission permission) => switch (permission) {
    Permission.manageProducts => permissionManageProductsHint,
    Permission.recordExpenses => permissionRecordExpensesHint,
    Permission.viewProfit => permissionViewProfitHint,
    Permission.deleteRecords => permissionDeleteRecordsHint,
  };
}
