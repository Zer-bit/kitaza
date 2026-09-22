import '../data/models/business_health.dart';
import '../data/models/expense_category.dart';
import '../data/models/payment_method.dart';
import '../data/models/report_period.dart';
import '../data/repositories/sale_repository.dart';
import 'generated/app_localizations.dart';

/// Words for the app's fixed choices. Models carry only the value; the owner's
/// language is decided here, at the edge of the screen.
extension ModelLabels on AppLocalizations {
  String paymentMethod(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => paymentCash,
    PaymentMethod.gcash => paymentGcash,
    PaymentMethod.maya => paymentMaya,
    PaymentMethod.bankTransfer => paymentBankTransfer,
    PaymentMethod.utang => paymentUtang,
  };

  String expenseCategory(ExpenseCategory category) => switch (category) {
    ExpenseCategory.inventory => categoryInventory,
    ExpenseCategory.utilities => categoryUtilities,
    ExpenseCategory.salary => categorySalary,
    ExpenseCategory.transportation => categoryTransportation,
    ExpenseCategory.rent => categoryRent,
    ExpenseCategory.supplies => categorySupplies,
    ExpenseCategory.repairs => categoryRepairs,
    ExpenseCategory.taxesPermits => categoryTaxesPermits,
    ExpenseCategory.other => categoryOther,
  };

  String reportPeriod(ReportPeriod period) => switch (period) {
    ReportPeriod.today => periodToday,
    ReportPeriod.week => periodWeek,
    ReportPeriod.month => periodMonth,
  };

  String healthRating(HealthRating rating) => switch (rating) {
    HealthRating.green => healthGood,
    HealthRating.yellow => healthAverage,
    HealthRating.red => healthWarning,
  };

  /// A sale line's product name as the owner should read it. Lines recorded
  /// from the keypad carry a fixed internal name that is translated here.
  String displayProductName(String stored) =>
      stored == CartLine.quickSaleName ? saleQuickSale : stored;
}
