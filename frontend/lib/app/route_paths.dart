import '../data/models/legal_document.dart';

/// Every route name in one place. Screens navigate by these constants so a
/// path change never means hunting through the widget tree.
abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String localSetup = '/welcome/offline';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String joinStore = '/join';
  static const String sessionEnded = '/signed-out';

  static const String dashboard = '/';
  static const String recordSale = '/sales/new';
  static const String saleHistory = '/sales';
  static const String recordExpense = '/expenses/new';
  static const String expenseHistory = '/expenses';
  static const String products = '/products';
  static const String productEditor = '/products/edit';
  static const String withdrawals = '/withdrawals';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String cloudUpgrade = '/settings/cloud';
  static const String syncProblems = '/settings/sync-problems';
  static const String staff = '/settings/staff';
  static const String devices = '/settings/devices';
  static const String activity = '/settings/activity';
  static const String plan = '/settings/plan';
  static const String guide = '/guide';
  static const String privacy = '/settings/privacy';
  static const String closeAccount = '/settings/privacy/close';
  static const String legal = '/legal';

  /// One legal document. Named in the path so a link keeps working.
  static String legalFor(LegalDocument document) =>
      '$legal/${document.wireName}';

  static const Set<String> publicRoutes = {
    welcome,
    localSetup,
    signIn,
    signUp,
    joinStore,
  };

  /// Where a phone whose session the server ended may go: the explanation,
  /// and the two ways back in.
  static const Set<String> endedRoutes = {sessionEnded, signIn, joinStore};
}
