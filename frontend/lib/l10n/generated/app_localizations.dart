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
