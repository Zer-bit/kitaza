/// Every route name in one place. Screens navigate by these constants so a
/// path change never means hunting through the widget tree.
abstract final class RoutePaths {
  static const String welcome = '/welcome';
  static const String localSetup = '/welcome/offline';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';

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

  static const Set<String> publicRoutes = {welcome, localSetup, signIn, signUp};
}
