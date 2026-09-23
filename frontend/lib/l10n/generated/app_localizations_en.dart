// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kitaza';

  @override
  String get tagline => 'Know where every peso goes';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonBack => 'Back';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonEnterAmount => 'Enter an amount';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonEnterEmail => 'Enter your email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonEnterPassword => 'Enter your password';

  @override
  String get commonPasswordHint => 'At least 8 characters';

  @override
  String get commonPasswordTooShort => 'Use at least 8 characters';

  @override
  String get commonShowPassword => 'Show password';

  @override
  String get commonHidePassword => 'Hide password';

  @override
  String get commonStoreName => 'Store name';

  @override
  String get commonEnterStoreName => 'Enter your store name';

  @override
  String get commonYourName => 'Your name';

  @override
  String get commonEnterYourName => 'Enter your name';

  @override
  String get commonEnterName => 'Enter a name';

  @override
  String get commonNoteOptional => 'Note (optional)';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String commonDayAtTime(Object day, Object time) {
    return '$day, $time';
  }

  @override
  String commonSeparator(Object first, Object second) {
    return '$first · $second';
  }

  @override
  String commonPercent(Object value) {
    return '$value%';
  }

  @override
  String get errorOffline =>
      'You are offline. Your entry is saved on this device and will sync when you reconnect.';

  @override
  String get errorSessionExpired =>
      'Your session expired. Please sign in again.';

  @override
  String get errorServer =>
      'The Kitaza server is having trouble. Your data is safe on this device.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorWrongCredentials => 'Email or password is incorrect.';

  @override
  String get errorEmailTaken => 'An account already uses this email address.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navSales => 'Sales';

  @override
  String get navExpenses => 'Expenses';

  @override
  String get navProducts => 'Products';

  @override
  String get navReports => 'Reports';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'This week';

  @override
  String get periodMonth => 'This month';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentGcash => 'GCash';

  @override
  String get paymentMaya => 'Maya';

  @override
  String get paymentBankTransfer => 'Bank transfer';

  @override
  String get paymentUtang => 'Utang (credit)';

  @override
  String get categoryInventory => 'Stock / Puhunan';

  @override
  String get categoryUtilities => 'Utilities';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryTransportation => 'Transport';

  @override
  String get categoryRent => 'Rent';

  @override
  String get categorySupplies => 'Supplies';

  @override
  String get categoryRepairs => 'Repairs';

  @override
  String get categoryTaxesPermits => 'Taxes & permits';

  @override
  String get categoryOther => 'Other';

  @override
  String get welcomeSubtitle =>
      'Pick how you want to keep your records. You can change this later.';

  @override
  String get welcomeLocalTitle => 'Just this phone';

  @override
  String get welcomeLocalDescription =>
      'Everything stays on this device. No account needed.';

  @override
  String get welcomeLocalPoint1 => 'Works with no load and no signal';

  @override
  String get welcomeLocalPoint2 => 'Nothing to pay, nothing to sign up for';

  @override
  String get welcomeLocalPoint3 => 'Only this device can see your records';

  @override
  String get welcomeCloudTitle => 'Save to the cloud';

  @override
  String get welcomeCloudDescription =>
      'Still works offline, and backs up so you never lose your history.';

  @override
  String get welcomeCloudPoint1 =>
      'Use the same store on your phone and tablet';

  @override
  String get welcomeCloudPoint2 => 'Safe if your phone is lost or broken';

  @override
  String get welcomeCloudPoint3 =>
      'Your helper can record sales while you are out';

  @override
  String get welcomeHaveAccount => 'I already have an account';

  @override
  String get welcomeStartHere => 'Start here';

  @override
  String get setupTitle => 'Set up your store';

  @override
  String get setupSubtitle => 'This takes about ten seconds.';

  @override
  String get setupStoreHint => 'Aling Nena Sari-Sari Store';

  @override
  String get setupNameHint => 'Nena Reyes';

  @override
  String get setupSubmit => 'Start using Kitaza';

  @override
  String get setupFailed => 'Could not set up. Please try again.';

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in once. This device will remember you.';

  @override
  String get signInSubmit => 'Sign in';

  @override
  String get signInCreateAccount => 'Create a new account';

  @override
  String get signInFailed => 'Could not sign in.';

  @override
  String get signUpTitle => 'Create your account';

  @override
  String get signUpSubtitle =>
      'Your records stay on this phone and back up to the cloud.';

  @override
  String get signUpSubmit => 'Create account';

  @override
  String get signUpFailed => 'Could not create your account.';

  @override
  String get dashboardYourStore => 'Your store';

  @override
  String get dashboardGoodMorning => 'Good morning';

  @override
  String get dashboardGoodAfternoon => 'Good afternoon';

  @override
  String get dashboardGoodEvening => 'Good evening';

  @override
  String get dashboardMoneyThisPeriod => 'Money this period';

  @override
  String get dashboardEmptyTitle => 'Nothing recorded yet';

  @override
  String get dashboardEmptyMessage =>
      'Tap \"Add sale\" after your next customer. It takes about five seconds and everything else fills in from there.';

  @override
  String get dashboardSales => 'Sales';

  @override
  String dashboardSaleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
    );
    return '$_temp0';
  }

  @override
  String get dashboardExpenses => 'Expenses';

  @override
  String dashboardCostOfGoods(Object amount) {
    return 'Cost of goods $amount';
  }

  @override
  String get dashboardProfit => 'Profit';

  @override
  String dashboardMarginOfSales(Object percent) {
    return '$percent% of sales';
  }

  @override
  String get dashboardCashKept => 'Cash kept';

  @override
  String get dashboardAfterWithdrawals => 'After your withdrawals';

  @override
  String get dashboardWithdrawalsTitle => 'Owner withdrawals';

  @override
  String dashboardWithdrawalsTaken(Object amount) {
    return 'You took out $amount this period';
  }

  @override
  String get dashboardWithdrawalsPrompt =>
      'Record money you take for personal use';

  @override
  String get dashboardTopSeller => 'Top seller';

  @override
  String dashboardSoldSummary(Object quantity, Object revenue) {
    return '$quantity sold · $revenue';
  }

  @override
  String dashboardLowStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products running low',
      one: '1 product running low',
    );
    return '$_temp0';
  }

  @override
  String get dashboardLowStockHint => 'Tap to see what needs restocking';

  @override
  String get actionAddSale => 'Add sale';

  @override
  String get actionExpense => 'Expense';

  @override
  String get actionProfit => 'Profit';

  @override
  String get healthGood => 'Good';

  @override
  String get healthAverage => 'Average';

  @override
  String get healthWarning => 'Warning';

  @override
  String get healthHeadlineGreen => 'Your store is doing well';

  @override
  String get healthHeadlineYellow => 'Keep an eye on your numbers';

  @override
  String get healthHeadlineRed => 'Your store needs attention';

  @override
  String get healthHeadlineNoSales => 'No sales recorded yet';

  @override
  String healthRatingChip(Object rating, int score) {
    return '$rating · $score';
  }

  @override
  String get healthReasonNoSales =>
      'Record your first sale to see how your store is doing.';

  @override
  String healthReasonProfit(Object amount) {
    return 'You earned a profit of $amount.';
  }

  @override
  String healthReasonLoss(Object amount) {
    return 'You spent $amount more than you sold.';
  }

  @override
  String healthReasonHealthyMargin(int percent) {
    return 'Healthy margin: $percent% of sales is profit.';
  }

  @override
  String healthReasonThinMargin(int percent) {
    return 'Thin margin: only $percent% of sales is profit.';
  }

  @override
  String healthReasonVeryThinMargin(int percent) {
    return 'Very thin margin: $percent% of sales is profit.';
  }

  @override
  String get healthReasonProfitUp =>
      'Profit is higher than the previous period.';

  @override
  String get healthReasonProfitDown =>
      'Profit is lower than the previous period.';

  @override
  String healthReasonOverWithdrawn(Object amount) {
    return 'You withdrew $amount, more than the profit you made.';
  }

  @override
  String healthReasonRestock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products need restocking.',
      one: '1 product needs restocking.',
    );
    return '$_temp0';
  }

  @override
  String get saleTitle => 'Add sale';

  @override
  String get saleProduct => 'Product';

  @override
  String get saleTotal => 'Total';

  @override
  String saleTyping(Object amount) {
    return 'Typing $amount';
  }

  @override
  String saleSaveAmount(Object amount) {
    return 'Save $amount';
  }

  @override
  String get saleNeedsSomething => 'Enter an amount or pick a product first.';

  @override
  String get saleRecorded => 'Sale recorded.';

  @override
  String get saleSaveFailed => 'Could not save the sale. Please try again.';

  @override
  String saleProductAdded(Object name) {
    return '$name added.';
  }

  @override
  String saleEach(Object price) {
    return '$price each';
  }

  @override
  String get saleLess => 'Less';

  @override
  String get saleMore => 'More';

  @override
  String get saleQuickSale => 'Quick sale';

  @override
  String saleItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get saleGeneric => 'Sale';

  @override
  String get saleHistoryEmptyTitle => 'No sales in this period';

  @override
  String get saleHistoryEmptyMessage =>
      'Every sale you record shows up here with its profit.';

  @override
  String get saleHistoryEmptyAction => 'Add a sale';

  @override
  String saleProfitAmount(Object amount) {
    return '$amount profit';
  }

  @override
  String get saleVoidTitle => 'Void this sale?';

  @override
  String get saleVoidMessage =>
      'The amount is removed from your totals and any stock is put back.';

  @override
  String get saleVoidKeep => 'Keep it';

  @override
  String get saleVoidConfirm => 'Void sale';

  @override
  String get saleVoided => 'Sale voided.';

  @override
  String get salePickerSearch => 'Search product or scan code';

  @override
  String get salePickerEmptyTitle => 'No products yet';

  @override
  String get salePickerEmptyMessage =>
      'You can still record the sale by typing the amount on the keypad.';

  @override
  String get saleOutOfStock => 'Out of stock';

  @override
  String saleStockLeft(Object quantity, Object unit) {
    return '$quantity $unit left';
  }

  @override
  String get keypadBackspace => 'Delete last digit';

  @override
  String get keypadBackspaceHint => 'Hold to clear';

  @override
  String get keypadDecimal => 'Decimal point';

  @override
  String get expenseTitle => 'Add expense';

  @override
  String get expenseWhatFor => 'What was it for?';

  @override
  String get expenseNoteHint => 'Meralco bill for October';

  @override
  String get expenseSave => 'Save expense';

  @override
  String get expenseRecorded => 'Expense recorded.';

  @override
  String get expenseSaveFailed => 'Could not save. Please try again.';

  @override
  String get expenseHistoryEmptyTitle => 'No expenses recorded';

  @override
  String get expenseHistoryEmptyMessage =>
      'Track what you spend on stock, load, transport and bills so your profit is real.';

  @override
  String get expenseHistoryEmptyAction => 'Add an expense';

  @override
  String get productAdd => 'Add product';

  @override
  String get productEdit => 'Edit product';

  @override
  String get productName => 'Product name';

  @override
  String get productNameHint => 'Lucky Me Pancit Canton';

  @override
  String get productCost => 'Cost (puhunan)';

  @override
  String get productPrice => 'Selling price';

  @override
  String get productStock => 'Stock on hand';

  @override
  String get productReorder => 'Warn me below';

  @override
  String get productSave => 'Save product';

  @override
  String get productSaved => 'Product saved.';

  @override
  String get productSaveFailed => 'Could not save the product.';

  @override
  String get productSearch => 'Search products';

  @override
  String get productEmptyTitle => 'No products yet';

  @override
  String get productEmptyMessage =>
      'Adding your regular items makes each sale one tap, and lets Kitaza tell you which ones actually earn.';

  @override
  String get productEmptyAction => 'Add your first product';

  @override
  String productMargin(Object percent) {
    return '$percent% margin';
  }

  @override
  String get productRestock => 'Restock';

  @override
  String productStockUnits(Object quantity, Object unit) {
    return '$quantity $unit';
  }

  @override
  String productWouldLose(Object amount) {
    return 'You would lose $amount per sale';
  }

  @override
  String productEarns(Object amount, Object percent) {
    return 'You earn $amount ($percent%) per sale';
  }

  @override
  String get withdrawalTitle => 'Owner withdrawals';

  @override
  String get withdrawalRecord => 'Record';

  @override
  String get withdrawalEmptyTitle => 'No withdrawals recorded';

  @override
  String get withdrawalEmptyMessage =>
      'When you take money from the store for personal use, record it here so your profit stays accurate.';

  @override
  String get withdrawalExplainer =>
      'Money you take home is not a business expense. Recording it here keeps your profit honest and shows what is really left.';

  @override
  String get withdrawalDefaultReason => 'Personal withdrawal';

  @override
  String get withdrawalRecorded => 'Withdrawal recorded.';

  @override
  String get withdrawalSheetTitle => 'Money taken out';

  @override
  String get withdrawalReason => 'What for? (optional)';

  @override
  String get withdrawalReasonHint => 'Grocery, tuition, allowance';

  @override
  String get withdrawalSubmit => 'Record withdrawal';

  @override
  String get reportTitle => 'Reports';

  @override
  String get reportEmptyTitle => 'Nothing to report yet';

  @override
  String get reportEmptyMessage =>
      'Record a few sales and expenses and this screen will show which products earn, where your money goes, and how your profit is trending.';

  @override
  String get reportTrendTitle => 'Daily profit, last 14 days';

  @override
  String get reportTrendHint => 'Tap a bar to see that day';

  @override
  String reportTrendSummary(
    int days,
    Object bestDay,
    Object bestAmount,
    Object worstDay,
    Object worstAmount,
  ) {
    return 'Daily profit over the last $days days. Best day $bestDay, $bestAmount. Worst day $worstDay, $worstAmount.';
  }

  @override
  String get reportTopProducts => 'Where your profit comes from';

  @override
  String get reportExpenseBreakdown => 'Where your money goes';

  @override
  String get reportUnusual => 'Worth a second look';

  @override
  String reportUnusualDetail(Object times, Object average, Object date) {
    return '${times}x your usual $average · $date';
  }

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceHint =>
      'Dark mode is easier at night; Auto follows your phone.';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageAuto => 'Auto';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageFilipino => 'Filipino';

  @override
  String get settingsYourData => 'Your data';

  @override
  String get settingsAccount => 'Account';

  @override
  String get storageLocalTitle => 'Saved on this phone only';

  @override
  String get storageLocalRisk =>
      'If this phone is lost or broken, your records go with it.';

  @override
  String get storageBackUp => 'Back up to the cloud';

  @override
  String get storageBackUpHint => 'Keeps everything you have recorded so far';

  @override
  String get storageCloudTitle => 'Backed up to the cloud';

  @override
  String get storageNotSynced => 'Not synced yet';

  @override
  String storageLastSynced(Object when) {
    return 'Last synced $when';
  }

  @override
  String storagePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting to upload',
      one: '1 waiting to upload',
    );
    return '$_temp0';
  }

  @override
  String get storagePendingHint => 'These go up as soon as you have signal.';

  @override
  String storageParked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count could not be saved',
      one: '1 could not be saved',
    );
    return '$_temp0';
  }

  @override
  String get storageParkedHint => 'Tap to see why and decide what to do';

  @override
  String get storageSyncNow => 'Sync now';

  @override
  String get storageUpToDate => 'Everything is up to date.';

  @override
  String get storageUnreachable => 'Could not reach the cloud. Will try again.';

  @override
  String get syncSavedOnPhone => 'Saved on this phone';

  @override
  String get syncSyncing => 'Syncing';

  @override
  String get syncOffline => 'Offline';

  @override
  String get syncBackedUp => 'Backed up';

  @override
  String get syncProblem => 'Sync problem';

  @override
  String syncWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting to sync',
      one: '1 waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get problemsTitle => 'Sync problems';

  @override
  String get problemsEmptyTitle => 'Nothing is stuck';

  @override
  String get problemsEmptyMessage =>
      'Every entry has reached the cloud or is waiting its turn.';

  @override
  String get problemsRefused => 'Refused by the server';

  @override
  String problemsStopped(int count) {
    return 'Stopped retrying after $count attempts.';
  }

  @override
  String problemsWillRetry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tried $count times; will retry.',
      one: 'Tried once; will retry.',
    );
    return '$_temp0';
  }

  @override
  String get problemsKeepLocal => 'Keep on phone only';

  @override
  String get problemsDiscardTitle => 'Stop uploading this?';

  @override
  String get problemsDiscardMessage =>
      'It stays in your records on this phone, but other devices and the cloud backup will not have it.';

  @override
  String get problemsSale => 'Sale';

  @override
  String problemsExpense(Object detail) {
    return 'Expense: $detail';
  }

  @override
  String get problemsWithdrawal => 'Withdrawal';

  @override
  String problemsProduct(Object name) {
    return 'Product: $name';
  }

  @override
  String get problemsStockChange => 'Stock change';

  @override
  String problemsRemoval(Object entity) {
    return 'Removal of a $entity';
  }

  @override
  String get problemsChange => 'Change';

  @override
  String get upgradeTitle => 'Back up to the cloud';

  @override
  String get upgradeIntro =>
      'Everything you have recorded on this phone stays, and is copied to your account. The app keeps working offline exactly as before.';

  @override
  String get upgradeNewAccount => 'New account';

  @override
  String get upgradeExistingAccount => 'I have one';

  @override
  String get upgradeExistingNote =>
      'This phone\'s records will be added to the store on that account.';

  @override
  String get upgradeCreateSubmit => 'Create account and back up';

  @override
  String get upgradeSignInSubmit => 'Sign in and back up';

  @override
  String get upgradeDone => 'Your store is now backed up.';

  @override
  String get upgradeFailed =>
      'Could not back up right now. Nothing was changed.';

  @override
  String get accountOfflineProfile => 'Offline profile';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutTitle => 'Sign out?';

  @override
  String get accountSignOutLocal =>
      'Your records are only on this phone. Signing out erases them for good.';

  @override
  String get accountSignOutClean =>
      'Everything is backed up. Sign back in on any phone to pick up where you left off.';

  @override
  String accountSignOutUnsent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count changes have not reached the cloud yet, and will be lost if you sign out now. Try again when you have signal.',
      one: '1 change has not reached the cloud yet, and will be lost if you sign out now. Try again when you have signal.',
    );
    return '$_temp0';
  }

  @override
  String get accountEraseAndSignOut => 'Erase and sign out';

  @override
  String get starterTitle => 'Start with common products';

  @override
  String get starterIntro =>
      'Tick what you sell. You can change names and prices any time.';

  @override
  String get starterPricesNotice =>
      'These are typical prices, not yours. Check each item\'s cost and price so your profit figures are right.';

  @override
  String starterAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count products',
      one: 'Add 1 product',
      zero: 'Pick at least one',
    );
    return '$_temp0';
  }

  @override
  String starterAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products added. Check their prices when you can.',
      one: '1 product added. Check its price when you can.',
    );
    return '$_temp0';
  }

  @override
  String get starterAll => 'All';

  @override
  String get starterOffer => 'Add common sari-sari items';

  @override
  String get starterPromptTitle => 'Your product list is empty';

  @override
  String get starterPromptMessage =>
      'Start with the usual sari-sari items, then each sale is one tap.';

  @override
  String get backupSection => 'Backups';

  @override
  String get backupAutoNone =>
      'No automatic copy yet. One is made each day you open the app.';

  @override
  String backupAutoLast(Object when) {
    return 'A copy is saved on this phone each day. Last copy: $when';
  }

  @override
  String get backupCloudNote => 'Your records are also kept in the cloud.';

  @override
  String get backupExport => 'Save a backup copy';

  @override
  String get backupExportHint =>
      'Send it to yourself on Messenger, Drive or email so it survives if this phone is lost.';

  @override
  String backupExportText(Object store) {
    return 'Kitaza backup for $store. Keep this file somewhere safe.';
  }

  @override
  String get backupExportFailed => 'Could not create a backup copy.';

  @override
  String get backupRestore => 'Restore from a backup file';

  @override
  String get backupRestoreHint =>
      'Replaces everything on this phone with the records in the file.';

  @override
  String get backupConfirmTitle => 'Restore this backup?';

  @override
  String backupConfirmSummary(Object store, int sales, int products) {
    String _temp0 = intl.Intl.pluralLogic(
      sales,
      locale: localeName,
      other: '$sales sales',
      one: '1 sale',
    );
    String _temp1 = intl.Intl.pluralLogic(
      products,
      locale: localeName,
      other: '$products products',
      one: '1 product',
    );
    return '$store: $_temp0 and $_temp1.';
  }

  @override
  String backupConfirmLastEntry(Object when) {
    return 'Last entry: $when.';
  }

  @override
  String get backupConfirmWarning =>
      'Everything currently on this phone will be replaced.';

  @override
  String get backupConfirmAction => 'Replace and restore';

  @override
  String get backupProblemNotABackup => 'That file is not a Kitaza backup.';

  @override
  String get backupProblemTooNew =>
      'This backup was made by a newer version of Kitaza. Update the app, then try again.';

  @override
  String get backupProblemDamaged =>
      'This backup file is damaged and cannot be restored.';

  @override
  String reportsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problem reports',
      one: '1 problem report',
    );
    return '$_temp0';
  }

  @override
  String get reportsCloudHint =>
      'Sent to the Kitaza team automatically when you sync.';

  @override
  String get reportsLocalHint =>
      'Tap to send them to the Kitaza team. They hold no sales or customer details.';

  @override
  String get reportsShareIntro =>
      'Kitaza problem reports. They hold no sales or customer details.';

  @override
  String get scanAction => 'Scan';

  @override
  String get scanTitle => 'Scan barcode';

  @override
  String get scanHint => 'Point the camera at the barcode';

  @override
  String get scanLight => 'Light';

  @override
  String get scanDone => 'Done';

  @override
  String scanAdded(Object name) {
    return '$name added';
  }

  @override
  String get scanUnknownTitle => 'No product has this code yet';

  @override
  String scanUnknownMessage(Object code) {
    return 'Code $code. Add it as a new product so the next scan finds it.';
  }

  @override
  String get scanAddProduct => 'Add as new product';

  @override
  String get scanNoCamera =>
      'Kitaza needs the camera to scan barcodes. Allow it in your phone\'s settings.';

  @override
  String get productBarcode => 'Barcode (optional)';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptSubtotal => 'Subtotal';

  @override
  String get receiptDiscount => 'Discount';

  @override
  String get receiptTotal => 'TOTAL';

  @override
  String get receiptPaidBy => 'Paid by';

  @override
  String receiptReference(Object code) {
    return 'Ref $code';
  }

  @override
  String get receiptThanks => 'Thank you!';

  @override
  String get receiptShare => 'Share';

  @override
  String get receiptPrint => 'Print';

  @override
  String get receiptPrinted => 'Receipt printed.';

  @override
  String get receiptNoPrinter =>
      'No receipt printer yet. Set one up in Settings.';

  @override
  String get printerSection => 'Receipt printer';

  @override
  String get printerNone => 'None chosen';

  @override
  String get printerChoose => 'Choose printer';

  @override
  String get printerChooseHint =>
      'Pair the printer in your phone\'s Bluetooth settings first, then pick it here.';

  @override
  String get printerNoneFound =>
      'No paired Bluetooth devices. Pair your printer in your phone\'s Bluetooth settings first.';

  @override
  String get printerPaper => 'Paper width';

  @override
  String get printerTest => 'Print a test receipt';

  @override
  String get printerTestLine =>
      'Printer test - if you can read this, it works.';

  @override
  String get printerBluetoothOff =>
      'Bluetooth is off. Turn it on and try again.';

  @override
  String get printerNoPermission =>
      'Kitaza needs Bluetooth permission to print. Allow it in your phone\'s settings.';

  @override
  String get printerCouldNotConnect =>
      'Could not connect to the printer. Check that it is on and nearby.';

  @override
  String get printerFailed =>
      'The printer did not accept the receipt. Try again.';

  @override
  String get welcomeJoinStaff => 'Join a store as staff';

  @override
  String get joinTitle => 'Join a store';

  @override
  String get joinSubtitle =>
      'Ask the store owner for a join code. They make one in Settings, under Staff.';

  @override
  String get joinCodeLabel => 'Join code';

  @override
  String get joinCodeInvalid => 'Enter all 10 letters and numbers of the code';

  @override
  String get joinAction => 'Join store';

  @override
  String get joinCodeRefused =>
      'That code did not work. It may have been used already or expired. Ask the owner for a new one.';

  @override
  String get joinSharedPhoneNote =>
      'Each code works on one phone. Anything recorded here goes to the store, under your name.';

  @override
  String get sessionEndedTitle => 'This phone was signed out';

  @override
  String sessionEndedMessage(Object store) {
    return '$store was signed out on this phone from another device, or your access to it was removed.';
  }

  @override
  String sessionEndedUnsent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count entries recorded here have not reached the cloud yet. Sign back in to send them.',
      one: '1 entry recorded here has not reached the cloud yet. Sign back in to send it.',
      zero: 'Everything recorded here had already reached the cloud.',
    );
    return '$_temp0';
  }

  @override
  String get sessionEndedSignIn => 'Sign in again';

  @override
  String get sessionEndedJoin => 'Enter a new join code';

  @override
  String get sessionEndedClear => 'Remove this store from the phone';

  @override
  String get sessionEndedClearTitle => 'Remove this store\'s records?';

  @override
  String sessionEndedClearMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count entries that never reached the cloud will be lost for good.',
      one: '1 entry that never reached the cloud will be lost for good.',
      zero: 'Everything here is already in the cloud, so nothing will be lost.',
    );
    return '$_temp0';
  }

  @override
  String get sessionEndedClearConfirm => 'Remove';

  @override
  String get settingsTeam => 'Stores and staff';

  @override
  String get storesHint =>
      'Tap a store to open it. Each keeps its own products, sales and staff.';

  @override
  String get storesOpenNow => 'Open now';

  @override
  String get storesAdd => 'Add another store';

  @override
  String get storesAddTitle => 'New store';

  @override
  String get storesAddSubmit => 'Add store';

  @override
  String get storesRename => 'Rename store';

  @override
  String storesSwitched(Object store) {
    return 'Now working in $store';
  }

  @override
  String get storesPickerTitle => 'Open a store';

  @override
  String get storesSwitchHint => 'Switch store';

  @override
  String get teamLocalTitle => 'Staff and more stores';

  @override
  String get teamLocalMessage =>
      'Staff accounts, more than one store and signing out a lost phone all need your records in the cloud.';

  @override
  String get staffTitle => 'Staff';

  @override
  String get staffTileHint => 'Let helpers sell from their own phone';

  @override
  String get staffEmptyTitle => 'No staff yet';

  @override
  String get staffEmptyMessage =>
      'Add the people who help at the counter. They sell from their own phone, and you choose what else they can do.';

  @override
  String get staffAdd => 'Add staff';

  @override
  String get staffNameLabel => 'Their name';

  @override
  String get staffAlwaysSells =>
      'Staff can always record sales. Choose what else they may do:';

  @override
  String get permissionManageProducts => 'Manage products';

  @override
  String get permissionManageProductsHint =>
      'Add and edit products and prices, record deliveries and stock counts';

  @override
  String get permissionRecordExpenses => 'Record expenses';

  @override
  String get permissionRecordExpensesHint => 'Write down what the store spends';

  @override
  String get permissionViewProfit => 'See profit and costs';

  @override
  String get permissionViewProfitHint =>
      'Cost prices, profit, expenses and the health score. Without this, costs never reach their phone.';

  @override
  String get permissionDeleteRecords => 'Void and delete';

  @override
  String get permissionDeleteRecordsHint =>
      'Void sales and delete expenses. Every void is kept in the activity log.';

  @override
  String get staffSells => 'Sells';

  @override
  String get staffShortProducts => 'products';

  @override
  String get staffShortExpenses => 'expenses';

  @override
  String get staffShortProfit => 'profit';

  @override
  String get staffShortDelete => 'voids';

  @override
  String staffDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Signed in on $count phones',
      one: 'Signed in on 1 phone',
      zero: 'Not signed in yet',
    );
    return '$_temp0';
  }

  @override
  String staffCodeWorksUntil(Object when) {
    return 'Join code works until $when';
  }

  @override
  String get staffNewCode => 'Make a new join code';

  @override
  String get staffNewCodeHint =>
      'For a new or replaced phone. Any earlier code stops working.';

  @override
  String get staffRemove => 'Remove from store';

  @override
  String staffRemoveTitle(Object name) {
    return 'Remove $name?';
  }

  @override
  String staffRemoveMessage(Object name) {
    return '$name\'s phone will be signed out straight away. Sales on it that have not reached the cloud yet will not arrive.';
  }

  @override
  String staffRemoved(Object name) {
    return '$name was removed';
  }

  @override
  String get staffSaved =>
      'Saved. Their phone picks this up within a few minutes.';

  @override
  String inviteTitle(Object name) {
    return 'Join code for $name';
  }

  @override
  String inviteSteps(Object name) {
    return 'On $name\'s phone, open Kitaza, tap “Join a store as staff” and enter this code.';
  }

  @override
  String inviteExpires(Object when) {
    return 'Works on one phone, until $when.';
  }

  @override
  String get inviteShare => 'Share code';

  @override
  String get inviteCopy => 'Copy';

  @override
  String get inviteCopied => 'Code copied';

  @override
  String inviteShareText(Object store, Object code) {
    return 'Join $store on Kitaza: open Kitaza, tap “Join a store as staff” and enter $code. The code works once, for one day.';
  }

  @override
  String get inviteDone => 'Done';

  @override
  String get devicesTitle => 'Signed-in devices';

  @override
  String get devicesTileHint =>
      'Every phone using your stores. Sign out one that was lost.';

  @override
  String get devicesIntro =>
      'Every phone that can open your stores. Sign out one that was lost, sold, or belongs to someone who left.';

  @override
  String get devicesThisPhone => 'This phone';

  @override
  String get devicesYou => 'You';

  @override
  String devicesStaff(Object name) {
    return '$name, staff';
  }

  @override
  String devicesLastActive(Object when) {
    return 'Last active $when';
  }

  @override
  String get devicesSignOut => 'Sign out';

  @override
  String devicesSignOutTitle(Object device) {
    return 'Sign out $device?';
  }

  @override
  String get devicesSignOutMessage =>
      'It stops syncing straight away and has to sign in again to be used. Anything on it that has not reached the cloud yet will not arrive.';

  @override
  String devicesSignedOut(Object device) {
    return '$device was signed out';
  }

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityTileHint => 'Who recorded, changed and voided what';

  @override
  String get activityFilterAll => 'Everything';

  @override
  String get activityFilterRemovals => 'Voids and deletions';

  @override
  String get activityEmptyTitle => 'Nothing here yet';

  @override
  String get activityEmptyMessage =>
      'Sales, changes and voids from every phone are listed here, with who made them.';

  @override
  String get activityShowOlder => 'Show older';

  @override
  String activitySaleRecorded(Object name, Object amount) {
    return '$name recorded a sale of $amount';
  }

  @override
  String activitySaleVoided(Object name, Object amount) {
    return '$name voided a sale of $amount';
  }

  @override
  String activityExpenseRecorded(Object name, Object amount, Object category) {
    return '$name recorded $amount for $category';
  }

  @override
  String activityExpenseDeleted(Object name, Object amount, Object category) {
    return '$name deleted $amount for $category';
  }

  @override
  String activityWithdrawalRecorded(Object name, Object amount) {
    return '$name took out $amount for personal use';
  }

  @override
  String activityWithdrawalDeleted(Object name, Object amount) {
    return '$name deleted a withdrawal of $amount';
  }

  @override
  String activityProductAdded(Object name, Object product, Object price) {
    return '$name added $product at $price';
  }

  @override
  String activityProductChanged(Object name, Object product) {
    return '$name changed $product';
  }

  @override
  String activityProductRemoved(Object name, Object product) {
    return '$name removed $product';
  }

  @override
  String activityPriceChange(Object before, Object after) {
    return 'Price $before to $after';
  }

  @override
  String activityCostChange(Object before, Object after) {
    return 'Cost $before to $after';
  }

  @override
  String activityRenamedFrom(Object before) {
    return 'Was “$before”';
  }

  @override
  String activityStockReceived(Object name, Object quantity, Object product) {
    return '$name received $quantity $product';
  }

  @override
  String activityStockRemoved(Object name, Object quantity, Object product) {
    return '$name took out $quantity $product';
  }

  @override
  String activityStockCounted(Object name, Object quantity, Object product) {
    return '$name counted $quantity $product';
  }

  @override
  String activityStockDifference(Object change) {
    return '$change from what was expected';
  }

  @override
  String activityStockSpoiled(Object name, Object quantity, Object product) {
    return '$name marked $quantity $product as spoiled';
  }

  @override
  String activityStaffAdded(Object name, Object staff) {
    return '$name added $staff as staff';
  }

  @override
  String activityStaffChanged(Object name, Object staff) {
    return '$name changed what $staff can do';
  }

  @override
  String activityStaffRemoved(Object name, Object staff) {
    return '$name removed $staff';
  }

  @override
  String activityStaffInvited(Object name, Object staff) {
    return '$name made a join code for $staff';
  }

  @override
  String activityStaffJoined(Object name, Object device) {
    return '$name joined on $device';
  }

  @override
  String activityDeviceSignedOut(Object name, Object member, Object device) {
    return '$name signed out $member\'s $device';
  }

  @override
  String activityStoreAdded(Object name, Object store) {
    return '$name opened $store';
  }

  @override
  String activityStoreRenamed(Object name, Object before, Object store) {
    return '$name renamed $before to $store';
  }

  @override
  String activityOther(Object name) {
    return '$name made a change';
  }

  @override
  String get activityStaffBadge => 'Staff';

  @override
  String accountStaffAt(Object store) {
    return 'Staff at $store';
  }

  @override
  String get accountStaffSignOutNote =>
      'To use this phone again, you will need a new join code from the owner.';

  @override
  String get productCostSetByOwner => 'The owner sets the cost price.';

  @override
  String get syncNotAllowed =>
      'Your access does not allow this. Ask the owner.';

  @override
  String get settingsPlan => 'Plan';

  @override
  String get planTitle => 'Your plan';

  @override
  String planStatusTrial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Free Pro trial, $count days left',
      one: 'Free Pro trial, 1 day left',
    );
    return '$_temp0';
  }

  @override
  String planStatusActive(Object plan, Object date) {
    return '$plan, paid until $date';
  }

  @override
  String planStatusGrace(Object date) {
    return 'Your plan has ended. Everything keeps working until $date.';
  }

  @override
  String get planStatusPaused =>
      'Cloud backup is paused. Everything you record is kept on this phone and uploads as soon as you renew.';

  @override
  String get planStatusUnlimited =>
      'This server does not charge. Everything is included.';

  @override
  String get planBasic => 'Basic';

  @override
  String get planPro => 'Pro';

  @override
  String get planBasicPoints =>
      'Backup and sync for one store, on all your phones';

  @override
  String get planProPoints =>
      'Up to 5 stores, staff accounts, and everything in Basic';

  @override
  String planPerMonth(Object price) {
    return '$price a month';
  }

  @override
  String planPerYear(Object price) {
    return '$price a year';
  }

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planYearly => 'Yearly, 2 months free';

  @override
  String planPay(Object amount) {
    return 'Pay $amount with GCash or Maya';
  }

  @override
  String get planPayHint =>
      'You pay ahead, like buying load. Nothing is ever charged automatically.';

  @override
  String get planFinishInBrowser =>
      'Finish paying on the page that opened. Kitaza updates when you come back.';

  @override
  String get planCouldNotOpen => 'Could not open the payment page. Try again.';

  @override
  String get planPaid => 'Thank you! Your plan is updated.';

  @override
  String get planCurrent => 'Current';

  @override
  String get planHistory => 'Payments';

  @override
  String get planOneMonth => '1 month';

  @override
  String get planOneYear => '1 year';

  @override
  String get planLeaveTitle => 'Use Kitaza offline for free';

  @override
  String get planLeaveHint =>
      'Keep everything on this phone and stop syncing. Your records in the cloud stay there.';

  @override
  String get planLeaveConfirmTitle => 'Switch this phone to offline?';

  @override
  String get planLeaveConfirmMessage =>
      'This phone keeps every record and stops syncing. Your other phones and staff will no longer see what is recorded here. You can move back to the cloud any time.';

  @override
  String get planLeaveConfirm => 'Use offline';

  @override
  String get planLeft => 'This phone now works offline. Nothing was lost.';

  @override
  String get planPausedShort =>
      'Cloud backup is paused until the plan is renewed. This entry is kept on the phone.';

  @override
  String get planUpgradeNeeded => 'This needs Kitaza Pro.';

  @override
  String planBannerTrial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your free trial ends in $count days.',
      one: 'Your free trial ends in 1 day.',
    );
    return '$_temp0';
  }

  @override
  String planBannerEnding(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your plan ends in $count days.',
      one: 'Your plan ends in 1 day.',
    );
    return '$_temp0';
  }

  @override
  String planBannerGrace(Object date) {
    return 'Your plan has ended. Syncing continues until $date.';
  }

  @override
  String get planBannerPaused =>
      'Cloud backup is paused. Your entries are kept on this phone.';

  @override
  String get planBannerAction => 'Choose a plan';

  @override
  String get planBannerStaff => 'Ask the owner to renew the store\'s plan.';

  @override
  String get syncPaused => 'Paused, saved on this phone';

  @override
  String activitySubscriptionPaid(Object name, Object amount, Object plan) {
    return '$name paid $amount for $plan';
  }

  @override
  String get insightsTitle => 'Suggestions';

  @override
  String get insightsEarlyDays =>
      'Keep recording sales for about two weeks and Kitaza can suggest what to reorder and which prices to look at.';

  @override
  String get insightsHowTitle => 'How these are worked out';

  @override
  String get insightsHowBody =>
      'From your own records on this phone: the last four weeks of sales for each product, with the days it was out of stock left out. Nothing here changes a price or orders anything.';

  @override
  String get restockTitle => 'Reorder soon';

  @override
  String restockOrder(Object quantity, Object unit) {
    return 'Order $quantity $unit';
  }

  @override
  String restockReasonRate(Object quantity, Object unit, Object days) {
    return 'About $quantity $unit a day. Around $days left.';
  }

  @override
  String restockReasonEmpty(Object quantity, Object unit) {
    return 'About $quantity $unit a day, and the shelf is empty.';
  }

  @override
  String get restockReasonLevel => 'Below the reorder level you set.';

  @override
  String restockDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get priceTitle => 'Prices worth a look';

  @override
  String priceReasonBelowCost(Object cost) {
    return 'Sold for less than the $cost it costs you.';
  }

  @override
  String priceReasonThin(Object percent) {
    return 'Only $percent is left after the cost.';
  }

  @override
  String get priceReasonSlow => 'Barely sells. Money sitting on the shelf.';

  @override
  String priceTry(Object price) {
    return 'Try $price';
  }

  @override
  String priceExtraPerMonth(Object amount) {
    return 'About $amount more a month';
  }

  @override
  String get priceSlowAdvice =>
      'Order fewer next time, or lower the price for a while.';

  @override
  String get patternTitle => 'Your rhythm';

  @override
  String patternPayday(Object percent) {
    return 'Payday weeks bring in about $percent more than the rest of the month.';
  }

  @override
  String patternNextPayday(Object date) {
    return 'Next payday is $date. Stock up before it.';
  }

  @override
  String patternBusiest(Object day, Object percent) {
    return '$day is your best day, about $percent above your average.';
  }

  @override
  String get benchmarkTitle => 'Stores like yours';

  @override
  String benchmarkFrom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The middle of $count similar stores near your size.',
    );
    return '$_temp0';
  }

  @override
  String get benchmarkMargin => 'Kept from each sale';

  @override
  String get benchmarkExpenses => 'Expenses against sales';

  @override
  String get benchmarkDailySales => 'Sales a day';

  @override
  String benchmarkYours(Object value) {
    return 'You: $value';
  }

  @override
  String benchmarkTypical(Object value) {
    return 'Usual: $value';
  }

  @override
  String get benchmarkNotEnough =>
      'Comparisons appear once enough stores your size are sharing theirs.';

  @override
  String get benchmarkNotSharing =>
      'Comparisons are off while you keep your own figures back.';

  @override
  String get benchmarkSharingTitle => 'Share anonymous comparisons';

  @override
  String get benchmarkSharingHint =>
      'Your monthly totals join the middle figures other owners see. Never your name, your store or any single sale, and only across at least 20 stores.';

  @override
  String get benchmarkSharingOff =>
      'Not sharing. You will not see comparisons either.';
}
