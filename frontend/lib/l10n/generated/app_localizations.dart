import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kitaza'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Know where every peso goes'**
  String get tagline;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// No description provided for @commonEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get commonEnterAmount;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get commonEnterEmail;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get commonEnterPassword;

  /// No description provided for @commonPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get commonPasswordHint;

  /// No description provided for @commonPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get commonPasswordTooShort;

  /// No description provided for @commonShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// No description provided for @commonStoreName.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get commonStoreName;

  /// No description provided for @commonEnterStoreName.
  ///
  /// In en, this message translates to:
  /// **'Enter your store name'**
  String get commonEnterStoreName;

  /// No description provided for @commonYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get commonYourName;

  /// No description provided for @commonEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get commonEnterYourName;

  /// No description provided for @commonEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get commonEnterName;

  /// No description provided for @commonNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get commonNoteOptional;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonDayAtTime.
  ///
  /// In en, this message translates to:
  /// **'{day}, {time}'**
  String commonDayAtTime(Object day, Object time);

  /// No description provided for @commonSeparator.
  ///
  /// In en, this message translates to:
  /// **'{first} · {second}'**
  String commonSeparator(Object first, Object second);

  /// No description provided for @commonPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String commonPercent(Object value);

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Your entry is saved on this device and will sync when you reconnect.'**
  String get errorOffline;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The Kitaza server is having trouble. Your data is safe on this device.'**
  String get errorServer;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get errorWrongCredentials;

  /// No description provided for @errorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'An account already uses this email address.'**
  String get errorEmailTaken;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes and try again.'**
  String get errorTooManyAttempts;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get navSales;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodMonth;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentGcash.
  ///
  /// In en, this message translates to:
  /// **'GCash'**
  String get paymentGcash;

  /// No description provided for @paymentMaya.
  ///
  /// In en, this message translates to:
  /// **'Maya'**
  String get paymentMaya;

  /// No description provided for @paymentBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get paymentBankTransfer;

  /// No description provided for @paymentUtang.
  ///
  /// In en, this message translates to:
  /// **'Utang (credit)'**
  String get paymentUtang;

  /// No description provided for @categoryInventory.
  ///
  /// In en, this message translates to:
  /// **'Stock / Puhunan'**
  String get categoryInventory;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransportation;

  /// No description provided for @categoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get categoryRent;

  /// No description provided for @categorySupplies.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get categorySupplies;

  /// No description provided for @categoryRepairs.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get categoryRepairs;

  /// No description provided for @categoryTaxesPermits.
  ///
  /// In en, this message translates to:
  /// **'Taxes & permits'**
  String get categoryTaxesPermits;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick how you want to keep your records. You can change this later.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Just this phone'**
  String get welcomeLocalTitle;

  /// No description provided for @welcomeLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this device. No account needed.'**
  String get welcomeLocalDescription;

  /// No description provided for @welcomeLocalPoint1.
  ///
  /// In en, this message translates to:
  /// **'Works with no load and no signal'**
  String get welcomeLocalPoint1;

  /// No description provided for @welcomeLocalPoint2.
  ///
  /// In en, this message translates to:
  /// **'Nothing to pay, nothing to sign up for'**
  String get welcomeLocalPoint2;

  /// No description provided for @welcomeLocalPoint3.
  ///
  /// In en, this message translates to:
  /// **'Only this device can see your records'**
  String get welcomeLocalPoint3;

  /// No description provided for @welcomeCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Save to the cloud'**
  String get welcomeCloudTitle;

  /// No description provided for @welcomeCloudDescription.
  ///
  /// In en, this message translates to:
  /// **'Still works offline, and backs up so you never lose your history.'**
  String get welcomeCloudDescription;

  /// No description provided for @welcomeCloudPoint1.
  ///
  /// In en, this message translates to:
  /// **'Use the same store on your phone and tablet'**
  String get welcomeCloudPoint1;

  /// No description provided for @welcomeCloudPoint2.
  ///
  /// In en, this message translates to:
  /// **'Safe if your phone is lost or broken'**
  String get welcomeCloudPoint2;

  /// No description provided for @welcomeCloudPoint3.
  ///
  /// In en, this message translates to:
  /// **'Your helper can record sales while you are out'**
  String get welcomeCloudPoint3;

  /// No description provided for @welcomeHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeHaveAccount;

  /// No description provided for @welcomeStartHere.
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get welcomeStartHere;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your store'**
  String get setupTitle;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This takes about ten seconds.'**
  String get setupSubtitle;

  /// No description provided for @setupStoreHint.
  ///
  /// In en, this message translates to:
  /// **'Aling Nena Sari-Sari Store'**
  String get setupStoreHint;

  /// No description provided for @setupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Nena Reyes'**
  String get setupNameHint;

  /// No description provided for @setupSubmit.
  ///
  /// In en, this message translates to:
  /// **'Start using Kitaza'**
  String get setupSubmit;

  /// No description provided for @setupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not set up. Please try again.'**
  String get setupFailed;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in once. This device will remember you.'**
  String get signInSubtitle;

  /// No description provided for @signInSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInSubmit;

  /// No description provided for @signInCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get signInCreateAccount;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in.'**
  String get signInFailed;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your records stay on this phone and back up to the cloud.'**
  String get signUpSubtitle;

  /// No description provided for @signUpSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpSubmit;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create your account.'**
  String get signUpFailed;

  /// No description provided for @dashboardYourStore.
  ///
  /// In en, this message translates to:
  /// **'Your store'**
  String get dashboardYourStore;

  /// No description provided for @dashboardGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGoodMorning;

  /// No description provided for @dashboardGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGoodAfternoon;

  /// No description provided for @dashboardGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGoodEvening;

  /// No description provided for @dashboardMoneyThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Money this period'**
  String get dashboardMoneyThisPeriod;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add sale\" after your next customer. It takes about five seconds and everything else fills in from there.'**
  String get dashboardEmptyMessage;

  /// No description provided for @dashboardSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get dashboardSales;

  /// No description provided for @dashboardSaleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sale} other{{count} sales}}'**
  String dashboardSaleCount(int count);

  /// No description provided for @dashboardExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get dashboardExpenses;

  /// No description provided for @dashboardCostOfGoods.
  ///
  /// In en, this message translates to:
  /// **'Cost of goods {amount}'**
  String dashboardCostOfGoods(Object amount);

  /// No description provided for @dashboardProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get dashboardProfit;

  /// No description provided for @dashboardMarginOfSales.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of sales'**
  String dashboardMarginOfSales(Object percent);

  /// No description provided for @dashboardCashKept.
  ///
  /// In en, this message translates to:
  /// **'Cash kept'**
  String get dashboardCashKept;

  /// No description provided for @dashboardAfterWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'After your withdrawals'**
  String get dashboardAfterWithdrawals;

  /// No description provided for @dashboardWithdrawalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner withdrawals'**
  String get dashboardWithdrawalsTitle;

  /// No description provided for @dashboardWithdrawalsTaken.
  ///
  /// In en, this message translates to:
  /// **'You took out {amount} this period'**
  String dashboardWithdrawalsTaken(Object amount);

  /// No description provided for @dashboardWithdrawalsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Record money you take for personal use'**
  String get dashboardWithdrawalsPrompt;

  /// No description provided for @dashboardTopSeller.
  ///
  /// In en, this message translates to:
  /// **'Top seller'**
  String get dashboardTopSeller;

  /// No description provided for @dashboardSoldSummary.
  ///
  /// In en, this message translates to:
  /// **'{quantity} sold · {revenue}'**
  String dashboardSoldSummary(Object quantity, Object revenue);

  /// No description provided for @dashboardLowStock.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product running low} other{{count} products running low}}'**
  String dashboardLowStock(int count);

  /// No description provided for @dashboardLowStockHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to see what needs restocking'**
  String get dashboardLowStockHint;

  /// No description provided for @actionAddSale.
  ///
  /// In en, this message translates to:
  /// **'Add sale'**
  String get actionAddSale;

  /// No description provided for @actionExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get actionExpense;

  /// No description provided for @actionProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get actionProfit;

  /// No description provided for @healthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get healthGood;

  /// No description provided for @healthAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get healthAverage;

  /// No description provided for @healthWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get healthWarning;

  /// No description provided for @healthHeadlineGreen.
  ///
  /// In en, this message translates to:
  /// **'Your store is doing well'**
  String get healthHeadlineGreen;

  /// No description provided for @healthHeadlineYellow.
  ///
  /// In en, this message translates to:
  /// **'Keep an eye on your numbers'**
  String get healthHeadlineYellow;

  /// No description provided for @healthHeadlineRed.
  ///
  /// In en, this message translates to:
  /// **'Your store needs attention'**
  String get healthHeadlineRed;

  /// No description provided for @healthHeadlineNoSales.
  ///
  /// In en, this message translates to:
  /// **'No sales recorded yet'**
  String get healthHeadlineNoSales;

  /// No description provided for @healthRatingChip.
  ///
  /// In en, this message translates to:
  /// **'{rating} · {score}'**
  String healthRatingChip(Object rating, int score);

  /// No description provided for @healthReasonNoSales.
  ///
  /// In en, this message translates to:
  /// **'Record your first sale to see how your store is doing.'**
  String get healthReasonNoSales;

  /// No description provided for @healthReasonProfit.
  ///
  /// In en, this message translates to:
  /// **'You earned a profit of {amount}.'**
  String healthReasonProfit(Object amount);

  /// No description provided for @healthReasonLoss.
  ///
  /// In en, this message translates to:
  /// **'You spent {amount} more than you sold.'**
  String healthReasonLoss(Object amount);

  /// No description provided for @healthReasonHealthyMargin.
  ///
  /// In en, this message translates to:
  /// **'Healthy margin: {percent}% of sales is profit.'**
  String healthReasonHealthyMargin(int percent);

  /// No description provided for @healthReasonThinMargin.
  ///
  /// In en, this message translates to:
  /// **'Thin margin: only {percent}% of sales is profit.'**
  String healthReasonThinMargin(int percent);

  /// No description provided for @healthReasonVeryThinMargin.
  ///
  /// In en, this message translates to:
  /// **'Very thin margin: {percent}% of sales is profit.'**
  String healthReasonVeryThinMargin(int percent);

  /// No description provided for @healthReasonProfitUp.
  ///
  /// In en, this message translates to:
  /// **'Profit is higher than the previous period.'**
  String get healthReasonProfitUp;

  /// No description provided for @healthReasonProfitDown.
  ///
  /// In en, this message translates to:
  /// **'Profit is lower than the previous period.'**
  String get healthReasonProfitDown;

  /// No description provided for @healthReasonOverWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'You withdrew {amount}, more than the profit you made.'**
  String healthReasonOverWithdrawn(Object amount);

  /// No description provided for @healthReasonRestock.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product needs restocking.} other{{count} products need restocking.}}'**
  String healthReasonRestock(int count);

  /// No description provided for @saleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add sale'**
  String get saleTitle;

  /// No description provided for @saleProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get saleProduct;

  /// No description provided for @saleTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get saleTotal;

  /// No description provided for @saleTyping.
  ///
  /// In en, this message translates to:
  /// **'Typing {amount}'**
  String saleTyping(Object amount);

  /// No description provided for @saleSaveAmount.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String saleSaveAmount(Object amount);

  /// No description provided for @saleNeedsSomething.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount or pick a product first.'**
  String get saleNeedsSomething;

  /// No description provided for @saleRecorded.
  ///
  /// In en, this message translates to:
  /// **'Sale recorded.'**
  String get saleRecorded;

  /// No description provided for @saleSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the sale. Please try again.'**
  String get saleSaveFailed;

  /// No description provided for @saleProductAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added.'**
  String saleProductAdded(Object name);

  /// No description provided for @saleEach.
  ///
  /// In en, this message translates to:
  /// **'{price} each'**
  String saleEach(Object price);

  /// No description provided for @saleLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get saleLess;

  /// No description provided for @saleMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get saleMore;

  /// No description provided for @saleQuickSale.
  ///
  /// In en, this message translates to:
  /// **'Quick sale'**
  String get saleQuickSale;

  /// No description provided for @saleItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String saleItemCount(int count);

  /// No description provided for @saleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get saleGeneric;

  /// No description provided for @saleHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales in this period'**
  String get saleHistoryEmptyTitle;

  /// No description provided for @saleHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Every sale you record shows up here with its profit.'**
  String get saleHistoryEmptyMessage;

  /// No description provided for @saleHistoryEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add a sale'**
  String get saleHistoryEmptyAction;

  /// No description provided for @saleProfitAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} profit'**
  String saleProfitAmount(Object amount);

  /// No description provided for @saleVoidTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this sale?'**
  String get saleVoidTitle;

  /// No description provided for @saleVoidMessage.
  ///
  /// In en, this message translates to:
  /// **'The amount is removed from your totals and any stock is put back.'**
  String get saleVoidMessage;

  /// No description provided for @saleVoidKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get saleVoidKeep;

  /// No description provided for @saleVoidConfirm.
  ///
  /// In en, this message translates to:
  /// **'Void sale'**
  String get saleVoidConfirm;

  /// No description provided for @saleVoided.
  ///
  /// In en, this message translates to:
  /// **'Sale voided.'**
  String get saleVoided;

  /// No description provided for @salePickerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search product or scan code'**
  String get salePickerSearch;

  /// No description provided for @salePickerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get salePickerEmptyTitle;

  /// No description provided for @salePickerEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You can still record the sale by typing the amount on the keypad.'**
  String get salePickerEmptyMessage;

  /// No description provided for @saleOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get saleOutOfStock;

  /// No description provided for @saleStockLeft.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {unit} left'**
  String saleStockLeft(Object quantity, Object unit);

  /// No description provided for @keypadBackspace.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get keypadBackspace;

  /// No description provided for @keypadBackspaceHint.
  ///
  /// In en, this message translates to:
  /// **'Hold to clear'**
  String get keypadBackspaceHint;

  /// No description provided for @keypadDecimal.
  ///
  /// In en, this message translates to:
  /// **'Decimal point'**
  String get keypadDecimal;

  /// No description provided for @expenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expenseTitle;

  /// No description provided for @expenseWhatFor.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get expenseWhatFor;

  /// No description provided for @expenseNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Meralco bill for October'**
  String get expenseNoteHint;

  /// No description provided for @expenseSave.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get expenseSave;

  /// No description provided for @expenseRecorded.
  ///
  /// In en, this message translates to:
  /// **'Expense recorded.'**
  String get expenseRecorded;

  /// No description provided for @expenseSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get expenseSaveFailed;

  /// No description provided for @expenseHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded'**
  String get expenseHistoryEmptyTitle;

  /// No description provided for @expenseHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Track what you spend on stock, load, transport and bills so your profit is real.'**
  String get expenseHistoryEmptyMessage;

  /// No description provided for @expenseHistoryEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add an expense'**
  String get expenseHistoryEmptyAction;

  /// No description provided for @productAdd.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get productAdd;

  /// No description provided for @productEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productEdit;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @productNameHint.
  ///
  /// In en, this message translates to:
  /// **'Lucky Me Pancit Canton'**
  String get productNameHint;

  /// No description provided for @productCost.
  ///
  /// In en, this message translates to:
  /// **'Cost (puhunan)'**
  String get productCost;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get productPrice;

  /// No description provided for @productStock.
  ///
  /// In en, this message translates to:
  /// **'Stock on hand'**
  String get productStock;

  /// No description provided for @productReorder.
  ///
  /// In en, this message translates to:
  /// **'Warn me below'**
  String get productReorder;

  /// No description provided for @productSave.
  ///
  /// In en, this message translates to:
  /// **'Save product'**
  String get productSave;

  /// No description provided for @productSaved.
  ///
  /// In en, this message translates to:
  /// **'Product saved.'**
  String get productSaved;

  /// No description provided for @productSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the product.'**
  String get productSaveFailed;

  /// No description provided for @productSearch.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get productSearch;

  /// No description provided for @productEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get productEmptyTitle;

  /// No description provided for @productEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Adding your regular items makes each sale one tap, and lets Kitaza tell you which ones actually earn.'**
  String get productEmptyMessage;

  /// No description provided for @productEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add your first product'**
  String get productEmptyAction;

  /// No description provided for @productMargin.
  ///
  /// In en, this message translates to:
  /// **'{percent}% margin'**
  String productMargin(Object percent);

  /// No description provided for @productRestock.
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get productRestock;

  /// No description provided for @productStockUnits.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {unit}'**
  String productStockUnits(Object quantity, Object unit);

  /// No description provided for @productWouldLose.
  ///
  /// In en, this message translates to:
  /// **'You would lose {amount} per sale'**
  String productWouldLose(Object amount);

  /// No description provided for @productEarns.
  ///
  /// In en, this message translates to:
  /// **'You earn {amount} ({percent}%) per sale'**
  String productEarns(Object amount, Object percent);

  /// No description provided for @withdrawalTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner withdrawals'**
  String get withdrawalTitle;

  /// No description provided for @withdrawalRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get withdrawalRecord;

  /// No description provided for @withdrawalEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No withdrawals recorded'**
  String get withdrawalEmptyTitle;

  /// No description provided for @withdrawalEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'When you take money from the store for personal use, record it here so your profit stays accurate.'**
  String get withdrawalEmptyMessage;

  /// No description provided for @withdrawalExplainer.
  ///
  /// In en, this message translates to:
  /// **'Money you take home is not a business expense. Recording it here keeps your profit honest and shows what is really left.'**
  String get withdrawalExplainer;

  /// No description provided for @withdrawalDefaultReason.
  ///
  /// In en, this message translates to:
  /// **'Personal withdrawal'**
  String get withdrawalDefaultReason;

  /// No description provided for @withdrawalRecorded.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal recorded.'**
  String get withdrawalRecorded;

  /// No description provided for @withdrawalSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Money taken out'**
  String get withdrawalSheetTitle;

  /// No description provided for @withdrawalReason.
  ///
  /// In en, this message translates to:
  /// **'What for? (optional)'**
  String get withdrawalReason;

  /// No description provided for @withdrawalReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Grocery, tuition, allowance'**
  String get withdrawalReasonHint;

  /// No description provided for @withdrawalSubmit.
  ///
  /// In en, this message translates to:
  /// **'Record withdrawal'**
  String get withdrawalSubmit;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportTitle;

  /// No description provided for @reportEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to report yet'**
  String get reportEmptyTitle;

  /// No description provided for @reportEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Record a few sales and expenses and this screen will show which products earn, where your money goes, and how your profit is trending.'**
  String get reportEmptyMessage;

  /// No description provided for @reportTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily profit, last 14 days'**
  String get reportTrendTitle;

  /// No description provided for @reportTrendHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a bar to see that day'**
  String get reportTrendHint;

  /// No description provided for @reportTrendSummary.
  ///
  /// In en, this message translates to:
  /// **'Daily profit over the last {days} days. Best day {bestDay}, {bestAmount}. Worst day {worstDay}, {worstAmount}.'**
  String reportTrendSummary(
    int days,
    Object bestDay,
    Object bestAmount,
    Object worstDay,
    Object worstAmount,
  );

  /// No description provided for @reportTopProducts.
  ///
  /// In en, this message translates to:
  /// **'Where your profit comes from'**
  String get reportTopProducts;

  /// No description provided for @reportExpenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Where your money goes'**
  String get reportExpenseBreakdown;

  /// No description provided for @reportUnusual.
  ///
  /// In en, this message translates to:
  /// **'Worth a second look'**
  String get reportUnusual;

  /// No description provided for @reportUnusualDetail.
  ///
  /// In en, this message translates to:
  /// **'{times}x your usual {average} · {date}'**
  String reportUnusualDetail(Object times, Object average, Object date);

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Dark mode is easier at night; Auto follows your phone.'**
  String get settingsAppearanceHint;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsThemeAuto;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsLanguageAuto;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageFilipino.
  ///
  /// In en, this message translates to:
  /// **'Filipino'**
  String get settingsLanguageFilipino;

  /// No description provided for @settingsYourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsYourData;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @storageLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone only'**
  String get storageLocalTitle;

  /// No description provided for @storageLocalRisk.
  ///
  /// In en, this message translates to:
  /// **'If this phone is lost or broken, your records go with it.'**
  String get storageLocalRisk;

  /// No description provided for @storageBackUp.
  ///
  /// In en, this message translates to:
  /// **'Back up to the cloud'**
  String get storageBackUp;

  /// No description provided for @storageBackUpHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps everything you have recorded so far'**
  String get storageBackUpHint;

  /// No description provided for @storageCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Backed up to the cloud'**
  String get storageCloudTitle;

  /// No description provided for @storageNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get storageNotSynced;

  /// No description provided for @storageLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {when}'**
  String storageLastSynced(Object when);

  /// No description provided for @storagePending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 waiting to upload} other{{count} waiting to upload}}'**
  String storagePending(int count);

  /// No description provided for @storagePendingHint.
  ///
  /// In en, this message translates to:
  /// **'These go up as soon as you have signal.'**
  String get storagePendingHint;

  /// No description provided for @storageParked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 could not be saved} other{{count} could not be saved}}'**
  String storageParked(int count);

  /// No description provided for @storageParkedHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to see why and decide what to do'**
  String get storageParkedHint;

  /// No description provided for @storageSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get storageSyncNow;

  /// No description provided for @storageUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Everything is up to date.'**
  String get storageUpToDate;

  /// No description provided for @storageUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the cloud. Will try again.'**
  String get storageUnreachable;

  /// No description provided for @syncSavedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get syncSavedOnPhone;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncSyncing;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncOffline;

  /// No description provided for @syncBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Backed up'**
  String get syncBackedUp;

  /// No description provided for @syncProblem.
  ///
  /// In en, this message translates to:
  /// **'Sync problem'**
  String get syncProblem;

  /// No description provided for @syncWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 waiting to sync} other{{count} waiting to sync}}'**
  String syncWaiting(int count);

  /// No description provided for @problemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync problems'**
  String get problemsTitle;

  /// No description provided for @problemsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing is stuck'**
  String get problemsEmptyTitle;

  /// No description provided for @problemsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Every entry has reached the cloud or is waiting its turn.'**
  String get problemsEmptyMessage;

  /// No description provided for @problemsRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused by the server'**
  String get problemsRefused;

  /// No description provided for @problemsStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped retrying after {count} attempts.'**
  String problemsStopped(int count);

  /// No description provided for @problemsWillRetry.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Tried once; will retry.} other{Tried {count} times; will retry.}}'**
  String problemsWillRetry(int count);

  /// No description provided for @problemsKeepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep on phone only'**
  String get problemsKeepLocal;

  /// No description provided for @problemsDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop uploading this?'**
  String get problemsDiscardTitle;

  /// No description provided for @problemsDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'It stays in your records on this phone, but other devices and the cloud backup will not have it.'**
  String get problemsDiscardMessage;

  /// No description provided for @problemsSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get problemsSale;

  /// No description provided for @problemsExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense: {detail}'**
  String problemsExpense(Object detail);

  /// No description provided for @problemsWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get problemsWithdrawal;

  /// No description provided for @problemsProduct.
  ///
  /// In en, this message translates to:
  /// **'Product: {name}'**
  String problemsProduct(Object name);

  /// No description provided for @problemsStockChange.
  ///
  /// In en, this message translates to:
  /// **'Stock change'**
  String get problemsStockChange;

  /// No description provided for @problemsRemoval.
  ///
  /// In en, this message translates to:
  /// **'Removal of a {entity}'**
  String problemsRemoval(Object entity);

  /// No description provided for @problemsChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get problemsChange;

  /// No description provided for @upgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up to the cloud'**
  String get upgradeTitle;

  /// No description provided for @upgradeIntro.
  ///
  /// In en, this message translates to:
  /// **'Everything you have recorded on this phone stays, and is copied to your account. The app keeps working offline exactly as before.'**
  String get upgradeIntro;

  /// No description provided for @upgradeNewAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get upgradeNewAccount;

  /// No description provided for @upgradeExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'I have one'**
  String get upgradeExistingAccount;

  /// No description provided for @upgradeExistingNote.
  ///
  /// In en, this message translates to:
  /// **'This phone\'s records will be added to the store on that account.'**
  String get upgradeExistingNote;

  /// No description provided for @upgradeCreateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create account and back up'**
  String get upgradeCreateSubmit;

  /// No description provided for @upgradeSignInSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in and back up'**
  String get upgradeSignInSubmit;

  /// No description provided for @upgradeDone.
  ///
  /// In en, this message translates to:
  /// **'Your store is now backed up.'**
  String get upgradeDone;

  /// No description provided for @upgradeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not back up right now. Nothing was changed.'**
  String get upgradeFailed;

  /// No description provided for @accountOfflineProfile.
  ///
  /// In en, this message translates to:
  /// **'Offline profile'**
  String get accountOfflineProfile;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get accountSignOutTitle;

  /// No description provided for @accountSignOutLocal.
  ///
  /// In en, this message translates to:
  /// **'Your records are only on this phone. Signing out erases them for good.'**
  String get accountSignOutLocal;

  /// No description provided for @accountSignOutClean.
  ///
  /// In en, this message translates to:
  /// **'Everything is backed up. Sign back in on any phone to pick up where you left off.'**
  String get accountSignOutClean;

  /// No description provided for @accountSignOutUnsent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change has not reached the cloud yet, and will be lost if you sign out now. Try again when you have signal.} other{{count} changes have not reached the cloud yet, and will be lost if you sign out now. Try again when you have signal.}}'**
  String accountSignOutUnsent(int count);

  /// No description provided for @accountEraseAndSignOut.
  ///
  /// In en, this message translates to:
  /// **'Erase and sign out'**
  String get accountEraseAndSignOut;

  /// No description provided for @starterTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with common products'**
  String get starterTitle;

  /// No description provided for @starterIntro.
  ///
  /// In en, this message translates to:
  /// **'Tick what you sell. You can change names and prices any time.'**
  String get starterIntro;

  /// No description provided for @starterPricesNotice.
  ///
  /// In en, this message translates to:
  /// **'These are typical prices, not yours. Check each item\'s cost and price so your profit figures are right.'**
  String get starterPricesNotice;

  /// No description provided for @starterAdd.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Pick at least one} =1{Add 1 product} other{Add {count} products}}'**
  String starterAdd(int count);

  /// No description provided for @starterAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product added. Check its price when you can.} other{{count} products added. Check their prices when you can.}}'**
  String starterAdded(int count);

  /// No description provided for @starterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get starterAll;

  /// No description provided for @starterOffer.
  ///
  /// In en, this message translates to:
  /// **'Add common sari-sari items'**
  String get starterOffer;

  /// No description provided for @starterPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Your product list is empty'**
  String get starterPromptTitle;

  /// No description provided for @starterPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Start with the usual sari-sari items, then each sale is one tap.'**
  String get starterPromptMessage;

  /// No description provided for @backupSection.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get backupSection;

  /// No description provided for @backupAutoNone.
  ///
  /// In en, this message translates to:
  /// **'No automatic copy yet. One is made each day you open the app.'**
  String get backupAutoNone;

  /// No description provided for @backupAutoLast.
  ///
  /// In en, this message translates to:
  /// **'A copy is saved on this phone each day. Last copy: {when}'**
  String backupAutoLast(Object when);

  /// No description provided for @backupCloudNote.
  ///
  /// In en, this message translates to:
  /// **'Your records are also kept in the cloud.'**
  String get backupCloudNote;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Save a backup copy'**
  String get backupExport;

  /// No description provided for @backupExportHint.
  ///
  /// In en, this message translates to:
  /// **'Send it to yourself on Messenger, Drive or email so it survives if this phone is lost.'**
  String get backupExportHint;

  /// No description provided for @backupExportText.
  ///
  /// In en, this message translates to:
  /// **'Kitaza backup for {store}. Keep this file somewhere safe.'**
  String backupExportText(Object store);

  /// No description provided for @backupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create a backup copy.'**
  String get backupExportFailed;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup file'**
  String get backupRestore;

  /// No description provided for @backupRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Replaces everything on this phone with the records in the file.'**
  String get backupRestoreHint;

  /// No description provided for @backupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get backupConfirmTitle;

  /// No description provided for @backupConfirmSummary.
  ///
  /// In en, this message translates to:
  /// **'{store}: {sales, plural, =1{1 sale} other{{sales} sales}} and {products, plural, =1{1 product} other{{products} products}}.'**
  String backupConfirmSummary(Object store, int sales, int products);

  /// No description provided for @backupConfirmLastEntry.
  ///
  /// In en, this message translates to:
  /// **'Last entry: {when}.'**
  String backupConfirmLastEntry(Object when);

  /// No description provided for @backupConfirmWarning.
  ///
  /// In en, this message translates to:
  /// **'Everything currently on this phone will be replaced.'**
  String get backupConfirmWarning;

  /// No description provided for @backupConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Replace and restore'**
  String get backupConfirmAction;

  /// No description provided for @backupProblemNotABackup.
  ///
  /// In en, this message translates to:
  /// **'That file is not a Kitaza backup.'**
  String get backupProblemNotABackup;

  /// No description provided for @backupProblemTooNew.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of Kitaza. Update the app, then try again.'**
  String get backupProblemTooNew;

  /// No description provided for @backupProblemDamaged.
  ///
  /// In en, this message translates to:
  /// **'This backup file is damaged and cannot be restored.'**
  String get backupProblemDamaged;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 problem report} other{{count} problem reports}}'**
  String reportsTitle(int count);

  /// No description provided for @reportsCloudHint.
  ///
  /// In en, this message translates to:
  /// **'Sent to the Kitaza team automatically when you sync.'**
  String get reportsCloudHint;

  /// No description provided for @reportsLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to send them to the Kitaza team. They hold no sales or customer details.'**
  String get reportsLocalHint;

  /// No description provided for @reportsShareIntro.
  ///
  /// In en, this message translates to:
  /// **'Kitaza problem reports. They hold no sales or customer details.'**
  String get reportsShareIntro;

  /// No description provided for @scanAction.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanAction;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the barcode'**
  String get scanHint;

  /// No description provided for @scanLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get scanLight;

  /// No description provided for @scanDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get scanDone;

  /// No description provided for @scanAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String scanAdded(Object name);

  /// No description provided for @scanUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'No product has this code yet'**
  String get scanUnknownTitle;

  /// No description provided for @scanUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'Code {code}. Add it as a new product so the next scan finds it.'**
  String scanUnknownMessage(Object code);

  /// No description provided for @scanAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add as new product'**
  String get scanAddProduct;

  /// No description provided for @scanNoCamera.
  ///
  /// In en, this message translates to:
  /// **'Kitaza needs the camera to scan barcodes. Allow it in your phone\'s settings.'**
  String get scanNoCamera;

  /// No description provided for @productBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode (optional)'**
  String get productBarcode;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get receiptSubtotal;

  /// No description provided for @receiptDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get receiptDiscount;

  /// No description provided for @receiptTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get receiptTotal;

  /// No description provided for @receiptPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get receiptPaidBy;

  /// No description provided for @receiptReference.
  ///
  /// In en, this message translates to:
  /// **'Ref {code}'**
  String receiptReference(Object code);

  /// No description provided for @receiptThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get receiptThanks;

  /// No description provided for @receiptShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get receiptShare;

  /// No description provided for @receiptPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get receiptPrint;

  /// No description provided for @receiptPrinted.
  ///
  /// In en, this message translates to:
  /// **'Receipt printed.'**
  String get receiptPrinted;

  /// No description provided for @receiptNoPrinter.
  ///
  /// In en, this message translates to:
  /// **'No receipt printer yet. Set one up in Settings.'**
  String get receiptNoPrinter;

  /// No description provided for @printerSection.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer'**
  String get printerSection;

  /// No description provided for @printerNone.
  ///
  /// In en, this message translates to:
  /// **'None chosen'**
  String get printerNone;

  /// No description provided for @printerChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose printer'**
  String get printerChoose;

  /// No description provided for @printerChooseHint.
  ///
  /// In en, this message translates to:
  /// **'Pair the printer in your phone\'s Bluetooth settings first, then pick it here.'**
  String get printerChooseHint;

  /// No description provided for @printerNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No paired Bluetooth devices. Pair your printer in your phone\'s Bluetooth settings first.'**
  String get printerNoneFound;

  /// No description provided for @printerPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper width'**
  String get printerPaper;

  /// No description provided for @printerTest.
  ///
  /// In en, this message translates to:
  /// **'Print a test receipt'**
  String get printerTest;

  /// No description provided for @printerTestLine.
  ///
  /// In en, this message translates to:
  /// **'Printer test - if you can read this, it works.'**
  String get printerTestLine;

  /// No description provided for @printerBluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn it on and try again.'**
  String get printerBluetoothOff;

  /// No description provided for @printerNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Kitaza needs Bluetooth permission to print. Allow it in your phone\'s settings.'**
  String get printerNoPermission;

  /// No description provided for @printerCouldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the printer. Check that it is on and nearby.'**
  String get printerCouldNotConnect;

  /// No description provided for @printerFailed.
  ///
  /// In en, this message translates to:
  /// **'The printer did not accept the receipt. Try again.'**
  String get printerFailed;

  /// No description provided for @welcomeJoinStaff.
  ///
  /// In en, this message translates to:
  /// **'Join a store as staff'**
  String get welcomeJoinStaff;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a store'**
  String get joinTitle;

  /// No description provided for @joinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask the store owner for a join code. They make one in Settings, under Staff.'**
  String get joinSubtitle;

  /// No description provided for @joinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Join code'**
  String get joinCodeLabel;

  /// No description provided for @joinCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter all 10 letters and numbers of the code'**
  String get joinCodeInvalid;

  /// No description provided for @joinAction.
  ///
  /// In en, this message translates to:
  /// **'Join store'**
  String get joinAction;

  /// No description provided for @joinCodeRefused.
  ///
  /// In en, this message translates to:
  /// **'That code did not work. It may have been used already or expired. Ask the owner for a new one.'**
  String get joinCodeRefused;

  /// No description provided for @joinSharedPhoneNote.
  ///
  /// In en, this message translates to:
  /// **'Each code works on one phone. Anything recorded here goes to the store, under your name.'**
  String get joinSharedPhoneNote;

  /// No description provided for @sessionEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'This phone was signed out'**
  String get sessionEndedTitle;

  /// No description provided for @sessionEndedMessage.
  ///
  /// In en, this message translates to:
  /// **'{store} was signed out on this phone from another device, or your access to it was removed.'**
  String sessionEndedMessage(Object store);

  /// No description provided for @sessionEndedUnsent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Everything recorded here had already reached the cloud.} =1{1 entry recorded here has not reached the cloud yet. Sign back in to send it.} other{{count} entries recorded here have not reached the cloud yet. Sign back in to send them.}}'**
  String sessionEndedUnsent(int count);

  /// No description provided for @sessionEndedSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get sessionEndedSignIn;

  /// No description provided for @sessionEndedJoin.
  ///
  /// In en, this message translates to:
  /// **'Enter a new join code'**
  String get sessionEndedJoin;

  /// No description provided for @sessionEndedClear.
  ///
  /// In en, this message translates to:
  /// **'Remove this store from the phone'**
  String get sessionEndedClear;

  /// No description provided for @sessionEndedClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this store\'s records?'**
  String get sessionEndedClearTitle;

  /// No description provided for @sessionEndedClearMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Everything here is already in the cloud, so nothing will be lost.} =1{1 entry that never reached the cloud will be lost for good.} other{{count} entries that never reached the cloud will be lost for good.}}'**
  String sessionEndedClearMessage(int count);

  /// No description provided for @sessionEndedClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get sessionEndedClearConfirm;

  /// No description provided for @settingsTeam.
  ///
  /// In en, this message translates to:
  /// **'Stores and staff'**
  String get settingsTeam;

  /// No description provided for @storesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a store to open it. Each keeps its own products, sales and staff.'**
  String get storesHint;

  /// No description provided for @storesOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get storesOpenNow;

  /// No description provided for @storesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add another store'**
  String get storesAdd;

  /// No description provided for @storesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New store'**
  String get storesAddTitle;

  /// No description provided for @storesAddSubmit.
  ///
  /// In en, this message translates to:
  /// **'Add store'**
  String get storesAddSubmit;

  /// No description provided for @storesRename.
  ///
  /// In en, this message translates to:
  /// **'Rename store'**
  String get storesRename;

  /// No description provided for @storesSwitched.
  ///
  /// In en, this message translates to:
  /// **'Now working in {store}'**
  String storesSwitched(Object store);

  /// No description provided for @storesPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Open a store'**
  String get storesPickerTitle;

  /// No description provided for @storesSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Switch store'**
  String get storesSwitchHint;

  /// No description provided for @teamLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff and more stores'**
  String get teamLocalTitle;

  /// No description provided for @teamLocalMessage.
  ///
  /// In en, this message translates to:
  /// **'Staff accounts, more than one store and signing out a lost phone all need your records in the cloud.'**
  String get teamLocalMessage;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffTitle;

  /// No description provided for @staffTileHint.
  ///
  /// In en, this message translates to:
  /// **'Let helpers sell from their own phone'**
  String get staffTileHint;

  /// No description provided for @staffEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No staff yet'**
  String get staffEmptyTitle;

  /// No description provided for @staffEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the people who help at the counter. They sell from their own phone, and you choose what else they can do.'**
  String get staffEmptyMessage;

  /// No description provided for @staffAdd.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get staffAdd;

  /// No description provided for @staffNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Their name'**
  String get staffNameLabel;

  /// No description provided for @staffAlwaysSells.
  ///
  /// In en, this message translates to:
  /// **'Staff can always record sales. Choose what else they may do:'**
  String get staffAlwaysSells;

  /// No description provided for @permissionManageProducts.
  ///
  /// In en, this message translates to:
  /// **'Manage products'**
  String get permissionManageProducts;

  /// No description provided for @permissionManageProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Add and edit products and prices, record deliveries and stock counts'**
  String get permissionManageProductsHint;

  /// No description provided for @permissionRecordExpenses.
  ///
  /// In en, this message translates to:
  /// **'Record expenses'**
  String get permissionRecordExpenses;

  /// No description provided for @permissionRecordExpensesHint.
  ///
  /// In en, this message translates to:
  /// **'Write down what the store spends'**
  String get permissionRecordExpensesHint;

  /// No description provided for @permissionViewProfit.
  ///
  /// In en, this message translates to:
  /// **'See profit and costs'**
  String get permissionViewProfit;

  /// No description provided for @permissionViewProfitHint.
  ///
  /// In en, this message translates to:
  /// **'Cost prices, profit, expenses and the health score. Without this, costs never reach their phone.'**
  String get permissionViewProfitHint;

  /// No description provided for @permissionDeleteRecords.
  ///
  /// In en, this message translates to:
  /// **'Void and delete'**
  String get permissionDeleteRecords;

  /// No description provided for @permissionDeleteRecordsHint.
  ///
  /// In en, this message translates to:
  /// **'Void sales and delete expenses. Every void is kept in the activity log.'**
  String get permissionDeleteRecordsHint;

  /// No description provided for @staffSells.
  ///
  /// In en, this message translates to:
  /// **'Sells'**
  String get staffSells;

  /// No description provided for @staffShortProducts.
  ///
  /// In en, this message translates to:
  /// **'products'**
  String get staffShortProducts;

  /// No description provided for @staffShortExpenses.
  ///
  /// In en, this message translates to:
  /// **'expenses'**
  String get staffShortExpenses;

  /// No description provided for @staffShortProfit.
  ///
  /// In en, this message translates to:
  /// **'profit'**
  String get staffShortProfit;

  /// No description provided for @staffShortDelete.
  ///
  /// In en, this message translates to:
  /// **'voids'**
  String get staffShortDelete;

  /// No description provided for @staffDevices.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not signed in yet} =1{Signed in on 1 phone} other{Signed in on {count} phones}}'**
  String staffDevices(int count);

  /// No description provided for @staffCodeWorksUntil.
  ///
  /// In en, this message translates to:
  /// **'Join code works until {when}'**
  String staffCodeWorksUntil(Object when);

  /// No description provided for @staffNewCode.
  ///
  /// In en, this message translates to:
  /// **'Make a new join code'**
  String get staffNewCode;

  /// No description provided for @staffNewCodeHint.
  ///
  /// In en, this message translates to:
  /// **'For a new or replaced phone. Any earlier code stops working.'**
  String get staffNewCodeHint;

  /// No description provided for @staffRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from store'**
  String get staffRemove;

  /// No description provided for @staffRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String staffRemoveTitle(Object name);

  /// No description provided for @staffRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s phone will be signed out straight away. Sales on it that have not reached the cloud yet will not arrive.'**
  String staffRemoveMessage(Object name);

  /// No description provided for @staffRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} was removed'**
  String staffRemoved(Object name);

  /// No description provided for @staffSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Their phone picks this up within a few minutes.'**
  String get staffSaved;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Join code for {name}'**
  String inviteTitle(Object name);

  /// No description provided for @inviteSteps.
  ///
  /// In en, this message translates to:
  /// **'On {name}\'s phone, open Kitaza, tap “Join a store as staff” and enter this code.'**
  String inviteSteps(Object name);

  /// No description provided for @inviteExpires.
  ///
  /// In en, this message translates to:
  /// **'Works on one phone, until {when}.'**
  String inviteExpires(Object when);

  /// No description provided for @inviteShare.
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get inviteShare;

  /// No description provided for @inviteCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get inviteCopy;

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get inviteCopied;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join {store} on Kitaza: open Kitaza, tap “Join a store as staff” and enter {code}. The code works once, for one day.'**
  String inviteShareText(Object store, Object code);

  /// No description provided for @inviteDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get inviteDone;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Signed-in devices'**
  String get devicesTitle;

  /// No description provided for @devicesTileHint.
  ///
  /// In en, this message translates to:
  /// **'Every phone using your stores. Sign out one that was lost.'**
  String get devicesTileHint;

  /// No description provided for @devicesIntro.
  ///
  /// In en, this message translates to:
  /// **'Every phone that can open your stores. Sign out one that was lost, sold, or belongs to someone who left.'**
  String get devicesIntro;

  /// No description provided for @devicesThisPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get devicesThisPhone;

  /// No description provided for @devicesYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get devicesYou;

  /// No description provided for @devicesStaff.
  ///
  /// In en, this message translates to:
  /// **'{name}, staff'**
  String devicesStaff(Object name);

  /// No description provided for @devicesLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active {when}'**
  String devicesLastActive(Object when);

  /// No description provided for @devicesSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get devicesSignOut;

  /// No description provided for @devicesSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out {device}?'**
  String devicesSignOutTitle(Object device);

  /// No description provided for @devicesSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'It stops syncing straight away and has to sign in again to be used. Anything on it that has not reached the cloud yet will not arrive.'**
  String get devicesSignOutMessage;

  /// No description provided for @devicesSignedOut.
  ///
  /// In en, this message translates to:
  /// **'{device} was signed out'**
  String devicesSignedOut(Object device);

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activityTileHint.
  ///
  /// In en, this message translates to:
  /// **'Who recorded, changed and voided what'**
  String get activityTileHint;

  /// No description provided for @activityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get activityFilterAll;

  /// No description provided for @activityFilterRemovals.
  ///
  /// In en, this message translates to:
  /// **'Voids and deletions'**
  String get activityFilterRemovals;

  /// No description provided for @activityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get activityEmptyTitle;

  /// No description provided for @activityEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Sales, changes and voids from every phone are listed here, with who made them.'**
  String get activityEmptyMessage;

  /// No description provided for @activityShowOlder.
  ///
  /// In en, this message translates to:
  /// **'Show older'**
  String get activityShowOlder;

  /// No description provided for @activitySaleRecorded.
  ///
  /// In en, this message translates to:
  /// **'{name} recorded a sale of {amount}'**
  String activitySaleRecorded(Object name, Object amount);

  /// No description provided for @activitySaleVoided.
  ///
  /// In en, this message translates to:
  /// **'{name} voided a sale of {amount}'**
  String activitySaleVoided(Object name, Object amount);

  /// No description provided for @activityExpenseRecorded.
  ///
  /// In en, this message translates to:
  /// **'{name} recorded {amount} for {category}'**
  String activityExpenseRecorded(Object name, Object amount, Object category);

  /// No description provided for @activityExpenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted {amount} for {category}'**
  String activityExpenseDeleted(Object name, Object amount, Object category);

  /// No description provided for @activityWithdrawalRecorded.
  ///
  /// In en, this message translates to:
  /// **'{name} took out {amount} for personal use'**
  String activityWithdrawalRecorded(Object name, Object amount);

  /// No description provided for @activityWithdrawalDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted a withdrawal of {amount}'**
  String activityWithdrawalDeleted(Object name, Object amount);

  /// No description provided for @activityProductAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added {product} at {price}'**
  String activityProductAdded(Object name, Object product, Object price);

  /// No description provided for @activityProductChanged.
  ///
  /// In en, this message translates to:
  /// **'{name} changed {product}'**
  String activityProductChanged(Object name, Object product);

  /// No description provided for @activityProductRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed {product}'**
  String activityProductRemoved(Object name, Object product);

  /// No description provided for @activityPriceChange.
  ///
  /// In en, this message translates to:
  /// **'Price {before} to {after}'**
  String activityPriceChange(Object before, Object after);

  /// No description provided for @activityCostChange.
  ///
  /// In en, this message translates to:
  /// **'Cost {before} to {after}'**
  String activityCostChange(Object before, Object after);

  /// No description provided for @activityRenamedFrom.
  ///
  /// In en, this message translates to:
  /// **'Was “{before}”'**
  String activityRenamedFrom(Object before);

  /// No description provided for @activityStockReceived.
  ///
  /// In en, this message translates to:
  /// **'{name} received {quantity} {product}'**
  String activityStockReceived(Object name, Object quantity, Object product);

  /// No description provided for @activityStockRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} took out {quantity} {product}'**
  String activityStockRemoved(Object name, Object quantity, Object product);

  /// No description provided for @activityStockCounted.
  ///
  /// In en, this message translates to:
  /// **'{name} counted {quantity} {product}'**
  String activityStockCounted(Object name, Object quantity, Object product);

  /// No description provided for @activityStockDifference.
  ///
  /// In en, this message translates to:
  /// **'{change} from what was expected'**
  String activityStockDifference(Object change);

  /// No description provided for @activityStockSpoiled.
  ///
  /// In en, this message translates to:
  /// **'{name} marked {quantity} {product} as spoiled'**
  String activityStockSpoiled(Object name, Object quantity, Object product);

  /// No description provided for @activityStaffAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added {staff} as staff'**
  String activityStaffAdded(Object name, Object staff);

  /// No description provided for @activityStaffChanged.
  ///
  /// In en, this message translates to:
  /// **'{name} changed what {staff} can do'**
  String activityStaffChanged(Object name, Object staff);

  /// No description provided for @activityStaffRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed {staff}'**
  String activityStaffRemoved(Object name, Object staff);

  /// No description provided for @activityStaffInvited.
  ///
  /// In en, this message translates to:
  /// **'{name} made a join code for {staff}'**
  String activityStaffInvited(Object name, Object staff);

  /// No description provided for @activityStaffJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined on {device}'**
  String activityStaffJoined(Object name, Object device);

  /// No description provided for @activityDeviceSignedOut.
  ///
  /// In en, this message translates to:
  /// **'{name} signed out {member}\'s {device}'**
  String activityDeviceSignedOut(Object name, Object member, Object device);

  /// No description provided for @activityStoreAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} opened {store}'**
  String activityStoreAdded(Object name, Object store);

  /// No description provided for @activityStoreRenamed.
  ///
  /// In en, this message translates to:
  /// **'{name} renamed {before} to {store}'**
  String activityStoreRenamed(Object name, Object before, Object store);

  /// No description provided for @activityOther.
  ///
  /// In en, this message translates to:
  /// **'{name} made a change'**
  String activityOther(Object name);

  /// No description provided for @activityStaffBadge.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get activityStaffBadge;

  /// No description provided for @accountStaffAt.
  ///
  /// In en, this message translates to:
  /// **'Staff at {store}'**
  String accountStaffAt(Object store);

  /// No description provided for @accountStaffSignOutNote.
  ///
  /// In en, this message translates to:
  /// **'To use this phone again, you will need a new join code from the owner.'**
  String get accountStaffSignOutNote;

  /// No description provided for @productCostSetByOwner.
  ///
  /// In en, this message translates to:
  /// **'The owner sets the cost price.'**
  String get productCostSetByOwner;

  /// No description provided for @syncNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Your access does not allow this. Ask the owner.'**
  String get syncNotAllowed;

  /// No description provided for @settingsPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get settingsPlan;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get planTitle;

  /// No description provided for @planStatusTrial.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Free Pro trial, 1 day left} other{Free Pro trial, {count} days left}}'**
  String planStatusTrial(int count);

  /// No description provided for @planStatusActive.
  ///
  /// In en, this message translates to:
  /// **'{plan}, paid until {date}'**
  String planStatusActive(Object plan, Object date);

  /// No description provided for @planStatusGrace.
  ///
  /// In en, this message translates to:
  /// **'Your plan has ended. Everything keeps working until {date}.'**
  String planStatusGrace(Object date);

  /// No description provided for @planStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup is paused. Everything you record is kept on this phone and uploads as soon as you renew.'**
  String get planStatusPaused;

  /// No description provided for @planStatusUnlimited.
  ///
  /// In en, this message translates to:
  /// **'This server does not charge. Everything is included.'**
  String get planStatusUnlimited;

  /// No description provided for @planBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get planBasic;

  /// No description provided for @planPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get planPro;

  /// No description provided for @planBasicPoints.
  ///
  /// In en, this message translates to:
  /// **'Backup and sync for one store, on all your phones'**
  String get planBasicPoints;

  /// No description provided for @planProPoints.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 stores, staff accounts, and everything in Basic'**
  String get planProPoints;

  /// No description provided for @planPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} a month'**
  String planPerMonth(Object price);

  /// No description provided for @planPerYear.
  ///
  /// In en, this message translates to:
  /// **'{price} a year'**
  String planPerYear(Object price);

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly, 2 months free'**
  String get planYearly;

  /// No description provided for @planPay.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} with GCash or Maya'**
  String planPay(Object amount);

  /// No description provided for @planPayHint.
  ///
  /// In en, this message translates to:
  /// **'You pay ahead, like buying load. Nothing is ever charged automatically.'**
  String get planPayHint;

  /// No description provided for @planFinishInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Finish paying on the page that opened. Kitaza updates when you come back.'**
  String get planFinishInBrowser;

  /// No description provided for @planCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open the payment page. Try again.'**
  String get planCouldNotOpen;

  /// No description provided for @planPaid.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your plan is updated.'**
  String get planPaid;

  /// No description provided for @planCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get planCurrent;

  /// No description provided for @planHistory.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get planHistory;

  /// No description provided for @planOneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get planOneMonth;

  /// No description provided for @planOneYear.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get planOneYear;

  /// No description provided for @planLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Kitaza offline for free'**
  String get planLeaveTitle;

  /// No description provided for @planLeaveHint.
  ///
  /// In en, this message translates to:
  /// **'Keep everything on this phone and stop syncing. Your records in the cloud stay there.'**
  String get planLeaveHint;

  /// No description provided for @planLeaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch this phone to offline?'**
  String get planLeaveConfirmTitle;

  /// No description provided for @planLeaveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This phone keeps every record and stops syncing. Your other phones and staff will no longer see what is recorded here. You can move back to the cloud any time.'**
  String get planLeaveConfirmMessage;

  /// No description provided for @planLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Use offline'**
  String get planLeaveConfirm;

  /// No description provided for @planLeft.
  ///
  /// In en, this message translates to:
  /// **'This phone now works offline. Nothing was lost.'**
  String get planLeft;

  /// No description provided for @planPausedShort.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup is paused until the plan is renewed. This entry is kept on the phone.'**
  String get planPausedShort;

  /// No description provided for @planUpgradeNeeded.
  ///
  /// In en, this message translates to:
  /// **'This needs Kitaza Pro.'**
  String get planUpgradeNeeded;

  /// No description provided for @planBannerTrial.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Your free trial ends in 1 day.} other{Your free trial ends in {count} days.}}'**
  String planBannerTrial(int count);

  /// No description provided for @planBannerEnding.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Your plan ends in 1 day.} other{Your plan ends in {count} days.}}'**
  String planBannerEnding(int count);

  /// No description provided for @planBannerGrace.
  ///
  /// In en, this message translates to:
  /// **'Your plan has ended. Syncing continues until {date}.'**
  String planBannerGrace(Object date);

  /// No description provided for @planBannerPaused.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup is paused. Your entries are kept on this phone.'**
  String get planBannerPaused;

  /// No description provided for @planBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get planBannerAction;

  /// No description provided for @planBannerStaff.
  ///
  /// In en, this message translates to:
  /// **'Ask the owner to renew the store\'s plan.'**
  String get planBannerStaff;

  /// No description provided for @syncPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused, saved on this phone'**
  String get syncPaused;

  /// No description provided for @activitySubscriptionPaid.
  ///
  /// In en, this message translates to:
  /// **'{name} paid {amount} for {plan}'**
  String activitySubscriptionPaid(Object name, Object amount, Object plan);

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get insightsTitle;

  /// No description provided for @insightsEarlyDays.
  ///
  /// In en, this message translates to:
  /// **'Keep recording sales for about two weeks and Kitaza can suggest what to reorder and which prices to look at.'**
  String get insightsEarlyDays;

  /// No description provided for @insightsHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How these are worked out'**
  String get insightsHowTitle;

  /// No description provided for @insightsHowBody.
  ///
  /// In en, this message translates to:
  /// **'From your own records on this phone: the last four weeks of sales for each product, with the days it was out of stock left out. Nothing here changes a price or orders anything.'**
  String get insightsHowBody;

  /// No description provided for @restockTitle.
  ///
  /// In en, this message translates to:
  /// **'Reorder soon'**
  String get restockTitle;

  /// No description provided for @restockOrder.
  ///
  /// In en, this message translates to:
  /// **'Order {quantity} {unit}'**
  String restockOrder(Object quantity, Object unit);

  /// No description provided for @restockReasonRate.
  ///
  /// In en, this message translates to:
  /// **'About {quantity} {unit} a day. Around {days} left.'**
  String restockReasonRate(Object quantity, Object unit, Object days);

  /// No description provided for @restockReasonEmpty.
  ///
  /// In en, this message translates to:
  /// **'About {quantity} {unit} a day, and the shelf is empty.'**
  String restockReasonEmpty(Object quantity, Object unit);

  /// No description provided for @restockReasonLevel.
  ///
  /// In en, this message translates to:
  /// **'Below the reorder level you set.'**
  String get restockReasonLevel;

  /// No description provided for @restockDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String restockDays(int count);

  /// No description provided for @priceTitle.
  ///
  /// In en, this message translates to:
  /// **'Prices worth a look'**
  String get priceTitle;

  /// No description provided for @priceReasonBelowCost.
  ///
  /// In en, this message translates to:
  /// **'Sold for less than the {cost} it costs you.'**
  String priceReasonBelowCost(Object cost);

  /// No description provided for @priceReasonThin.
  ///
  /// In en, this message translates to:
  /// **'Only {percent} is left after the cost.'**
  String priceReasonThin(Object percent);

  /// No description provided for @priceReasonSlow.
  ///
  /// In en, this message translates to:
  /// **'Barely sells. Money sitting on the shelf.'**
  String get priceReasonSlow;

  /// No description provided for @priceTry.
  ///
  /// In en, this message translates to:
  /// **'Try {price}'**
  String priceTry(Object price);

  /// No description provided for @priceExtraPerMonth.
  ///
  /// In en, this message translates to:
  /// **'About {amount} more a month'**
  String priceExtraPerMonth(Object amount);

  /// No description provided for @priceSlowAdvice.
  ///
  /// In en, this message translates to:
  /// **'Order fewer next time, or lower the price for a while.'**
  String get priceSlowAdvice;

  /// No description provided for @patternTitle.
  ///
  /// In en, this message translates to:
  /// **'Your rhythm'**
  String get patternTitle;

  /// No description provided for @patternPayday.
  ///
  /// In en, this message translates to:
  /// **'Payday weeks bring in about {percent} more than the rest of the month.'**
  String patternPayday(Object percent);

  /// No description provided for @patternNextPayday.
  ///
  /// In en, this message translates to:
  /// **'Next payday is {date}. Stock up before it.'**
  String patternNextPayday(Object date);

  /// No description provided for @patternBusiest.
  ///
  /// In en, this message translates to:
  /// **'{day} is your best day, about {percent} above your average.'**
  String patternBusiest(Object day, Object percent);

  /// No description provided for @benchmarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Stores like yours'**
  String get benchmarkTitle;

  /// No description provided for @benchmarkFrom.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{The middle of {count} similar stores near your size.}}'**
  String benchmarkFrom(int count);

  /// No description provided for @benchmarkMargin.
  ///
  /// In en, this message translates to:
  /// **'Kept from each sale'**
  String get benchmarkMargin;

  /// No description provided for @benchmarkExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses against sales'**
  String get benchmarkExpenses;

  /// No description provided for @benchmarkDailySales.
  ///
  /// In en, this message translates to:
  /// **'Sales a day'**
  String get benchmarkDailySales;

  /// No description provided for @benchmarkYours.
  ///
  /// In en, this message translates to:
  /// **'You: {value}'**
  String benchmarkYours(Object value);

  /// No description provided for @benchmarkTypical.
  ///
  /// In en, this message translates to:
  /// **'Usual: {value}'**
  String benchmarkTypical(Object value);

  /// No description provided for @benchmarkNotEnough.
  ///
  /// In en, this message translates to:
  /// **'Comparisons appear once enough stores your size are sharing theirs.'**
  String get benchmarkNotEnough;

  /// No description provided for @benchmarkNotSharing.
  ///
  /// In en, this message translates to:
  /// **'Comparisons are off while you keep your own figures back.'**
  String get benchmarkNotSharing;

  /// No description provided for @benchmarkSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous comparisons'**
  String get benchmarkSharingTitle;

  /// No description provided for @benchmarkSharingHint.
  ///
  /// In en, this message translates to:
  /// **'Your monthly totals join the middle figures other owners see. Never your name, your store or any single sale, and only across at least 20 stores.'**
  String get benchmarkSharingHint;

  /// No description provided for @benchmarkSharingOff.
  ///
  /// In en, this message translates to:
  /// **'Not sharing. You will not see comparisons either.'**
  String get benchmarkSharingOff;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Kitaza {version}'**
  String aboutVersion(Object version);

  /// No description provided for @aboutCopied.
  ///
  /// In en, this message translates to:
  /// **'Version copied'**
  String get aboutCopied;

  /// No description provided for @aboutUnreleasedBuild.
  ///
  /// In en, this message translates to:
  /// **'Test build. Cloud storage will not connect.'**
  String get aboutUnreleasedBuild;

  /// No description provided for @settingsGuide.
  ///
  /// In en, this message translates to:
  /// **'Learn Kitaza'**
  String get settingsGuide;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'How to use Kitaza'**
  String get guideTitle;

  /// No description provided for @guideIntro.
  ///
  /// In en, this message translates to:
  /// **'Eight short lessons. Read them in order the first time, then come back to any one of them whenever you need it.'**
  String get guideIntro;

  /// No description provided for @guideProgress.
  ///
  /// In en, this message translates to:
  /// **'{read, plural, =0{Not started} other{{read} of {total} read}}'**
  String guideProgress(int read, int total);

  /// No description provided for @guideLessonProgress.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} steps}}'**
  String guideLessonProgress(int count);

  /// No description provided for @guideStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String guideStepLabel(int number);

  /// No description provided for @guideOpenScreen.
  ///
  /// In en, this message translates to:
  /// **'Open it now'**
  String get guideOpenScreen;

  /// No description provided for @guideNextLesson.
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String guideNextLesson(Object title);

  /// No description provided for @guideAllDone.
  ///
  /// In en, this message translates to:
  /// **'That is the whole guide.'**
  String get guideAllDone;

  /// No description provided for @guideAllDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing here is a test. Come back to any lesson whenever you need it.'**
  String get guideAllDoneBody;

  /// No description provided for @guideBackToLessons.
  ///
  /// In en, this message translates to:
  /// **'Back to the lessons'**
  String get guideBackToLessons;

  /// No description provided for @guideRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get guideRead;

  /// No description provided for @guidePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'New to Kitaza?'**
  String get guidePromptTitle;

  /// No description provided for @guidePromptBody.
  ///
  /// In en, this message translates to:
  /// **'A short guide walks you through recording a sale, your prices, and reading your numbers.'**
  String get guidePromptBody;

  /// No description provided for @guidePromptOpen.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get guidePromptOpen;

  /// No description provided for @guidePromptDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get guidePromptDismiss;

  /// No description provided for @guideFirstDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first day'**
  String get guideFirstDayTitle;

  /// No description provided for @guideFirstDaySummary.
  ///
  /// In en, this message translates to:
  /// **'What to do in the first hour, and why the app keeps working when the signal does not.'**
  String get guideFirstDaySummary;

  /// No description provided for @guideFirstDayStep1Title.
  ///
  /// In en, this message translates to:
  /// **'It works without load'**
  String get guideFirstDayStep1Title;

  /// No description provided for @guideFirstDayStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Everything you record is saved on this phone first. No signal, no data, no problem. If you use cloud storage, the phone sends it on by itself once there is signal again.'**
  String get guideFirstDayStep1Body;

  /// No description provided for @guideFirstDayStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Put in what you sell'**
  String get guideFirstDayStep2Title;

  /// No description provided for @guideFirstDayStep2Body.
  ///
  /// In en, this message translates to:
  /// **'You do not need everything on day one. Start with the ten things that move the most. Add the rest as you go along.'**
  String get guideFirstDayStep2Body;

  /// No description provided for @guideFirstDayStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Record every sale, even a five-peso one'**
  String get guideFirstDayStep3Title;

  /// No description provided for @guideFirstDayStep3Body.
  ///
  /// In en, this message translates to:
  /// **'A sachet counts the same as a case. The numbers Kitaza gives back are only as true as what you put in, so the small ones matter most.'**
  String get guideFirstDayStep3Body;

  /// No description provided for @guideFirstDayStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Look at the day before you close'**
  String get guideFirstDayStep4Title;

  /// No description provided for @guideFirstDayStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Open the first screen at the end of the day. It shows what came in, what went out, and what you actually kept.'**
  String get guideFirstDayStep4Body;

  /// No description provided for @guideRecordingSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording a sale'**
  String get guideRecordingSalesTitle;

  /// No description provided for @guideRecordingSalesSummary.
  ///
  /// In en, this message translates to:
  /// **'The one thing you will do a hundred times a day. It takes three taps.'**
  String get guideRecordingSalesSummary;

  /// No description provided for @guideRecordingSalesStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Tap Add sale'**
  String get guideRecordingSalesStep1Title;

  /// No description provided for @guideRecordingSalesStep1Body.
  ///
  /// In en, this message translates to:
  /// **'It is the big button at the top of the first screen. You can reach it from anywhere using the buttons along the bottom.'**
  String get guideRecordingSalesStep1Body;

  /// No description provided for @guideRecordingSalesStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Tap what they bought'**
  String get guideRecordingSalesStep2Title;

  /// No description provided for @guideRecordingSalesStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Tap an item to add one. Tap it again for two. If the item has a barcode, use the scanner button instead of searching for it.'**
  String get guideRecordingSalesStep2Body;

  /// No description provided for @guideRecordingSalesStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Say how they paid'**
  String get guideRecordingSalesStep3Title;

  /// No description provided for @guideRecordingSalesStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Cash, GCash, or utang. Utang is still a sale, and Kitaza remembers it as money you have not been handed yet.'**
  String get guideRecordingSalesStep3Body;

  /// No description provided for @guideRecordingSalesStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get guideRecordingSalesStep4Title;

  /// No description provided for @guideRecordingSalesStep4Body.
  ///
  /// In en, this message translates to:
  /// **'That is it. The sale is on the phone straight away, and the stock count goes down by itself.'**
  String get guideRecordingSalesStep4Body;

  /// No description provided for @guideRecordingSalesStep5Title.
  ///
  /// In en, this message translates to:
  /// **'If you get one wrong'**
  String get guideRecordingSalesStep5Title;

  /// No description provided for @guideRecordingSalesStep5Body.
  ///
  /// In en, this message translates to:
  /// **'Open Sales, find it, and void it. Nothing is erased quietly: the sale is marked void and the stock goes back on the shelf.'**
  String get guideRecordingSalesStep5Body;

  /// No description provided for @guideWhatYouSellTitle.
  ///
  /// In en, this message translates to:
  /// **'What you sell'**
  String get guideWhatYouSellTitle;

  /// No description provided for @guideWhatYouSellSummary.
  ///
  /// In en, this message translates to:
  /// **'Your prices, your stock, and the one field that decides whether Kitaza can tell you your profit.'**
  String get guideWhatYouSellSummary;

  /// No description provided for @guideWhatYouSellStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get guideWhatYouSellStep1Title;

  /// No description provided for @guideWhatYouSellStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Go to Products and tap Add. A name and a selling price are enough to start selling it.'**
  String get guideWhatYouSellStep1Body;

  /// No description provided for @guideWhatYouSellStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Put in both prices'**
  String get guideWhatYouSellStep2Title;

  /// No description provided for @guideWhatYouSellStep2Body.
  ///
  /// In en, this message translates to:
  /// **'What you paid for it, and what you charge. Without the cost, Kitaza can only count your sales - it cannot tell you what you kept.'**
  String get guideWhatYouSellStep2Body;

  /// No description provided for @guideWhatYouSellStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Count what is on the shelf'**
  String get guideWhatYouSellStep3Title;

  /// No description provided for @guideWhatYouSellStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Put in how many you have now. From then on Kitaza counts down as you sell and up when you record a delivery.'**
  String get guideWhatYouSellStep3Body;

  /// No description provided for @guideWhatYouSellStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Say when to reorder'**
  String get guideWhatYouSellStep4Title;

  /// No description provided for @guideWhatYouSellStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Set the number that means running low - two, five, a dozen. Kitaza tells you before the shelf is empty, not after.'**
  String get guideWhatYouSellStep4Body;

  /// No description provided for @guideWhatYouSellStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Scan instead of typing'**
  String get guideWhatYouSellStep5Title;

  /// No description provided for @guideWhatYouSellStep5Body.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode once while adding the item, and from then on scanning it at the counter finds it instantly.'**
  String get guideWhatYouSellStep5Body;

  /// No description provided for @guideMoneyGoingOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Money going out'**
  String get guideMoneyGoingOutTitle;

  /// No description provided for @guideMoneyGoingOutSummary.
  ///
  /// In en, this message translates to:
  /// **'Buying stock, paying the bills, and the difference between the two kinds of money leaving.'**
  String get guideMoneyGoingOutSummary;

  /// No description provided for @guideMoneyGoingOutStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Record what you spend'**
  String get guideMoneyGoingOutStep1Title;

  /// No description provided for @guideMoneyGoingOutStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap Expense and put in the amount. The reason is optional - do not let it slow you down at the counter.'**
  String get guideMoneyGoingOutStep1Body;

  /// No description provided for @guideMoneyGoingOutStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Buying stock counts too'**
  String get guideMoneyGoingOutStep2Title;

  /// No description provided for @guideMoneyGoingOutStep2Body.
  ///
  /// In en, this message translates to:
  /// **'The trip to the palengke, the delivery, the load you bought to resell. If money left the till, it belongs here.'**
  String get guideMoneyGoingOutStep2Body;

  /// No description provided for @guideMoneyGoingOutStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Money you take for yourself is different'**
  String get guideMoneyGoingOutStep3Title;

  /// No description provided for @guideMoneyGoingOutStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Use Withdrawals for that, not Expenses. Mixing them makes a shop that is doing fine look like it is losing money every week.'**
  String get guideMoneyGoingOutStep3Body;

  /// No description provided for @guideMoneyGoingOutStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Do it the same day'**
  String get guideMoneyGoingOutStep4Title;

  /// No description provided for @guideMoneyGoingOutStep4Body.
  ///
  /// In en, this message translates to:
  /// **'An expense remembered three days later is usually remembered wrong. A quick note at the time beats an exact one that never happens.'**
  String get guideMoneyGoingOutStep4Body;

  /// No description provided for @guideReadingYourNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading your numbers'**
  String get guideReadingYourNumbersTitle;

  /// No description provided for @guideReadingYourNumbersSummary.
  ///
  /// In en, this message translates to:
  /// **'What the first screen is telling you, and the difference between selling a lot and earning.'**
  String get guideReadingYourNumbersSummary;

  /// No description provided for @guideReadingYourNumbersStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Pick the period first'**
  String get guideReadingYourNumbersStep1Title;

  /// No description provided for @guideReadingYourNumbersStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Today, this week, this month. Every number on the screen is for the period you picked, so check it before you worry.'**
  String get guideReadingYourNumbersStep1Body;

  /// No description provided for @guideReadingYourNumbersStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Sales is not profit'**
  String get guideReadingYourNumbersStep2Title;

  /// No description provided for @guideReadingYourNumbersStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Sales is what came through the till. Profit is what is left after what the goods cost you. A busy day with thin prices can earn less than a quiet one.'**
  String get guideReadingYourNumbersStep2Body;

  /// No description provided for @guideReadingYourNumbersStep3Title.
  ///
  /// In en, this message translates to:
  /// **'The coloured band'**
  String get guideReadingYourNumbersStep3Title;

  /// No description provided for @guideReadingYourNumbersStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Green means the week is going well, yellow means watch something, red means something needs your attention today. It always says why underneath.'**
  String get guideReadingYourNumbersStep3Body;

  /// No description provided for @guideReadingYourNumbersStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Tap a number to see where it came from'**
  String get guideReadingYourNumbersStep4Title;

  /// No description provided for @guideReadingYourNumbersStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Nothing in Kitaza is a number you have to take on faith. Every total opens into the sales and expenses that made it.'**
  String get guideReadingYourNumbersStep4Body;

  /// No description provided for @guideWhatKitazaSuggestsTitle.
  ///
  /// In en, this message translates to:
  /// **'What Kitaza suggests'**
  String get guideWhatKitazaSuggestsTitle;

  /// No description provided for @guideWhatKitazaSuggestsSummary.
  ///
  /// In en, this message translates to:
  /// **'Reorder advice, prices worth a look, and your own busy days - all worked out from your own records.'**
  String get guideWhatKitazaSuggestsSummary;

  /// No description provided for @guideWhatKitazaSuggestsStep1Title.
  ///
  /// In en, this message translates to:
  /// **'What to reorder'**
  String get guideWhatKitazaSuggestsStep1Title;

  /// No description provided for @guideWhatKitazaSuggestsStep1Body.
  ///
  /// In en, this message translates to:
  /// **'How fast each item actually sells, how many days the shelf will last, and how much to buy. Days it was out of stock are left out, so a fast seller is not mistaken for a slow one.'**
  String get guideWhatKitazaSuggestsStep1Body;

  /// No description provided for @guideWhatKitazaSuggestsStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Prices worth a look'**
  String get guideWhatKitazaSuggestsStep2Title;

  /// No description provided for @guideWhatKitazaSuggestsStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Anything you are selling for less than it cost you, thin margins on good sellers, and stock that is not moving. Each one suggests a price and what it would add in a month.'**
  String get guideWhatKitazaSuggestsStep2Body;

  /// No description provided for @guideWhatKitazaSuggestsStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Your own busy days'**
  String get guideWhatKitazaSuggestsStep3Title;

  /// No description provided for @guideWhatKitazaSuggestsStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Payday weeks and your best day of the week, measured from your takings - not guessed. A store beside a school and one beside a factory do not share a rhythm.'**
  String get guideWhatKitazaSuggestsStep3Body;

  /// No description provided for @guideWhatKitazaSuggestsStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Check the arithmetic'**
  String get guideWhatKitazaSuggestsStep4Title;

  /// No description provided for @guideWhatKitazaSuggestsStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Every card has How these are worked out underneath it. If a suggestion looks wrong to you, open it - you know your store better than the app does.'**
  String get guideWhatKitazaSuggestsStep4Body;

  /// No description provided for @guideKeepingRecordsSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Keeping your records safe'**
  String get guideKeepingRecordsSafeTitle;

  /// No description provided for @guideKeepingRecordsSafeSummary.
  ///
  /// In en, this message translates to:
  /// **'What happens if the phone is lost, and how to make sure a year of records is not lost with it.'**
  String get guideKeepingRecordsSafeSummary;

  /// No description provided for @guideKeepingRecordsSafeStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Kitaza backs itself up'**
  String get guideKeepingRecordsSafeStep1Title;

  /// No description provided for @guideKeepingRecordsSafeStep1Body.
  ///
  /// In en, this message translates to:
  /// **'A copy of your records is saved on the phone on its own, without you asking. That covers a mistake. It does not cover a lost phone.'**
  String get guideKeepingRecordsSafeStep1Body;

  /// No description provided for @guideKeepingRecordsSafeStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Keep a copy off the phone'**
  String get guideKeepingRecordsSafeStep2Title;

  /// No description provided for @guideKeepingRecordsSafeStep2Body.
  ///
  /// In en, this message translates to:
  /// **'In Settings, tap Export and send the file to yourself - Messenger, email, a memory card. Once a month is enough. This is the step people skip and regret.'**
  String get guideKeepingRecordsSafeStep2Body;

  /// No description provided for @guideKeepingRecordsSafeStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Getting your records back'**
  String get guideKeepingRecordsSafeStep3Title;

  /// No description provided for @guideKeepingRecordsSafeStep3Body.
  ///
  /// In en, this message translates to:
  /// **'On a new phone, install Kitaza and choose Restore instead of setting up a new store. Your products, sales and expenses come back as they were.'**
  String get guideKeepingRecordsSafeStep3Body;

  /// No description provided for @guideKeepingRecordsSafeStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Or let the cloud hold it'**
  String get guideKeepingRecordsSafeStep4Title;

  /// No description provided for @guideKeepingRecordsSafeStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Cloud storage keeps your records on our server as well as your phone, so a lost phone costs you nothing. It needs signal sometimes, and a monthly plan.'**
  String get guideKeepingRecordsSafeStep4Body;

  /// No description provided for @guideYourHelpersTitle.
  ///
  /// In en, this message translates to:
  /// **'Your helpers'**
  String get guideYourHelpersTitle;

  /// No description provided for @guideYourHelpersSummary.
  ///
  /// In en, this message translates to:
  /// **'Letting someone else mind the counter without handing over everything.'**
  String get guideYourHelpersSummary;

  /// No description provided for @guideYourHelpersStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Add the person first'**
  String get guideYourHelpersStep1Title;

  /// No description provided for @guideYourHelpersStep1Body.
  ///
  /// In en, this message translates to:
  /// **'In Settings, open Team and add them by name. Kitaza gives you a short code for them to type into their own phone.'**
  String get guideYourHelpersStep1Body;

  /// No description provided for @guideYourHelpersStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Choose what they can see'**
  String get guideYourHelpersStep2Title;

  /// No description provided for @guideYourHelpersStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Everyone can sell. You decide separately whether they can change prices, record expenses, see your profit, or void a sale.'**
  String get guideYourHelpersStep2Body;

  /// No description provided for @guideYourHelpersStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Their phone and yours agree'**
  String get guideYourHelpersStep3Title;

  /// No description provided for @guideYourHelpersStep3Body.
  ///
  /// In en, this message translates to:
  /// **'A sale rung up at the counter shows on your phone within seconds. Both phones keep working when the signal drops, and catch up afterwards.'**
  String get guideYourHelpersStep3Body;

  /// No description provided for @guideYourHelpersStep4Title.
  ///
  /// In en, this message translates to:
  /// **'If a phone goes missing'**
  String get guideYourHelpersStep4Title;

  /// No description provided for @guideYourHelpersStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Open Signed-in devices and remove it. That phone stops being able to see or change anything, straight away.'**
  String get guideYourHelpersStep4Body;

  /// No description provided for @legalOperator.
  ///
  /// In en, this message translates to:
  /// **'[Registered business name], [address], Philippines'**
  String get legalOperator;

  /// No description provided for @legalContact.
  ///
  /// In en, this message translates to:
  /// **'Questions about this document, or about your records: [privacy@kitaza.ph]. We answer within 15 working days, as the National Privacy Commission expects.'**
  String get legalContact;

  /// No description provided for @legalVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String legalVersion(Object version);

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get legalPrivacyTitle;

  /// No description provided for @legalTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get legalTermsTitle;

  /// No description provided for @legalReadPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get legalReadPrivacy;

  /// No description provided for @legalReadTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get legalReadTerms;

  /// No description provided for @legalAgreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get legalAgreeTitle;

  /// No description provided for @legalAgree.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the {privacy} and the {terms}.'**
  String legalAgree(Object privacy, Object terms);

  /// No description provided for @legalAgreeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please read and agree to both before continuing.'**
  String get legalAgreeRequired;

  /// No description provided for @legalAgreedOn.
  ///
  /// In en, this message translates to:
  /// **'Agreed {date}'**
  String legalAgreedOn(Object date);

  /// No description provided for @legalNeedsAgreement.
  ///
  /// In en, this message translates to:
  /// **'Please review and agree'**
  String get legalNeedsAgreement;

  /// No description provided for @legalUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'We have updated these'**
  String get legalUpdatedTitle;

  /// No description provided for @legalUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Please read what changed and agree again. Nothing on your phone is affected while you decide.'**
  String get legalUpdatedBody;

  /// No description provided for @legalAgreeButton.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get legalAgreeButton;

  /// No description provided for @privacyWhoHeading.
  ///
  /// In en, this message translates to:
  /// **'Who holds your records'**
  String get privacyWhoHeading;

  /// No description provided for @privacyWhoBody.
  ///
  /// In en, this message translates to:
  /// **'Kitaza is run by {operator}. Under the Data Privacy Act of 2012 (Republic Act 10173) we are the personal information controller for the details you give us about yourself.\n\nOur Data Protection Officer can be reached at the address at the end of this notice.'**
  String privacyWhoBody(Object operator);

  /// No description provided for @privacyOfflineHeading.
  ///
  /// In en, this message translates to:
  /// **'If you use Kitaza offline, we hold nothing'**
  String get privacyOfflineHeading;

  /// No description provided for @privacyOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'An offline store keeps everything on the phone. Your products, sales, expenses and takings never reach us, because there is nothing to send them to. We could not show them to anyone if we were asked.\n\nThis is not a setting we can change from our side. It is simply where the records are.'**
  String get privacyOfflineBody;

  /// No description provided for @privacyWhatHeading.
  ///
  /// In en, this message translates to:
  /// **'What we hold when you use the cloud'**
  String get privacyWhatHeading;

  /// No description provided for @privacyWhatBody.
  ///
  /// In en, this message translates to:
  /// **'Your name, your email address, and a scrambled form of your password that cannot be turned back into it.\n\nYour store\'s name, its type, and the names of any staff you add.\n\nYour business records: products and prices, sales, expenses, withdrawals and stock counts.\n\nThe name of each phone signed in, when it was last used, and a record of who did what in your store.\n\nIf the app breaks, what broke and which version it was: the error, where in the code it happened, and the phone\'s operating system.'**
  String get privacyWhatBody;

  /// No description provided for @privacyNeverHeading.
  ///
  /// In en, this message translates to:
  /// **'What we never hold'**
  String get privacyNeverHeading;

  /// No description provided for @privacyNeverBody.
  ///
  /// In en, this message translates to:
  /// **'We do not record your customers. A sale is an amount and the items in it; an utang is a payment method. No customer name, number or address is ever asked for or stored.\n\nWe never see card numbers, GCash PINs or bank details. Payments go through PayMongo, who handle them; we are told only that a payment succeeded and for how much.\n\nWe do not track your location, read your contacts, or look at anything else on your phone. The camera is used for scanning barcodes, and only while you have the scanner open.'**
  String get privacyNeverBody;

  /// No description provided for @privacyWhyHeading.
  ///
  /// In en, this message translates to:
  /// **'Why we hold it'**
  String get privacyWhyHeading;

  /// No description provided for @privacyWhyBody.
  ///
  /// In en, this message translates to:
  /// **'To run the service you asked for: to keep your records for you, to show them on your other phones, and to let your staff use the store.\n\nTo take payment for the plan you chose, and to keep the accounting records a business is required to keep.\n\nTo fix what breaks. Error reports tell us a build is failing; they carry no business figures.\n\nWith your permission, to work out the middle figures that let you compare your store with others. You can switch this off in Settings, and switching it off also switches off seeing anyone else\'s.'**
  String get privacyWhyBody;

  /// No description provided for @privacySharedHeading.
  ///
  /// In en, this message translates to:
  /// **'Who else sees it'**
  String get privacySharedHeading;

  /// No description provided for @privacySharedBody.
  ///
  /// In en, this message translates to:
  /// **'PayMongo Philippines, to take payment. They see what a payment is for and who is paying, under their own privacy policy.\n\nThe company that hosts our servers, which stores the data on our behalf and may not use it for anything else.\n\nNobody else. We do not sell your records, and we do not hand them to advertisers. We would give them to a government body only where a law or a court order requires it, and we would tell you unless we were forbidden to.\n\nComparisons between stores are published as middle figures only, across at least twenty stores of a similar type and size. They name no store and contain no single sale.'**
  String get privacySharedBody;

  /// No description provided for @privacyKeepHeading.
  ///
  /// In en, this message translates to:
  /// **'How long we keep it'**
  String get privacyKeepHeading;

  /// No description provided for @privacyKeepBody.
  ///
  /// In en, this message translates to:
  /// **'Your business records, for as long as your account is open.\n\nWho did what in your store: two years.\n\nError reports: ninety days.\n\nPhones you have signed out: one year.\n\nWhen you close your account we delete everything after thirty days, and the thirty days exist only so a mis-tap can be undone. What survives is the amount and date of payments we received, with nothing about you attached to it, because a business must be able to account for money it was paid.'**
  String get privacyKeepBody;

  /// No description provided for @privacyRightsHeading.
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get privacyRightsHeading;

  /// No description provided for @privacyRightsBody.
  ///
  /// In en, this message translates to:
  /// **'The Data Privacy Act gives you rights over what we hold, and the app carries out most of them without you having to ask anyone.\n\nTo be told what we hold and why: this notice, and Settings shows it too.\n\nTo get a copy: Settings, Download my records. It is an ordinary file you can open and keep.\n\nTo correct what is wrong: change it in the app, or write to us.\n\nTo have it deleted: Settings, Close my account. After thirty days it is gone and cannot be brought back.\n\nTo object, and to withdraw a permission you gave. Turning off comparisons is one of these.\n\nTo be paid for damage caused if we mishandle your records, and to complain to the National Privacy Commission at privacy.gov.ph. You do not have to come to us first, although we would rather you did.'**
  String get privacyRightsBody;

  /// No description provided for @privacySafetyHeading.
  ///
  /// In en, this message translates to:
  /// **'Keeping it safe, and telling you when we fail'**
  String get privacySafetyHeading;

  /// No description provided for @privacySafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Passwords are stored scrambled and cannot be read back, by us or anyone else. Traffic between your phone and our servers is encrypted. A phone you sign out stops working straight away.\n\nIf your records are exposed and it puts you at real risk, we will tell the National Privacy Commission within seventy-two hours of finding out, and we will tell you: what happened, what was involved, and what to do about it.'**
  String get privacySafetyBody;

  /// No description provided for @privacyChangesHeading.
  ///
  /// In en, this message translates to:
  /// **'Changes to this notice'**
  String get privacyChangesHeading;

  /// No description provided for @privacyChangesBody.
  ///
  /// In en, this message translates to:
  /// **'When this notice changes in a way that matters, the app asks you to read it and agree again, and records the version you agreed to.\n\nUsing the app does not count as agreeing. We ask you plainly.'**
  String get privacyChangesBody;

  /// No description provided for @termsWhatHeading.
  ///
  /// In en, this message translates to:
  /// **'What Kitaza is'**
  String get termsWhatHeading;

  /// No description provided for @termsWhatBody.
  ///
  /// In en, this message translates to:
  /// **'Kitaza is a record book for a small shop. It records what you sell and spend, counts your stock, and works out figures from what you put in.\n\nThe agreement is between you and {operator}.'**
  String termsWhatBody(Object operator);

  /// No description provided for @termsNotHeading.
  ///
  /// In en, this message translates to:
  /// **'What Kitaza is not'**
  String get termsNotHeading;

  /// No description provided for @termsNotBody.
  ///
  /// In en, this message translates to:
  /// **'It is not an accountant, and it is not a BIR filing tool. Its figures are not a tax return and not a set of audited books.\n\nIts suggestions - what to reorder, what to charge - are arithmetic on your own records, shown with their working. They are something to weigh, not instructions. You know your shop; the app does not.\n\nIf you need advice about tax, permits or the law, ask someone qualified to give it.'**
  String get termsNotBody;

  /// No description provided for @termsAccountHeading.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get termsAccountHeading;

  /// No description provided for @termsAccountBody.
  ///
  /// In en, this message translates to:
  /// **'You must be old enough to enter a contract, and the details you give must be true.\n\nKeep your password to yourself. Anything done by a phone signed in to your account is treated as done by you, so sign out a phone you no longer have.\n\nStaff you add act for you. You decide what each of them may see and do, and you are responsible for what they do in your store.'**
  String get termsAccountBody;

  /// No description provided for @termsPayHeading.
  ///
  /// In en, this message translates to:
  /// **'What you pay'**
  String get termsPayHeading;

  /// No description provided for @termsPayBody.
  ///
  /// In en, this message translates to:
  /// **'The first thirty days are free and need no payment details.\n\nAfter that a plan is paid for in advance - one month or one year at a time - at the price shown in the app when you pay. Nothing renews by itself and nothing is charged automatically. When a period runs out you get seven more days, and then the app stops syncing until you pay again.\n\nYour records are not held hostage. An unpaid account can still be read on the phone, and its records can still be exported.\n\nPrices can change, but never for a period you have already paid for.'**
  String get termsPayBody;

  /// No description provided for @termsRefundHeading.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get termsRefundHeading;

  /// No description provided for @termsRefundBody.
  ///
  /// In en, this message translates to:
  /// **'If the service does not do what this page says it does, tell us within thirty days of paying and we will refund that payment in full.\n\nWe do not refund a period you simply did not use. Nothing renews by itself, so an unused period is a choice rather than an accident.\n\nThis sits alongside your rights under the Consumer Act of the Philippines (Republic Act 7394); nothing here takes those away.'**
  String get termsRefundBody;

  /// No description provided for @termsYoursHeading.
  ///
  /// In en, this message translates to:
  /// **'Your records are yours'**
  String get termsYoursHeading;

  /// No description provided for @termsYoursBody.
  ///
  /// In en, this message translates to:
  /// **'What you put in stays yours. We claim nothing over it, and we hold it to run the service for you and nothing else.\n\nYou can take a copy at any time, and you can close the account and have it deleted. The Privacy notice says exactly what happens then.'**
  String get termsYoursBody;

  /// No description provided for @termsFairHeading.
  ///
  /// In en, this message translates to:
  /// **'Using it fairly'**
  String get termsFairHeading;

  /// No description provided for @termsFairBody.
  ///
  /// In en, this message translates to:
  /// **'Do not use Kitaza to break the law, to record someone else\'s business without their say-so, or to attack the service or get into an account that is not yours.\n\nWe may suspend an account that is doing one of these, and we will say why.'**
  String get termsFairBody;

  /// No description provided for @termsLimitsHeading.
  ///
  /// In en, this message translates to:
  /// **'What we do and do not promise'**
  String get termsLimitsHeading;

  /// No description provided for @termsLimitsBody.
  ///
  /// In en, this message translates to:
  /// **'We will take reasonable care to keep the service running and your records safe. We cannot promise it will never be down, and we cannot promise a phone will never be lost or broken - which is why the app keeps its own backups and asks you to keep a copy off the phone.\n\nWhere the law allows a limit, ours is the amount you have paid us in the twelve months before the problem. Nothing here limits liability for fraud, for death or injury caused by negligence, or for anything a law says may not be limited.'**
  String get termsLimitsBody;

  /// No description provided for @termsEndingHeading.
  ///
  /// In en, this message translates to:
  /// **'Ending it'**
  String get termsEndingHeading;

  /// No description provided for @termsEndingBody.
  ///
  /// In en, this message translates to:
  /// **'You can close your account at any time, from Settings.\n\nWe would end an agreement only for a serious or repeated breach of these terms, and we would give you notice and time to take a copy of your records first.'**
  String get termsEndingBody;

  /// No description provided for @termsLawHeading.
  ///
  /// In en, this message translates to:
  /// **'Which law applies'**
  String get termsLawHeading;

  /// No description provided for @termsLawBody.
  ///
  /// In en, this message translates to:
  /// **'The law of the Republic of the Philippines. A dispute that cannot be settled between us goes to the courts of the place where our business is registered.\n\nIf part of this page turns out to be unenforceable, the rest still stands.'**
  String get termsLawBody;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your data and privacy'**
  String get settingsPrivacy;

  /// No description provided for @privacyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data and privacy'**
  String get privacyCardTitle;

  /// No description provided for @privacyCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What is held, how to get a copy, and how to close your account'**
  String get privacyCardSubtitle;

  /// No description provided for @privacyScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data and privacy'**
  String get privacyScreenTitle;

  /// No description provided for @privacyWhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Where your records are'**
  String get privacyWhereTitle;

  /// No description provided for @privacyWhereLocal.
  ///
  /// In en, this message translates to:
  /// **'On this phone only. Nothing about your store has ever been sent to us, and nothing can be.'**
  String get privacyWhereLocal;

  /// No description provided for @privacyWhereCloud.
  ///
  /// In en, this message translates to:
  /// **'On this phone and on our servers, so your other phones and your staff can see them.'**
  String get privacyWhereCloud;

  /// No description provided for @privacyDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'What you agreed to'**
  String get privacyDocumentsTitle;

  /// No description provided for @privacyDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download my records'**
  String get privacyDownloadTitle;

  /// No description provided for @privacyDownloadLocal.
  ///
  /// In en, this message translates to:
  /// **'Everything on this phone, as a file you can keep or open elsewhere.'**
  String get privacyDownloadLocal;

  /// No description provided for @privacyDownloadCloud.
  ///
  /// In en, this message translates to:
  /// **'Everything we hold about you, as a file you can keep or open elsewhere.'**
  String get privacyDownloadCloud;

  /// No description provided for @privacyDownloadWorking.
  ///
  /// In en, this message translates to:
  /// **'Gathering your records…'**
  String get privacyDownloadWorking;

  /// No description provided for @privacyDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not gather your records. Try again.'**
  String get privacyDownloadFailed;

  /// No description provided for @privacyCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close my account'**
  String get privacyCloseTitle;

  /// No description provided for @privacyCloseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete everything we hold about you'**
  String get privacyCloseSubtitle;

  /// No description provided for @privacyCloseScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Close my account'**
  String get privacyCloseScreenTitle;

  /// No description provided for @privacyCloseExplain.
  ///
  /// In en, this message translates to:
  /// **'Your account, your stores and every sale, expense and product in them will be deleted from our servers.'**
  String get privacyCloseExplain;

  /// No description provided for @privacyCloseGrace.
  ///
  /// In en, this message translates to:
  /// **'Nothing is deleted for {days} days. Until then you can change your mind, and everything carries on as normal.'**
  String privacyCloseGrace(int days);

  /// No description provided for @privacyCloseKeeps.
  ///
  /// In en, this message translates to:
  /// **'What we keep: the amount and date of payments you made, with nothing about you attached. A business has to be able to account for money it was paid.'**
  String get privacyCloseKeeps;

  /// No description provided for @privacyClosePhone.
  ///
  /// In en, this message translates to:
  /// **'The records on this phone are not touched. Take a copy first if you want to keep them.'**
  String get privacyClosePhone;

  /// No description provided for @privacyCloseConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Type the name of your store to confirm'**
  String get privacyCloseConfirmLabel;

  /// No description provided for @privacyCloseConfirmWrong.
  ///
  /// In en, this message translates to:
  /// **'That does not match the name of your store.'**
  String get privacyCloseConfirmWrong;

  /// No description provided for @privacyCloseSubmit.
  ///
  /// In en, this message translates to:
  /// **'Close my account'**
  String get privacyCloseSubmit;

  /// No description provided for @privacyCloseScheduled.
  ///
  /// In en, this message translates to:
  /// **'Your account will be deleted on {date}.'**
  String privacyCloseScheduled(Object date);

  /// No description provided for @privacyCloseCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get privacyCloseCancel;

  /// No description provided for @privacyCloseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your account is staying open.'**
  String get privacyCloseCancelled;

  /// No description provided for @privacyCloseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not do that. Try again when you have signal.'**
  String get privacyCloseFailed;

  /// No description provided for @privacyLocalOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to close'**
  String get privacyLocalOnlyTitle;

  /// No description provided for @privacyLocalOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'This store is on your phone only. To remove it, delete the app - but take a copy of your records first.'**
  String get privacyLocalOnlyBody;

  /// No description provided for @privacyNpcTitle.
  ///
  /// In en, this message translates to:
  /// **'If we get it wrong'**
  String get privacyNpcTitle;

  /// No description provided for @privacyNpcBody.
  ///
  /// In en, this message translates to:
  /// **'You can complain to the National Privacy Commission at privacy.gov.ph. You do not have to come to us first.'**
  String get privacyNpcBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
