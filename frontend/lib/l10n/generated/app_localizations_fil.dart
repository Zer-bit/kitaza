// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get appName => 'Kitaza';

  @override
  String get tagline => 'Alamin kung saan napupunta ang bawat piso';

  @override
  String get commonCancel => 'Kanselahin';

  @override
  String get commonBack => 'Bumalik';

  @override
  String get commonTryAgain => 'Subukan ulit';

  @override
  String get commonSave => 'I-save';

  @override
  String get commonAmount => 'Halaga';

  @override
  String get commonEnterAmount => 'Ilagay ang halaga';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonEnterEmail => 'Ilagay ang iyong email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonEnterPassword => 'Ilagay ang iyong password';

  @override
  String get commonPasswordHint => 'Hindi bababa sa 8 character';

  @override
  String get commonPasswordTooShort => 'Gumamit ng hindi bababa sa 8 character';

  @override
  String get commonShowPassword => 'Ipakita ang password';

  @override
  String get commonHidePassword => 'Itago ang password';

  @override
  String get commonStoreName => 'Pangalan ng tindahan';

  @override
  String get commonEnterStoreName => 'Ilagay ang pangalan ng tindahan';

  @override
  String get commonYourName => 'Pangalan mo';

  @override
  String get commonEnterYourName => 'Ilagay ang pangalan mo';

  @override
  String get commonEnterName => 'Ilagay ang pangalan';

  @override
  String get commonNoteOptional => 'Tala (hindi kailangan)';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonToday => 'Ngayong araw';

  @override
  String get commonYesterday => 'Kahapon';

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
      'Offline ka. Naka-save ang entry sa phone na ito at magsi-sync pag may signal na.';

  @override
  String get errorSessionExpired =>
      'Nag-expire na ang session mo. Mag-sign in ulit.';

  @override
  String get errorServer =>
      'May problema ang Kitaza server. Ligtas ang data mo sa phone na ito.';

  @override
  String get errorGeneric => 'May nagkaproblema. Subukan ulit.';

  @override
  String get errorWrongCredentials => 'Mali ang email o password.';

  @override
  String get errorEmailTaken => 'May account na gumagamit ng email na ito.';

  @override
  String get errorTooManyAttempts =>
      'Masyadong maraming subok. Maghintay ng ilang minuto at subukan ulit.';

  @override
  String get navHome => 'Home';

  @override
  String get navSales => 'Benta';

  @override
  String get navExpenses => 'Gastos';

  @override
  String get navProducts => 'Paninda';

  @override
  String get navReports => 'Ulat';

  @override
  String get periodToday => 'Ngayon';

  @override
  String get periodWeek => 'Ngayong linggo';

  @override
  String get periodMonth => 'Ngayong buwan';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentGcash => 'GCash';

  @override
  String get paymentMaya => 'Maya';

  @override
  String get paymentBankTransfer => 'Bank transfer';

  @override
  String get paymentUtang => 'Utang';

  @override
  String get categoryInventory => 'Paninda / Puhunan';

  @override
  String get categoryUtilities => 'Kuryente at tubig';

  @override
  String get categorySalary => 'Sahod';

  @override
  String get categoryTransportation => 'Pamasahe / Biyahe';

  @override
  String get categoryRent => 'Upa';

  @override
  String get categorySupplies => 'Gamit sa tindahan';

  @override
  String get categoryRepairs => 'Pagpapaayos';

  @override
  String get categoryTaxesPermits => 'Buwis at permit';

  @override
  String get categoryOther => 'Iba pa';

  @override
  String get welcomeSubtitle =>
      'Piliin kung paano mo itatago ang iyong mga record. Pwede mo itong palitan mamaya.';

  @override
  String get welcomeLocalTitle => 'Sa phone lang na ito';

  @override
  String get welcomeLocalDescription =>
      'Lahat ay nasa device na ito. Walang kailangang account.';

  @override
  String get welcomeLocalPoint1 => 'Gumagana kahit walang load at signal';

  @override
  String get welcomeLocalPoint2 => 'Walang babayaran, walang sign-up';

  @override
  String get welcomeLocalPoint3 =>
      'Ang device lang na ito ang makakakita ng records mo';

  @override
  String get welcomeCloudTitle => 'I-save sa cloud';

  @override
  String get welcomeCloudDescription =>
      'Gumagana pa rin offline, at may backup kaya hindi mawawala ang records mo.';

  @override
  String get welcomeCloudPoint1 =>
      'Gamitin ang parehong tindahan sa phone at tablet';

  @override
  String get welcomeCloudPoint2 => 'Ligtas kahit mawala o masira ang phone mo';

  @override
  String get welcomeCloudPoint3 =>
      'Makakapagtala ng benta ang katulong mo kahit wala ka';

  @override
  String get welcomeHaveAccount => 'May account na ako';

  @override
  String get welcomeStartHere => 'Dito magsimula';

  @override
  String get setupTitle => 'I-set up ang tindahan mo';

  @override
  String get setupSubtitle => 'Mga sampung segundo lang ito.';

  @override
  String get setupStoreHint => 'Aling Nena Sari-Sari Store';

  @override
  String get setupNameHint => 'Nena Reyes';

  @override
  String get setupSubmit => 'Simulan ang Kitaza';

  @override
  String get setupFailed => 'Hindi ma-set up. Subukan ulit.';

  @override
  String get signInTitle => 'Maligayang pagbabalik';

  @override
  String get signInSubtitle =>
      'Isang beses lang mag-sign in. Tatandaan ka ng device na ito.';

  @override
  String get signInSubmit => 'Mag-sign in';

  @override
  String get signInCreateAccount => 'Gumawa ng bagong account';

  @override
  String get signInFailed => 'Hindi maka-sign in.';

  @override
  String get signUpTitle => 'Gumawa ng account';

  @override
  String get signUpSubtitle =>
      'Nasa phone na ito ang records mo at may backup sa cloud.';

  @override
  String get signUpSubmit => 'Gumawa ng account';

  @override
  String get signUpFailed => 'Hindi magawa ang account mo.';

  @override
  String get dashboardYourStore => 'Tindahan mo';

  @override
  String get dashboardGoodMorning => 'Magandang umaga';

  @override
  String get dashboardGoodAfternoon => 'Magandang hapon';

  @override
  String get dashboardGoodEvening => 'Magandang gabi';

  @override
  String get dashboardMoneyThisPeriod => 'Pera ngayong panahon';

  @override
  String get dashboardEmptyTitle => 'Wala pang naitala';

  @override
  String get dashboardEmptyMessage =>
      'Pindutin ang \"Magbenta\" pagkatapos ng susunod mong customer. Mga limang segundo lang, at ang iba ay susunod na.';

  @override
  String get dashboardSales => 'Benta';

  @override
  String dashboardSaleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count benta',
    );
    return '$_temp0';
  }

  @override
  String get dashboardExpenses => 'Gastos';

  @override
  String dashboardCostOfGoods(Object amount) {
    return 'Puhunan sa nabenta $amount';
  }

  @override
  String get dashboardProfit => 'Kita';

  @override
  String dashboardMarginOfSales(Object percent) {
    return '$percent% ng benta';
  }

  @override
  String get dashboardCashKept => 'Natirang pera';

  @override
  String get dashboardAfterWithdrawals => 'Pagkatapos ng kinuha mo';

  @override
  String get dashboardWithdrawalsTitle => 'Kinuha ng may-ari';

  @override
  String dashboardWithdrawalsTaken(Object amount) {
    return 'Kumuha ka ng $amount ngayong panahon';
  }

  @override
  String get dashboardWithdrawalsPrompt =>
      'Itala ang perang kinukuha mo para sa sarili';

  @override
  String get dashboardTopSeller => 'Pinakamabenta';

  @override
  String dashboardSoldSummary(Object quantity, Object revenue) {
    return '$quantity nabenta · $revenue';
  }

  @override
  String dashboardLowStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paninda ang paubos na',
    );
    return '$_temp0';
  }

  @override
  String get dashboardLowStockHint =>
      'Pindutin para makita ang kailangang i-restock';

  @override
  String get actionAddSale => 'Magbenta';

  @override
  String get actionExpense => 'Gastos';

  @override
  String get actionProfit => 'Kita';

  @override
  String get healthGood => 'Maayos';

  @override
  String get healthAverage => 'Katamtaman';

  @override
  String get healthWarning => 'Babala';

  @override
  String get healthHeadlineGreen => 'Maayos ang tindahan mo';

  @override
  String get healthHeadlineYellow => 'Bantayan ang mga numero mo';

  @override
  String get healthHeadlineRed => 'Kailangan ng pansin ang tindahan mo';

  @override
  String get healthHeadlineNoSales => 'Wala pang naitalang benta';

  @override
  String healthRatingChip(Object rating, int score) {
    return '$rating · $score';
  }

  @override
  String get healthReasonNoSales =>
      'Itala ang unang benta para makita kung kumusta ang tindahan mo.';

  @override
  String healthReasonProfit(Object amount) {
    return 'Kumita ka ng $amount.';
  }

  @override
  String healthReasonLoss(Object amount) {
    return 'Mas malaki ng $amount ang gastos mo kaysa sa benta.';
  }

  @override
  String healthReasonHealthyMargin(int percent) {
    return 'Maganda ang tubo: $percent% ng benta ay kita.';
  }

  @override
  String healthReasonThinMargin(int percent) {
    return 'Maliit ang tubo: $percent% lang ng benta ang kita.';
  }

  @override
  String healthReasonVeryThinMargin(int percent) {
    return 'Napakaliit ng tubo: $percent% ng benta ang kita.';
  }

  @override
  String get healthReasonProfitUp =>
      'Mas mataas ang kita kaysa noong nakaraan.';

  @override
  String get healthReasonProfitDown =>
      'Mas mababa ang kita kaysa noong nakaraan.';

  @override
  String healthReasonOverWithdrawn(Object amount) {
    return 'Kumuha ka ng $amount, mas malaki kaysa sa kinita mo.';
  }

  @override
  String healthReasonRestock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paninda ang kailangang i-restock.',
    );
    return '$_temp0';
  }

  @override
  String get saleTitle => 'Magbenta';

  @override
  String get saleProduct => 'Paninda';

  @override
  String get saleTotal => 'Kabuuan';

  @override
  String saleTyping(Object amount) {
    return 'Tina-type: $amount';
  }

  @override
  String saleSaveAmount(Object amount) {
    return 'I-save ang $amount';
  }

  @override
  String get saleNeedsSomething =>
      'Maglagay muna ng halaga o pumili ng paninda.';

  @override
  String get saleRecorded => 'Naitala ang benta.';

  @override
  String get saleSaveFailed => 'Hindi ma-save ang benta. Subukan ulit.';

  @override
  String saleProductAdded(Object name) {
    return 'Naidagdag ang $name.';
  }

  @override
  String saleEach(Object price) {
    return '$price bawat isa';
  }

  @override
  String get saleLess => 'Bawasan';

  @override
  String get saleMore => 'Dagdagan';

  @override
  String get saleQuickSale => 'Mabilisang benta';

  @override
  String saleItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get saleGeneric => 'Benta';

  @override
  String get saleHistoryEmptyTitle => 'Walang benta sa panahong ito';

  @override
  String get saleHistoryEmptyMessage =>
      'Lahat ng benta na itatala mo ay makikita dito kasama ang kita.';

  @override
  String get saleHistoryEmptyAction => 'Magtala ng benta';

  @override
  String saleProfitAmount(Object amount) {
    return '$amount kita';
  }

  @override
  String get saleVoidTitle => 'I-void ang bentang ito?';

  @override
  String get saleVoidMessage =>
      'Tatanggalin ang halaga sa kabuuan at ibabalik ang stock.';

  @override
  String get saleVoidKeep => 'Huwag';

  @override
  String get saleVoidConfirm => 'I-void';

  @override
  String get saleVoided => 'Na-void ang benta.';

  @override
  String get salePickerSearch => 'Hanapin ang paninda o i-scan';

  @override
  String get salePickerEmptyTitle => 'Wala pang paninda';

  @override
  String get salePickerEmptyMessage =>
      'Pwede ka pa ring magtala ng benta sa pag-type ng halaga sa keypad.';

  @override
  String get saleOutOfStock => 'Ubos na';

  @override
  String saleStockLeft(Object quantity, Object unit) {
    return '$quantity $unit na lang';
  }

  @override
  String get keypadBackspace => 'Burahin ang huling numero';

  @override
  String get keypadBackspaceHint => 'Pindutin nang matagal para burahin lahat';

  @override
  String get keypadDecimal => 'Tuldok';

  @override
  String get expenseTitle => 'Magtala ng gastos';

  @override
  String get expenseWhatFor => 'Para saan ito?';

  @override
  String get expenseNoteHint => 'Bayad sa Meralco ngayong Oktubre';

  @override
  String get expenseSave => 'I-save ang gastos';

  @override
  String get expenseRecorded => 'Naitala ang gastos.';

  @override
  String get expenseSaveFailed => 'Hindi ma-save. Subukan ulit.';

  @override
  String get expenseHistoryEmptyTitle => 'Wala pang naitalang gastos';

  @override
  String get expenseHistoryEmptyMessage =>
      'Itala ang gastos sa paninda, load, pamasahe at bayarin para totoo ang kita mo.';

  @override
  String get expenseHistoryEmptyAction => 'Magtala ng gastos';

  @override
  String get productAdd => 'Magdagdag ng paninda';

  @override
  String get productEdit => 'Baguhin ang paninda';

  @override
  String get productName => 'Pangalan ng paninda';

  @override
  String get productNameHint => 'Lucky Me Pancit Canton';

  @override
  String get productCost => 'Puhunan';

  @override
  String get productPrice => 'Presyo';

  @override
  String get productStock => 'Stock ngayon';

  @override
  String get productReorder => 'Paalalahanan pag bumaba sa';

  @override
  String get productSave => 'I-save ang paninda';

  @override
  String get productSaved => 'Na-save ang paninda.';

  @override
  String get productSaveFailed => 'Hindi ma-save ang paninda.';

  @override
  String get productSearch => 'Hanapin ang paninda';

  @override
  String get productEmptyTitle => 'Wala pang paninda';

  @override
  String get productEmptyMessage =>
      'Kapag nailagay mo ang mga karaniwang paninda, isang pindot na lang ang bawat benta, at malalaman mo kung alin ang talagang kumikita.';

  @override
  String get productEmptyAction => 'Idagdag ang unang paninda';

  @override
  String productMargin(Object percent) {
    return '$percent% tubo';
  }

  @override
  String get productRestock => 'I-restock';

  @override
  String productStockUnits(Object quantity, Object unit) {
    return '$quantity $unit';
  }

  @override
  String productWouldLose(Object amount) {
    return 'Malulugi ka ng $amount bawat benta';
  }

  @override
  String productEarns(Object amount, Object percent) {
    return 'Kikita ka ng $amount ($percent%) bawat benta';
  }

  @override
  String get withdrawalTitle => 'Kinuha ng may-ari';

  @override
  String get withdrawalRecord => 'Itala';

  @override
  String get withdrawalEmptyTitle => 'Wala pang naitalang kinuha';

  @override
  String get withdrawalEmptyMessage =>
      'Kapag kumuha ka ng pera sa tindahan para sa sarili, itala ito dito para tama ang kita mo.';

  @override
  String get withdrawalExplainer =>
      'Hindi gastos ng negosyo ang perang iniuuwi mo. Kapag itinala mo ito dito, tapat ang kita mo at makikita mo kung magkano talaga ang natitira.';

  @override
  String get withdrawalDefaultReason => 'Personal na gamit';

  @override
  String get withdrawalRecorded => 'Naitala ang kinuhang pera.';

  @override
  String get withdrawalSheetTitle => 'Perang kinuha';

  @override
  String get withdrawalReason => 'Para saan? (hindi kailangan)';

  @override
  String get withdrawalReasonHint => 'Pang-grocery, tuition, baon';

  @override
  String get withdrawalSubmit => 'Itala ang kinuha';

  @override
  String get reportTitle => 'Ulat';

  @override
  String get reportEmptyTitle => 'Wala pang maiuulat';

  @override
  String get reportEmptyMessage =>
      'Magtala ng ilang benta at gastos, at ipapakita dito kung aling paninda ang kumikita, saan napupunta ang pera mo, at kung paano gumagalaw ang kita mo.';

  @override
  String get reportTrendTitle => 'Kita bawat araw, huling 14 na araw';

  @override
  String get reportTrendHint => 'Pindutin ang bar para makita ang araw na iyon';

  @override
  String reportTrendSummary(
    int days,
    Object bestDay,
    Object bestAmount,
    Object worstDay,
    Object worstAmount,
  ) {
    return 'Kita bawat araw sa huling $days na araw. Pinakamagandang araw: $bestDay, $bestAmount. Pinakamahinang araw: $worstDay, $worstAmount.';
  }

  @override
  String get reportTopProducts => 'Saan nanggagaling ang kita mo';

  @override
  String get reportExpenseBreakdown => 'Saan napupunta ang pera mo';

  @override
  String get reportUnusual => 'Tingnan ulit';

  @override
  String reportUnusualDetail(Object times, Object average, Object date) {
    return '${times}x ng karaniwang $average · $date';
  }

  @override
  String get settingsAppearance => 'Itsura';

  @override
  String get settingsAppearanceHint =>
      'Mas madali sa mata ang dark mode sa gabi; sinusunod ng Auto ang phone mo.';

  @override
  String get settingsThemeLight => 'Maliwanag';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeDark => 'Madilim';

  @override
  String get settingsLanguage => 'Wika';

  @override
  String get settingsLanguageAuto => 'Auto';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageFilipino => 'Filipino';

  @override
  String get settingsYourData => 'Ang data mo';

  @override
  String get settingsAccount => 'Account';

  @override
  String get storageLocalTitle => 'Sa phone lang na ito naka-save';

  @override
  String get storageLocalRisk =>
      'Kapag nawala o nasira ang phone na ito, kasama nang mawawala ang records mo.';

  @override
  String get storageBackUp => 'I-backup sa cloud';

  @override
  String get storageBackUpHint => 'Mananatili ang lahat ng naitala mo';

  @override
  String get storageCloudTitle => 'May backup sa cloud';

  @override
  String get storageNotSynced => 'Hindi pa naka-sync';

  @override
  String storageLastSynced(Object when) {
    return 'Huling sync: $when';
  }

  @override
  String storagePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ang naghihintay i-upload',
    );
    return '$_temp0';
  }

  @override
  String get storagePendingHint =>
      'Mag-a-upload ang mga ito pag may signal na.';

  @override
  String storageParked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ang hindi ma-save',
    );
    return '$_temp0';
  }

  @override
  String get storageParkedHint =>
      'Pindutin para malaman kung bakit at kung ano ang gagawin';

  @override
  String get storageSyncNow => 'I-sync ngayon';

  @override
  String get storageUpToDate => 'Updated na ang lahat.';

  @override
  String get storageUnreachable => 'Hindi maabot ang cloud. Susubukan ulit.';

  @override
  String get syncSavedOnPhone => 'Naka-save sa phone na ito';

  @override
  String get syncSyncing => 'Nagsi-sync';

  @override
  String get syncOffline => 'Offline';

  @override
  String get syncBackedUp => 'May backup';

  @override
  String get syncProblem => 'Problema sa sync';

  @override
  String syncWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ang naghihintay i-sync',
    );
    return '$_temp0';
  }

  @override
  String get problemsTitle => 'Problema sa sync';

  @override
  String get problemsEmptyTitle => 'Walang naipit';

  @override
  String get problemsEmptyMessage =>
      'Nasa cloud na ang lahat o naghihintay ng pagkakataon.';

  @override
  String get problemsRefused => 'Tinanggihan ng server';

  @override
  String problemsStopped(int count) {
    return 'Tumigil nang sumubok pagkatapos ng $count beses.';
  }

  @override
  String problemsWillRetry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinubukan nang $count beses; susubukan ulit.',
    );
    return '$_temp0';
  }

  @override
  String get problemsKeepLocal => 'Sa phone lang itago';

  @override
  String get problemsDiscardTitle => 'Itigil ang pag-upload nito?';

  @override
  String get problemsDiscardMessage =>
      'Mananatili ito sa records mo sa phone na ito, pero wala ito sa ibang device at sa backup sa cloud.';

  @override
  String get problemsSale => 'Benta';

  @override
  String problemsExpense(Object detail) {
    return 'Gastos: $detail';
  }

  @override
  String get problemsWithdrawal => 'Kinuhang pera';

  @override
  String problemsProduct(Object name) {
    return 'Paninda: $name';
  }

  @override
  String get problemsStockChange => 'Pagbabago sa stock';

  @override
  String problemsRemoval(Object entity) {
    return 'Pagtanggal ng $entity';
  }

  @override
  String get problemsChange => 'Pagbabago';

  @override
  String get upgradeTitle => 'I-backup sa cloud';

  @override
  String get upgradeIntro =>
      'Mananatili ang lahat ng naitala mo sa phone na ito, at makokopya sa account mo. Gagana pa rin ang app offline gaya ng dati.';

  @override
  String get upgradeNewAccount => 'Bagong account';

  @override
  String get upgradeExistingAccount => 'May account na ako';

  @override
  String get upgradeExistingNote =>
      'Idadagdag ang records ng phone na ito sa tindahan ng account na iyon.';

  @override
  String get upgradeCreateSubmit => 'Gumawa ng account at i-backup';

  @override
  String get upgradeSignInSubmit => 'Mag-sign in at i-backup';

  @override
  String get upgradeDone => 'May backup na ang tindahan mo.';

  @override
  String get upgradeFailed => 'Hindi ma-backup ngayon. Walang nabago.';

  @override
  String get accountOfflineProfile => 'Offline na profile';

  @override
  String get accountSignOut => 'Mag-sign out';

  @override
  String get accountSignOutTitle => 'Mag-sign out?';

  @override
  String get accountSignOutLocal =>
      'Nasa phone lang na ito ang records mo. Mabubura ang lahat ng ito kapag nag-sign out ka.';

  @override
  String get accountSignOutClean =>
      'May backup na ang lahat. Mag-sign in ulit sa kahit anong phone para ituloy.';

  @override
  String accountSignOutUnsent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'May $count pagbabago na hindi pa nakakarating sa cloud, at mawawala kapag nag-sign out ka ngayon. Subukan ulit pag may signal.',
    );
    return '$_temp0';
  }

  @override
  String get accountEraseAndSignOut => 'Burahin at mag-sign out';

  @override
  String get starterTitle => 'Magsimula sa karaniwang paninda';

  @override
  String get starterIntro =>
      'Lagyan ng tsek ang mga binebenta mo. Pwede mong palitan ang pangalan at presyo anumang oras.';

  @override
  String get starterPricesNotice =>
      'Karaniwang presyo lang ang mga ito, hindi sa iyo. Tingnan ang puhunan at presyo ng bawat isa para tama ang kita mo.';

  @override
  String starterAdd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Idagdag ang $count paninda',
      zero: 'Pumili ng kahit isa',
    );
    return '$_temp0';
  }

  @override
  String starterAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Naidagdag ang $count paninda. Tingnan ang mga presyo kapag may oras ka.',
    );
    return '$_temp0';
  }

  @override
  String get starterAll => 'Lahat';

  @override
  String get starterOffer => 'Idagdag ang karaniwang paninda';

  @override
  String get starterPromptTitle => 'Wala pang laman ang listahan ng paninda';

  @override
  String get starterPromptMessage =>
      'Magsimula sa karaniwang paninda ng sari-sari store, para isang pindot na lang ang bawat benta.';

  @override
  String get backupSection => 'Backup';

  @override
  String get backupAutoNone =>
      'Wala pang awtomatikong kopya. May ginagawang kopya bawat araw na binubuksan mo ang app.';

  @override
  String backupAutoLast(Object when) {
    return 'May kopyang naka-save sa phone na ito araw-araw. Huling kopya: $when';
  }

  @override
  String get backupCloudNote => 'Nakatago rin sa cloud ang records mo.';

  @override
  String get backupExport => 'Mag-save ng backup na kopya';

  @override
  String get backupExportHint =>
      'Ipadala ito sa sarili mo sa Messenger, Drive o email para ligtas kahit mawala ang phone na ito.';

  @override
  String backupExportText(Object store) {
    return 'Kitaza backup ng $store. Itago ang file na ito sa ligtas na lugar.';
  }

  @override
  String get backupExportFailed => 'Hindi makagawa ng backup na kopya.';

  @override
  String get backupRestore => 'I-restore mula sa backup file';

  @override
  String get backupRestoreHint =>
      'Papalitan ang lahat ng nasa phone na ito ng records sa file.';

  @override
  String get backupConfirmTitle => 'I-restore ang backup na ito?';

  @override
  String backupConfirmSummary(Object store, int sales, int products) {
    String _temp0 = intl.Intl.pluralLogic(
      sales,
      locale: localeName,
      other: '$sales benta',
    );
    String _temp1 = intl.Intl.pluralLogic(
      products,
      locale: localeName,
      other: '$products paninda',
    );
    return '$store: $_temp0 at $_temp1.';
  }

  @override
  String backupConfirmLastEntry(Object when) {
    return 'Huling tala: $when.';
  }

  @override
  String get backupConfirmWarning =>
      'Papalitan ang lahat ng kasalukuyang nasa phone na ito.';

  @override
  String get backupConfirmAction => 'Palitan at i-restore';

  @override
  String get backupProblemNotABackup => 'Hindi Kitaza backup ang file na iyan.';

  @override
  String get backupProblemTooNew =>
      'Ginawa ang backup na ito ng mas bagong Kitaza. I-update muna ang app, saka subukan ulit.';

  @override
  String get backupProblemDamaged =>
      'Sira ang backup file na ito at hindi ma-restore.';

  @override
  String reportsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ulat ng problema',
    );
    return '$_temp0';
  }

  @override
  String get reportsCloudHint =>
      'Awtomatikong ipinapadala sa Kitaza team kapag nag-sync ka.';

  @override
  String get reportsLocalHint =>
      'Pindutin para ipadala sa Kitaza team. Walang benta o detalye ng customer ang mga ito.';

  @override
  String get reportsShareIntro =>
      'Mga ulat ng problema sa Kitaza. Walang benta o detalye ng customer ang mga ito.';

  @override
  String get scanAction => 'I-scan';

  @override
  String get scanTitle => 'I-scan ang barcode';

  @override
  String get scanHint => 'Itutok ang camera sa barcode';

  @override
  String get scanLight => 'Ilaw';

  @override
  String get scanDone => 'Tapos na';

  @override
  String scanAdded(Object name) {
    return 'Naidagdag ang $name';
  }

  @override
  String get scanUnknownTitle => 'Wala pang paninda na may ganitong code';

  @override
  String scanUnknownMessage(Object code) {
    return 'Code $code. Idagdag ito bilang bagong paninda para makita sa susunod na scan.';
  }

  @override
  String get scanAddProduct => 'Idagdag bilang bagong paninda';

  @override
  String get scanNoCamera =>
      'Kailangan ng Kitaza ang camera para mag-scan. Payagan ito sa settings ng phone mo.';

  @override
  String get productBarcode => 'Barcode (hindi kailangan)';

  @override
  String get receiptTitle => 'Resibo';

  @override
  String get receiptSubtotal => 'Subtotal';

  @override
  String get receiptDiscount => 'Diskwento';

  @override
  String get receiptTotal => 'KABUUAN';

  @override
  String get receiptPaidBy => 'Bayad sa';

  @override
  String receiptReference(Object code) {
    return 'Ref $code';
  }

  @override
  String get receiptThanks => 'Salamat po!';

  @override
  String get receiptShare => 'Ibahagi';

  @override
  String get receiptPrint => 'I-print';

  @override
  String get receiptPrinted => 'Na-print ang resibo.';

  @override
  String get receiptNoPrinter =>
      'Wala pang printer ng resibo. Mag-set up sa Settings.';

  @override
  String get printerSection => 'Printer ng resibo';

  @override
  String get printerNone => 'Wala pang napili';

  @override
  String get printerChoose => 'Pumili ng printer';

  @override
  String get printerChooseHint =>
      'I-pair muna ang printer sa Bluetooth settings ng phone mo, saka piliin dito.';

  @override
  String get printerNoneFound =>
      'Walang naka-pair na Bluetooth device. I-pair muna ang printer sa Bluetooth settings ng phone mo.';

  @override
  String get printerPaper => 'Lapad ng papel';

  @override
  String get printerTest => 'Mag-print ng test na resibo';

  @override
  String get printerTestLine =>
      'Test ng printer - kung nababasa mo ito, gumagana.';

  @override
  String get printerBluetoothOff =>
      'Naka-off ang Bluetooth. Buksan ito at subukan ulit.';

  @override
  String get printerNoPermission =>
      'Kailangan ng Kitaza ng pahintulot sa Bluetooth para mag-print. Payagan ito sa settings ng phone mo.';

  @override
  String get printerCouldNotConnect =>
      'Hindi makakonekta sa printer. Tiyaking naka-on at malapit ito.';

  @override
  String get printerFailed =>
      'Hindi tinanggap ng printer ang resibo. Subukan ulit.';

  @override
  String get welcomeJoinStaff => 'Sumali sa tindahan bilang staff';

  @override
  String get joinTitle => 'Sumali sa tindahan';

  @override
  String get joinSubtitle =>
      'Humingi ng join code sa may-ari ng tindahan. Gagawa sila nito sa Settings, sa Staff.';

  @override
  String get joinCodeLabel => 'Join code';

  @override
  String get joinCodeInvalid =>
      'Ilagay ang lahat ng 10 letra at numero ng code';

  @override
  String get joinAction => 'Sumali';

  @override
  String get joinCodeRefused =>
      'Hindi gumana ang code na iyan. Baka nagamit na o expired na. Humingi ng bago sa may-ari.';

  @override
  String get joinSharedPhoneNote =>
      'Isang phone lang ang puwede sa bawat code. Mapupunta sa tindahan ang lahat ng itatala mo rito, sa pangalan mo.';

  @override
  String get sessionEndedTitle => 'Na-sign out ang phone na ito';

  @override
  String sessionEndedMessage(Object store) {
    return 'Na-sign out ang $store sa phone na ito mula sa ibang device, o tinanggal ang access mo rito.';
  }

  @override
  String sessionEndedUnsent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count na entry na naitala rito ang hindi pa nakakarating sa cloud. Mag-sign in ulit para maipadala.',
      zero: 'Nakarating na sa cloud ang lahat ng naitala rito.',
    );
    return '$_temp0';
  }

  @override
  String get sessionEndedSignIn => 'Mag-sign in ulit';

  @override
  String get sessionEndedJoin => 'Maglagay ng bagong join code';

  @override
  String get sessionEndedClear => 'Alisin ang tindahan sa phone na ito';

  @override
  String get sessionEndedClearTitle => 'Alisin ang records ng tindahan?';

  @override
  String sessionEndedClearMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tuluyang mawawala ang $count na entry na hindi nakarating sa cloud.',
      zero: 'Nasa cloud na ang lahat ng narito, kaya walang mawawala.',
    );
    return '$_temp0';
  }

  @override
  String get sessionEndedClearConfirm => 'Alisin';

  @override
  String get settingsTeam => 'Mga tindahan at staff';

  @override
  String get storesHint =>
      'I-tap ang tindahan para buksan. May sariling produkto, benta at staff ang bawat isa.';

  @override
  String get storesOpenNow => 'Bukas ngayon';

  @override
  String get storesAdd => 'Magdagdag ng tindahan';

  @override
  String get storesAddTitle => 'Bagong tindahan';

  @override
  String get storesAddSubmit => 'Idagdag';

  @override
  String get storesRename => 'Palitan ang pangalan';

  @override
  String storesSwitched(Object store) {
    return 'Nasa $store ka na ngayon';
  }

  @override
  String get storesPickerTitle => 'Magbukas ng tindahan';

  @override
  String get storesSwitchHint => 'Lumipat ng tindahan';

  @override
  String get teamLocalTitle => 'Staff at iba pang tindahan';

  @override
  String get teamLocalMessage =>
      'Kailangang nasa cloud ang records mo para sa staff accounts, higit sa isang tindahan, at pag-sign out ng nawalang phone.';

  @override
  String get staffTitle => 'Staff';

  @override
  String get staffTileHint =>
      'Hayaang magbenta ang katulong gamit ang sariling phone';

  @override
  String get staffEmptyTitle => 'Wala pang staff';

  @override
  String get staffEmptyMessage =>
      'Idagdag ang mga tumutulong sa tindahan. Magbebenta sila gamit ang sariling phone, at ikaw ang pipili kung ano pa ang puwede nilang gawin.';

  @override
  String get staffAdd => 'Magdagdag ng staff';

  @override
  String get staffNameLabel => 'Pangalan niya';

  @override
  String get staffAlwaysSells =>
      'Laging puwedeng magtala ng benta ang staff. Piliin kung ano pa ang puwede niyang gawin:';

  @override
  String get permissionManageProducts => 'Mag-ayos ng produkto';

  @override
  String get permissionManageProductsHint =>
      'Magdagdag at magbago ng produkto at presyo, magtala ng deliveries at bilang ng stock';

  @override
  String get permissionRecordExpenses => 'Magtala ng gastos';

  @override
  String get permissionRecordExpensesHint => 'Itala ang ginagastos ng tindahan';

  @override
  String get permissionViewProfit => 'Makita ang kita at puhunan';

  @override
  String get permissionViewProfitHint =>
      'Puhunan, kita, gastos at ang health score. Kung wala ito, hindi makakarating sa phone niya ang puhunan.';

  @override
  String get permissionDeleteRecords => 'Mag-void at magbura';

  @override
  String get permissionDeleteRecordsHint =>
      'Mag-void ng benta at magbura ng gastos. Nakatala sa activity log ang bawat void.';

  @override
  String get staffSells => 'Nagbebenta';

  @override
  String get staffShortProducts => 'produkto';

  @override
  String get staffShortExpenses => 'gastos';

  @override
  String get staffShortProfit => 'kita';

  @override
  String get staffShortDelete => 'void';

  @override
  String staffDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Naka-sign in sa $count phone',
      zero: 'Hindi pa naka-sign in',
    );
    return '$_temp0';
  }

  @override
  String staffCodeWorksUntil(Object when) {
    return 'Gumagana ang join code hanggang $when';
  }

  @override
  String get staffNewCode => 'Gumawa ng bagong join code';

  @override
  String get staffNewCodeHint =>
      'Para sa bago o pinalitang phone. Hindi na gagana ang naunang code.';

  @override
  String get staffRemove => 'Alisin sa tindahan';

  @override
  String staffRemoveTitle(Object name) {
    return 'Alisin si $name?';
  }

  @override
  String staffRemoveMessage(Object name) {
    return 'Agad na masa-sign out ang phone ni $name. Hindi na darating ang mga benta roon na hindi pa nakakarating sa cloud.';
  }

  @override
  String staffRemoved(Object name) {
    return 'Inalis si $name';
  }

  @override
  String get staffSaved =>
      'Na-save. Makukuha ito ng phone niya sa loob ng ilang minuto.';

  @override
  String inviteTitle(Object name) {
    return 'Join code para kay $name';
  }

  @override
  String inviteSteps(Object name) {
    return 'Sa phone ni $name, buksan ang Kitaza, i-tap ang “Sumali sa tindahan bilang staff” at ilagay ang code na ito.';
  }

  @override
  String inviteExpires(Object when) {
    return 'Gagana sa isang phone lang, hanggang $when.';
  }

  @override
  String get inviteShare => 'Ibahagi ang code';

  @override
  String get inviteCopy => 'Kopyahin';

  @override
  String get inviteCopied => 'Nakopya ang code';

  @override
  String inviteShareText(Object store, Object code) {
    return 'Sumali sa $store sa Kitaza: buksan ang Kitaza, i-tap ang “Sumali sa tindahan bilang staff” at ilagay ang $code. Isang beses lang gagana ang code, sa loob ng isang araw.';
  }

  @override
  String get inviteDone => 'Tapos na';

  @override
  String get devicesTitle => 'Mga naka-sign in na device';

  @override
  String get devicesTileHint =>
      'Bawat phone na gumagamit ng tindahan mo. I-sign out ang nawala.';

  @override
  String get devicesIntro =>
      'Bawat phone na nakakabukas ng mga tindahan mo. I-sign out ang nawala, naibenta, o sa taong umalis na.';

  @override
  String get devicesThisPhone => 'Ang phone na ito';

  @override
  String get devicesYou => 'Ikaw';

  @override
  String devicesStaff(Object name) {
    return '$name, staff';
  }

  @override
  String devicesLastActive(Object when) {
    return 'Huling ginamit $when';
  }

  @override
  String get devicesSignOut => 'I-sign out';

  @override
  String devicesSignOutTitle(Object device) {
    return 'I-sign out ang $device?';
  }

  @override
  String get devicesSignOutMessage =>
      'Agad itong titigil sa pag-sync at kailangang mag-sign in ulit para magamit. Hindi na darating ang anumang nasa kanya na hindi pa nakakarating sa cloud.';

  @override
  String devicesSignedOut(Object device) {
    return 'Na-sign out ang $device';
  }

  @override
  String get activityTitle => 'Aktibidad';

  @override
  String get activityTileHint => 'Sino ang nagtala, nagbago at nag-void ng ano';

  @override
  String get activityFilterAll => 'Lahat';

  @override
  String get activityFilterRemovals => 'Mga void at binura';

  @override
  String get activityEmptyTitle => 'Wala pa rito';

  @override
  String get activityEmptyMessage =>
      'Nakalista rito ang mga benta, pagbabago at void mula sa bawat phone, pati kung sino ang gumawa.';

  @override
  String get activityShowOlder => 'Ipakita ang mas luma';

  @override
  String activitySaleRecorded(Object name, Object amount) {
    return 'Nagtala si $name ng benta na $amount';
  }

  @override
  String activitySaleVoided(Object name, Object amount) {
    return 'Nag-void si $name ng benta na $amount';
  }

  @override
  String activityExpenseRecorded(Object name, Object amount, Object category) {
    return 'Nagtala si $name ng $amount para sa $category';
  }

  @override
  String activityExpenseDeleted(Object name, Object amount, Object category) {
    return 'Binura ni $name ang $amount para sa $category';
  }

  @override
  String activityWithdrawalRecorded(Object name, Object amount) {
    return 'Kumuha si $name ng $amount para sa sarili';
  }

  @override
  String activityWithdrawalDeleted(Object name, Object amount) {
    return 'Binura ni $name ang withdrawal na $amount';
  }

  @override
  String activityProductAdded(Object name, Object product, Object price) {
    return 'Idinagdag ni $name ang $product sa halagang $price';
  }

  @override
  String activityProductChanged(Object name, Object product) {
    return 'Binago ni $name ang $product';
  }

  @override
  String activityProductRemoved(Object name, Object product) {
    return 'Inalis ni $name ang $product';
  }

  @override
  String activityPriceChange(Object before, Object after) {
    return 'Presyo $before papuntang $after';
  }

  @override
  String activityCostChange(Object before, Object after) {
    return 'Puhunan $before papuntang $after';
  }

  @override
  String activityRenamedFrom(Object before) {
    return 'Dating “$before”';
  }

  @override
  String activityStockReceived(Object name, Object quantity, Object product) {
    return 'Tumanggap si $name ng $quantity $product';
  }

  @override
  String activityStockRemoved(Object name, Object quantity, Object product) {
    return 'Naglabas si $name ng $quantity $product';
  }

  @override
  String activityStockCounted(Object name, Object quantity, Object product) {
    return 'Nagbilang si $name ng $quantity $product';
  }

  @override
  String activityStockDifference(Object change) {
    return '$change kumpara sa inaasahan';
  }

  @override
  String activityStockSpoiled(Object name, Object quantity, Object product) {
    return 'Minarkahan ni $name na sira ang $quantity $product';
  }

  @override
  String activityStaffAdded(Object name, Object staff) {
    return 'Idinagdag ni $name si $staff bilang staff';
  }

  @override
  String activityStaffChanged(Object name, Object staff) {
    return 'Binago ni $name ang puwedeng gawin ni $staff';
  }

  @override
  String activityStaffRemoved(Object name, Object staff) {
    return 'Inalis ni $name si $staff';
  }

  @override
  String activityStaffInvited(Object name, Object staff) {
    return 'Gumawa si $name ng join code para kay $staff';
  }

  @override
  String activityStaffJoined(Object name, Object device) {
    return 'Sumali si $name gamit ang $device';
  }

  @override
  String activityDeviceSignedOut(Object name, Object member, Object device) {
    return 'Na-sign out ni $name ang $device ni $member';
  }

  @override
  String activityStoreAdded(Object name, Object store) {
    return 'Binuksan ni $name ang $store';
  }

  @override
  String activityStoreRenamed(Object name, Object before, Object store) {
    return 'Pinalitan ni $name ang pangalan ng $before ng $store';
  }

  @override
  String activityOther(Object name) {
    return 'May binago si $name';
  }

  @override
  String get activityStaffBadge => 'Staff';

  @override
  String accountStaffAt(Object store) {
    return 'Staff sa $store';
  }

  @override
  String get accountStaffSignOutNote =>
      'Para magamit ulit ang phone na ito, kailangan mo ng bagong join code mula sa may-ari.';

  @override
  String get productCostSetByOwner => 'Ang may-ari ang nagtatakda ng puhunan.';

  @override
  String get syncNotAllowed =>
      'Hindi ito pinapayagan ng access mo. Magtanong sa may-ari.';

  @override
  String get settingsPlan => 'Plan';

  @override
  String get planTitle => 'Ang plan mo';

  @override
  String planStatusTrial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Libreng Pro trial, $count araw pa',
    );
    return '$_temp0';
  }

  @override
  String planStatusActive(Object plan, Object date) {
    return '$plan, bayad hanggang $date';
  }

  @override
  String planStatusGrace(Object date) {
    return 'Tapos na ang plan mo. Gagana pa ang lahat hanggang $date.';
  }

  @override
  String get planStatusPaused =>
      'Naka-pause ang cloud backup. Nakatago sa phone na ito ang lahat ng itatala mo, at mag-a-upload agad pag nag-renew ka.';

  @override
  String get planStatusUnlimited =>
      'Walang bayad sa server na ito. Kasama na ang lahat.';

  @override
  String get planBasic => 'Basic';

  @override
  String get planPro => 'Pro';

  @override
  String get planBasicPoints =>
      'Backup at sync para sa isang tindahan, sa lahat ng phone mo';

  @override
  String get planProPoints =>
      'Hanggang 5 tindahan, staff accounts, at lahat ng nasa Basic';

  @override
  String planPerMonth(Object price) {
    return '$price kada buwan';
  }

  @override
  String planPerYear(Object price) {
    return '$price kada taon';
  }

  @override
  String get planMonthly => 'Buwanan';

  @override
  String get planYearly => 'Taunan, libre ang 2 buwan';

  @override
  String planPay(Object amount) {
    return 'Magbayad ng $amount gamit ang GCash o Maya';
  }

  @override
  String get planPayHint =>
      'Paunang bayad, parang pagbili ng load. Walang awtomatikong kaltas kailanman.';

  @override
  String get planFinishInBrowser =>
      'Tapusin ang pagbayad sa page na bumukas. Mag-a-update ang Kitaza pagbalik mo.';

  @override
  String get planCouldNotOpen =>
      'Hindi mabuksan ang page ng bayad. Subukan ulit.';

  @override
  String get planPaid => 'Salamat! Na-update na ang plan mo.';

  @override
  String get planCurrent => 'Kasalukuyan';

  @override
  String get planHistory => 'Mga bayad';

  @override
  String get planOneMonth => '1 buwan';

  @override
  String get planOneYear => '1 taon';

  @override
  String get planLeaveTitle => 'Gamitin ang Kitaza offline nang libre';

  @override
  String get planLeaveHint =>
      'Itago ang lahat sa phone na ito at itigil ang pag-sync. Mananatili sa cloud ang records mo roon.';

  @override
  String get planLeaveConfirmTitle => 'Gawing offline ang phone na ito?';

  @override
  String get planLeaveConfirmMessage =>
      'Itatago ng phone na ito ang lahat ng records at titigil ito sa pag-sync. Hindi na makikita ng ibang phone at staff mo ang maitatala rito. Puwede kang bumalik sa cloud kahit kailan.';

  @override
  String get planLeaveConfirm => 'Gamitin offline';

  @override
  String get planLeft => 'Offline na ang phone na ito. Walang nawala.';

  @override
  String get planPausedShort =>
      'Naka-pause ang cloud backup hanggang ma-renew ang plan. Nakatago sa phone ang entry na ito.';

  @override
  String get planUpgradeNeeded => 'Kailangan ng Kitaza Pro para rito.';

  @override
  String planBannerTrial(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Matatapos ang libreng trial mo sa loob ng $count araw.',
    );
    return '$_temp0';
  }

  @override
  String planBannerEnding(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Matatapos ang plan mo sa loob ng $count araw.',
    );
    return '$_temp0';
  }

  @override
  String planBannerGrace(Object date) {
    return 'Tapos na ang plan mo. Tuloy ang pag-sync hanggang $date.';
  }

  @override
  String get planBannerPaused =>
      'Naka-pause ang cloud backup. Nakatago sa phone na ito ang mga entry mo.';

  @override
  String get planBannerAction => 'Pumili ng plan';

  @override
  String get planBannerStaff =>
      'Pakiusapan ang may-ari na i-renew ang plan ng tindahan.';

  @override
  String get syncPaused => 'Naka-pause, nakatago sa phone';

  @override
  String activitySubscriptionPaid(Object name, Object amount, Object plan) {
    return 'Nagbayad si $name ng $amount para sa $plan';
  }

  @override
  String get insightsTitle => 'Mga mungkahi';

  @override
  String get insightsEarlyDays =>
      'Magtala lang ng benta nang mga dalawang linggo at makakapagmungkahi na ang Kitaza kung ano ang i-restock at aling presyo ang dapat tingnan.';

  @override
  String get insightsHowTitle => 'Paano ito kinukuwenta';

  @override
  String get insightsHowBody =>
      'Mula sa sarili mong records sa phone na ito: ang huling apat na linggong benta ng bawat produkto, hindi kasama ang mga araw na ubos ang stock. Walang binabago rito sa presyo at walang ino-order.';

  @override
  String get restockTitle => 'I-restock na';

  @override
  String restockOrder(Object quantity, Object unit) {
    return 'Mag-order ng $quantity $unit';
  }

  @override
  String restockReasonRate(Object quantity, Object unit, Object days) {
    return 'Mga $quantity $unit kada araw. May $days pa.';
  }

  @override
  String restockReasonEmpty(Object quantity, Object unit) {
    return 'Mga $quantity $unit kada araw, at wala nang natitira.';
  }

  @override
  String get restockReasonLevel =>
      'Mas mababa na sa reorder level na itinakda mo.';

  @override
  String restockDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count araw',
    );
    return '$_temp0';
  }

  @override
  String get priceTitle => 'Mga presyong dapat tingnan';

  @override
  String priceReasonBelowCost(Object cost) {
    return 'Mas mura pa sa $cost na puhunan mo.';
  }

  @override
  String priceReasonThin(Object percent) {
    return '$percent na lang ang natitira pagkatapos ng puhunan.';
  }

  @override
  String get priceReasonSlow =>
      'Halos hindi nabebenta. Perang nakatengga sa istante.';

  @override
  String priceTry(Object price) {
    return 'Subukan ang $price';
  }

  @override
  String priceExtraPerMonth(Object amount) {
    return 'Mga $amount pa kada buwan';
  }

  @override
  String get priceSlowAdvice =>
      'Mag-order ng mas kaunti sa susunod, o ibaba muna ang presyo.';

  @override
  String get patternTitle => 'Ang takbo ng tindahan mo';

  @override
  String patternPayday(Object percent) {
    return 'Mga $percent mas malaki ang pasok tuwing payday week kaysa sa ibang araw ng buwan.';
  }

  @override
  String patternNextPayday(Object date) {
    return 'Ang susunod na payday ay $date. Mag-stock bago ito.';
  }

  @override
  String patternBusiest(Object day, Object percent) {
    return 'Ang $day ang pinakamalakas mong araw, mga $percent mas mataas sa karaniwan.';
  }

  @override
  String get benchmarkTitle => 'Mga tindahang katulad mo';

  @override
  String benchmarkFrom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ang gitna ng $count tindahang kasinlaki mo.',
    );
    return '$_temp0';
  }

  @override
  String get benchmarkMargin => 'Kita sa bawat benta';

  @override
  String get benchmarkExpenses => 'Gastos kumpara sa benta';

  @override
  String get benchmarkDailySales => 'Benta kada araw';

  @override
  String benchmarkYours(Object value) {
    return 'Ikaw: $value';
  }

  @override
  String benchmarkTypical(Object value) {
    return 'Karaniwan: $value';
  }

  @override
  String get benchmarkNotEnough =>
      'Lalabas ang paghahambing kapag sapat na ang tindahang kasinlaki mo na nagbabahagi.';

  @override
  String get benchmarkNotSharing =>
      'Naka-off ang paghahambing habang hindi ka nagbabahagi ng sarili mong numero.';

  @override
  String get benchmarkSharingTitle => 'Magbahagi ng anonymous na paghahambing';

  @override
  String get benchmarkSharingHint =>
      'Sasama ang buwanang kabuuan mo sa gitnang numerong nakikita ng ibang may-ari. Hindi kasama ang pangalan mo, ang tindahan mo, o kahit isang benta, at hindi bababa sa 20 tindahan ang pinagsasamahan.';

  @override
  String get benchmarkSharingOff =>
      'Hindi nagbabahagi. Hindi mo rin makikita ang paghahambing.';

  @override
  String get settingsAbout => 'Tungkol dito';

  @override
  String aboutVersion(Object version) {
    return 'Kitaza $version';
  }

  @override
  String get aboutCopied => 'Nakopya ang bersyon';

  @override
  String get aboutUnreleasedBuild =>
      'Pansubok na build. Hindi kokonekta ang cloud.';

  @override
  String get settingsGuide => 'Matutong gamitin';

  @override
  String get guideTitle => 'Paano gamitin ang Kitaza';

  @override
  String get guideIntro =>
      'Walong maikling aralin. Sundan ang pagkakasunod-sunod sa unang basa, tapos balikan ang kahit alin kapag kailangan.';

  @override
  String guideProgress(int read, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      read,
      locale: localeName,
      other: '$read sa $total ang nabasa',
      zero: 'Hindi pa nasisimulan',
    );
    return '$_temp0';
  }

  @override
  String guideLessonProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hakbang',
    );
    return '$_temp0';
  }

  @override
  String guideStepLabel(int number) {
    return 'Hakbang $number';
  }

  @override
  String get guideOpenScreen => 'Buksan ito ngayon';

  @override
  String guideNextLesson(Object title) {
    return 'Susunod: $title';
  }

  @override
  String get guideAllDone => 'Iyan na ang buong gabay.';

  @override
  String get guideAllDoneBody =>
      'Walang pagsusulit dito. Balikan ang kahit anong aralin kapag kailangan mo.';

  @override
  String get guideBackToLessons => 'Balik sa mga aralin';

  @override
  String get guideRead => 'Nabasa na';

  @override
  String get guidePromptTitle => 'Bago sa Kitaza?';

  @override
  String get guidePromptBody =>
      'May maikling gabay na magtuturo kung paano mag-record ng benta, ang presyo mo, at paano basahin ang numero mo.';

  @override
  String get guidePromptOpen => 'Ituro mo';

  @override
  String get guidePromptDismiss => 'Mamaya na';

  @override
  String get guideFirstDayTitle => 'Ang unang araw mo';

  @override
  String get guideFirstDaySummary =>
      'Ang gagawin sa unang oras, at kung bakit gumagana ang app kahit walang signal.';

  @override
  String get guideFirstDayStep1Title => 'Gumagana kahit walang load';

  @override
  String get guideFirstDayStep1Body =>
      'Lahat ng ire-record mo ay naka-save muna sa telepono. Walang signal, walang data, walang problema. Kung cloud ang gamit mo, kusang ipapadala ito ng telepono pagbalik ng signal.';

  @override
  String get guideFirstDayStep2Title => 'Ilagay ang mga binebenta mo';

  @override
  String get guideFirstDayStep2Body =>
      'Hindi kailangang kumpleto agad sa unang araw. Simulan sa sampung pinakamabiling paninda. Dagdagan mo na lang habang tumatakbo ang araw.';

  @override
  String get guideFirstDayStep3Title => 'I-record lahat, kahit limang piso';

  @override
  String get guideFirstDayStep3Body =>
      'Pareho ang bigat ng isang sachet at ng isang kaha. Ang numerong ibabalik sa iyo ng Kitaza ay kasingtotoo lang ng inilagay mo, kaya ang maliliit ang pinakamahalaga.';

  @override
  String get guideFirstDayStep4Title => 'Tingnan ang araw bago magsara';

  @override
  String get guideFirstDayStep4Body =>
      'Buksan ang unang screen bago ka magsara. Nandoon kung magkano ang pumasok, magkano ang lumabas, at magkano ang talagang natira sa iyo.';

  @override
  String get guideRecordingSalesTitle => 'Pag-record ng benta';

  @override
  String get guideRecordingSalesSummary =>
      'Ito ang gagawin mo nang daan-daang beses sa isang araw. Tatlong pindot lang.';

  @override
  String get guideRecordingSalesStep1Title => 'Pindutin ang Magdagdag ng benta';

  @override
  String get guideRecordingSalesStep1Body =>
      'Ito ang malaking button sa itaas ng unang screen. Maaabot mo ito kahit saan ka gamit ang mga button sa ibaba.';

  @override
  String get guideRecordingSalesStep2Title => 'Pindutin ang binili nila';

  @override
  String get guideRecordingSalesStep2Body =>
      'Isang pindot, isang piraso. Pindutin ulit kung dalawa. Kung may barcode ang paninda, i-scan na lang sa halip na hanapin.';

  @override
  String get guideRecordingSalesStep3Title => 'Sabihin kung paano nagbayad';

  @override
  String get guideRecordingSalesStep3Body =>
      'Cash, GCash, o utang. Benta pa rin ang utang, at tinatandaan ito ng Kitaza bilang perang hindi pa naaabot sa iyo.';

  @override
  String get guideRecordingSalesStep4Title => 'I-save';

  @override
  String get guideRecordingSalesStep4Body =>
      'Ayun, tapos na. Nasa telepono na agad ang benta, at kusang bumababa ang bilang ng stock.';

  @override
  String get guideRecordingSalesStep5Title => 'Kung may namali ka';

  @override
  String get guideRecordingSalesStep5Body =>
      'Buksan ang Benta, hanapin ito, at i-void. Walang tahimik na binubura: mamarkahan itong void at babalik ang stock sa istante.';

  @override
  String get guideWhatYouSellTitle => 'Ang mga paninda mo';

  @override
  String get guideWhatYouSellSummary =>
      'Ang presyo, ang stock, at ang isang bagay na magdedesisyon kung masasabi sa iyo ng Kitaza ang tubo mo.';

  @override
  String get guideWhatYouSellStep1Title => 'Magdagdag ng paninda';

  @override
  String get guideWhatYouSellStep1Body =>
      'Pumunta sa Paninda at pindutin ang Magdagdag. Sapat na ang pangalan at presyo para makapagbenta ka na.';

  @override
  String get guideWhatYouSellStep2Title => 'Ilagay ang dalawang presyo';

  @override
  String get guideWhatYouSellStep2Body =>
      'Ang puhunan mo, at ang sinisingil mo. Kapag walang puhunan, mabibilang lang ng Kitaza ang benta mo - hindi nito masasabi kung magkano ang natira sa iyo.';

  @override
  String get guideWhatYouSellStep3Title => 'Bilangin ang nasa istante';

  @override
  String get guideWhatYouSellStep3Body =>
      'Ilagay kung ilan ang meron ka ngayon. Mula roon, kusang binabawasan ito ng Kitaza habang nagbebenta ka at dinadagdagan kapag may na-record kang delivery.';

  @override
  String get guideWhatYouSellStep4Title => 'Sabihin kung kailan mag-order ulit';

  @override
  String get guideWhatYouSellStep4Body =>
      'Itakda ang bilang na nangangahulugang paubos na - dalawa, lima, isang dosena. Sasabihin ito ng Kitaza bago maubos, hindi pagkatapos.';

  @override
  String get guideWhatYouSellStep5Title => 'Mag-scan sa halip na mag-type';

  @override
  String get guideWhatYouSellStep5Body =>
      'I-scan ang barcode minsan habang dinadagdag ang paninda, at mula noon ay agad na itong makikita kapag ni-scan mo sa counter.';

  @override
  String get guideMoneyGoingOutTitle => 'Perang lumalabas';

  @override
  String get guideMoneyGoingOutSummary =>
      'Pagpuhunan, pagbayad ng bayarin, at ang pagkakaiba ng dalawang klaseng perang lumalabas.';

  @override
  String get guideMoneyGoingOutStep1Title => 'I-record ang ginastos mo';

  @override
  String get guideMoneyGoingOutStep1Body =>
      'Pindutin ang Gastos at ilagay ang halaga. Hindi kailangan ang dahilan - huwag mo nang hayaang makapagpabagal ito sa counter.';

  @override
  String get guideMoneyGoingOutStep2Title => 'Gastos din ang pagpuhunan';

  @override
  String get guideMoneyGoingOutStep2Body =>
      'Ang punta sa palengke, ang delivery, ang load na binili mong ibebenta ulit. Kung may perang lumabas sa kahon, dito ito kabilang.';

  @override
  String get guideMoneyGoingOutStep3Title =>
      'Iba ang perang kinuha mo para sa sarili';

  @override
  String get guideMoneyGoingOutStep3Body =>
      'Gamitin ang Paglabas ng pera para doon, hindi ang Gastos. Kapag pinagsama mo, ang tindahang maayos naman ay magmumukhang lugi kada linggo.';

  @override
  String get guideMoneyGoingOutStep4Title => 'Gawin sa mismong araw';

  @override
  String get guideMoneyGoingOutStep4Body =>
      'Ang gastos na naalala makalipas ang tatlong araw ay kadalasang maling naaalala. Mas mabuti ang mabilisang tala ngayon kaysa sa tamang-tamang tala na hindi naman mangyayari.';

  @override
  String get guideReadingYourNumbersTitle => 'Pagbasa ng numero mo';

  @override
  String get guideReadingYourNumbersSummary =>
      'Ang sinasabi sa iyo ng unang screen, at ang pagkakaiba ng malakas na benta at ng kita.';

  @override
  String get guideReadingYourNumbersStep1Title => 'Piliin muna ang panahon';

  @override
  String get guideReadingYourNumbersStep1Body =>
      'Ngayon, ngayong linggo, ngayong buwan. Lahat ng numero sa screen ay para sa napili mong panahon, kaya tingnan ito bago ka mag-alala.';

  @override
  String get guideReadingYourNumbersStep2Title => 'Hindi tubo ang benta';

  @override
  String get guideReadingYourNumbersStep2Body =>
      'Ang benta ay ang dumaan sa kahon. Ang tubo ay ang natira matapos ang puhunan sa paninda. Ang maabalang araw na manipis ang presyo ay puwedeng mas maliit ang kita kaysa sa tahimik na araw.';

  @override
  String get guideReadingYourNumbersStep3Title => 'Ang may kulay na banda';

  @override
  String get guideReadingYourNumbersStep3Body =>
      'Berde: maayos ang linggo. Dilaw: may bantayan ka. Pula: may dapat asikasuhin ngayong araw. Laging may paliwanag sa ilalim kung bakit.';

  @override
  String get guideReadingYourNumbersStep4Title =>
      'Pindutin ang numero para makita kung saan galing';

  @override
  String get guideReadingYourNumbersStep4Body =>
      'Walang numero sa Kitaza na basta na lang dapat paniwalaan. Bawat kabuuan ay bubukas sa mga bentahan at gastos na bumuo nito.';

  @override
  String get guideWhatKitazaSuggestsTitle => 'Ang mungkahi ng Kitaza';

  @override
  String get guideWhatKitazaSuggestsSummary =>
      'Kailan mag-order ulit, presyong dapat tingnan, at ang sarili mong maabalang araw - galing lahat sa sarili mong tala.';

  @override
  String get guideWhatKitazaSuggestsStep1Title => 'Ano ang dapat i-order ulit';

  @override
  String get guideWhatKitazaSuggestsStep1Body =>
      'Kung gaano kabilis talaga nauubos ang bawat paninda, ilang araw pa ang aabutin ng istante, at ilan ang bibilhin. Hindi binibilang ang mga araw na wala kang stock, kaya hindi napagkakamalang mabagal ang mabilis na paninda.';

  @override
  String get guideWhatKitazaSuggestsStep2Title => 'Presyong dapat tingnan';

  @override
  String get guideWhatKitazaSuggestsStep2Body =>
      'Ang mga ibinebenta mo nang mas mura pa sa puhunan, ang manipis na tubo sa mabiling paninda, at ang stock na hindi gumagalaw. May mungkahing presyo ang bawat isa at kung magkano ang maidaragdag nito sa isang buwan.';

  @override
  String get guideWhatKitazaSuggestsStep3Title =>
      'Ang sarili mong maabalang araw';

  @override
  String get guideWhatKitazaSuggestsStep3Body =>
      'Ang linggo ng sahod at ang pinakamalakas mong araw sa isang linggo, sinukat mula sa kita mo - hindi hinulaan. Magkaiba ang ritmo ng tindahang katabi ng paaralan at ng katabi ng pabrika.';

  @override
  String get guideWhatKitazaSuggestsStep4Title => 'Tingnan ang pagkukuwenta';

  @override
  String get guideWhatKitazaSuggestsStep4Body =>
      'May Paano ito kinuwenta sa ilalim ng bawat card. Kung mali sa tingin mo ang mungkahi, buksan mo ito - mas kilala mo ang tindahan mo kaysa sa app.';

  @override
  String get guideKeepingRecordsSafeTitle => 'Pag-iingat ng tala mo';

  @override
  String get guideKeepingRecordsSafeSummary =>
      'Ang mangyayari kapag nawala ang telepono, at kung paano hindi masasama roon ang isang taong tala.';

  @override
  String get guideKeepingRecordsSafeStep1Title =>
      'Kusang nagbaback-up ang Kitaza';

  @override
  String get guideKeepingRecordsSafeStep1Body =>
      'May kopya ng tala mo na kusang nase-save sa telepono, kahit hindi mo hilingin. Sagot nito ang pagkakamali. Hindi nito sagot ang nawawalang telepono.';

  @override
  String get guideKeepingRecordsSafeStep2Title =>
      'Magtago ng kopya sa labas ng telepono';

  @override
  String get guideKeepingRecordsSafeStep2Body =>
      'Sa Settings, pindutin ang I-export at ipadala sa sarili mo ang file - Messenger, email, memory card. Sapat na ang minsan sa isang buwan. Ito ang hakbang na nilalaktawan at pinagsisisihan.';

  @override
  String get guideKeepingRecordsSafeStep3Title => 'Pagbawi ng tala mo';

  @override
  String get guideKeepingRecordsSafeStep3Body =>
      'Sa bagong telepono, i-install ang Kitaza at piliin ang Ibalik sa halip na gumawa ng bagong tindahan. Babalik ang paninda, benta at gastos mo gaya ng dati.';

  @override
  String get guideKeepingRecordsSafeStep4Title =>
      'O hayaang ang cloud ang magtago';

  @override
  String get guideKeepingRecordsSafeStep4Body =>
      'Sa cloud, nasa server namin at nasa telepono mo ang tala, kaya walang mawawala kapag nawala ang telepono. Kailangan nito ng signal paminsan-minsan, at buwanang bayad.';

  @override
  String get guideYourHelpersTitle => 'Ang mga katulong mo';

  @override
  String get guideYourHelpersSummary =>
      'Paano magpabantay ng counter nang hindi ibinibigay ang lahat.';

  @override
  String get guideYourHelpersStep1Title => 'Idagdag muna ang tao';

  @override
  String get guideYourHelpersStep1Body =>
      'Sa Settings, buksan ang Tauhan at idagdag siya sa pangalan. Bibigyan ka ng Kitaza ng maikling code na ita-type niya sa sarili niyang telepono.';

  @override
  String get guideYourHelpersStep2Title => 'Piliin kung ano ang makikita niya';

  @override
  String get guideYourHelpersStep2Body =>
      'Lahat ay puwedeng magbenta. Ikaw ang magdedesisyon kung puwede niyang palitan ang presyo, mag-record ng gastos, makita ang tubo mo, o mag-void ng benta.';

  @override
  String get guideYourHelpersStep3Title =>
      'Magkasundo ang telepono niya at ang sa iyo';

  @override
  String get guideYourHelpersStep3Body =>
      'Ang bentang narehistro sa counter ay lalabas sa telepono mo sa loob ng ilang segundo. Parehong gumagana ang dalawang telepono kapag nawala ang signal, at naghahabol pagkatapos.';

  @override
  String get guideYourHelpersStep4Title => 'Kapag may nawalang telepono';

  @override
  String get guideYourHelpersStep4Body =>
      'Buksan ang Mga naka-sign in na device at alisin ito. Hindi na agad makakakita o makakapagbago ang teleponong iyon.';

  @override
  String get legalOperator =>
      '[Rehistradong pangalan ng negosyo], [address], Pilipinas';

  @override
  String get legalContact =>
      'Mga tanong tungkol sa dokumentong ito, o sa tala mo: [privacy@kitaza.ph]. Sinasagot namin ito sa loob ng 15 araw ng trabaho, ayon sa inaasahan ng National Privacy Commission.';

  @override
  String legalVersion(Object version) {
    return 'Bersyon $version';
  }

  @override
  String get legalPrivacyTitle => 'Paunawa sa privacy';

  @override
  String get legalTermsTitle => 'Mga tuntunin ng paggamit';

  @override
  String get legalReadPrivacy => 'Paunawa sa privacy';

  @override
  String get legalReadTerms => 'Mga tuntunin ng paggamit';

  @override
  String get legalAgreeTitle => 'Bago ka magsimula';

  @override
  String legalAgree(Object privacy, Object terms) {
    return 'Nabasa ko at sumasang-ayon ako sa $privacy at sa $terms.';
  }

  @override
  String get legalAgreeRequired =>
      'Pakibasa at sang-ayunan ang dalawa bago magpatuloy.';

  @override
  String legalAgreedOn(Object date) {
    return 'Sinang-ayunan noong $date';
  }

  @override
  String get legalNeedsAgreement => 'Pakibasa at sang-ayunan';

  @override
  String get legalUpdatedTitle => 'May binago kami rito';

  @override
  String get legalUpdatedBody =>
      'Pakibasa ang nabago at sang-ayunan ulit. Walang maaapektuhan sa telepono mo habang nagdedesisyon ka.';

  @override
  String get legalAgreeButton => 'Sumasang-ayon ako';

  @override
  String get privacyWhoHeading => 'Sino ang may hawak ng tala mo';

  @override
  String privacyWhoBody(Object operator) {
    return 'Pinapatakbo ang Kitaza ng $operator. Sa ilalim ng Data Privacy Act of 2012 (Republic Act 10173), kami ang personal information controller para sa mga detalyeng ibinibigay mo tungkol sa sarili mo.\n\nMaaabot ang aming Data Protection Officer sa address na nasa dulo ng paunawang ito.';
  }

  @override
  String get privacyOfflineHeading =>
      'Kung offline ang gamit mo, wala kaming hawak';

  @override
  String get privacyOfflineBody =>
      'Ang offline na tindahan ay nasa telepono lang lahat. Ang paninda, benta, gastos at kita mo ay hindi umaabot sa amin, dahil walang pinapadalhan. Hindi namin ito maipapakita kahit may humingi.';

  @override
  String get privacyWhatHeading => 'Ang hawak namin kapag cloud ang gamit mo';

  @override
  String get privacyWhatBody =>
      'Ang pangalan mo, ang email mo, at ang ginulong anyo ng password mo na hindi na maibabalik sa dati.\n\nAng pangalan ng tindahan mo, ang uri nito, at ang pangalan ng mga tauhang idinagdag mo.\n\nAng tala ng negosyo mo: paninda at presyo, benta, gastos, paglabas ng pera at bilang ng stock.\n\nAng pangalan ng bawat teleponong naka-sign in, kailan huling ginamit, at tala kung sino ang gumawa ng ano sa tindahan mo.\n\nKung masira ang app, kung ano ang nasira at anong bersyon: ang error, kung saan sa code ito nangyari, at ang operating system ng telepono.';

  @override
  String get privacyNeverHeading => 'Ang hindi namin hawak kailanman';

  @override
  String get privacyNeverBody =>
      'Hindi namin itinatala ang mga suki mo. Ang benta ay halaga at ang mga binili; ang utang ay paraan ng pagbabayad. Walang pangalan, numero o address ng suki na hinihingi o iniimbak.\n\nHindi namin nakikita ang card number, GCash PIN o detalye ng bangko. Dumadaan ang bayad sa PayMongo na siyang humahawak nito; ang sinasabi lang sa amin ay may naipasang bayad at kung magkano.\n\nHindi namin sinusubaybayan ang kinaroroonan mo, hindi binabasa ang contacts mo, at wala kaming tinitingnan sa telepono mo. Ang camera ay ginagamit sa pag-scan ng barcode, at habang bukas lang ang scanner.';

  @override
  String get privacyWhyHeading => 'Bakit namin ito hawak';

  @override
  String get privacyWhyBody =>
      'Para patakbuhin ang serbisyong hiniling mo: itago ang tala mo, ipakita ito sa iba mong telepono, at magamit ng tauhan mo ang tindahan.\n\nPara maningil para sa planong pinili mo, at panatilihin ang talang pinansyal na kailangang itago ng isang negosyo.\n\nPara ayusin ang nasisira. Ang error report ay nagsasabing may bumabagsak na build; walang dalang numero ng negosyo.\n\nKung papayag ka, para kuwentahin ang gitnang numero na ipinapaghambing sa tindahan mo at sa iba. Puwede mo itong patayin sa Settings, at kapag pinatay mo, hindi mo rin makikita ang sa iba.';

  @override
  String get privacySharedHeading => 'Sino pa ang nakakakita nito';

  @override
  String get privacySharedBody =>
      'Ang PayMongo Philippines, para sa bayad. Nakikita nila kung para saan ang bayad at sino ang nagbabayad, sa ilalim ng sarili nilang privacy policy.\n\nAng kompanyang nagho-host ng server namin, na nag-iimbak ng data para sa amin at hindi puwedeng gamitin ito sa iba.\n\nWala nang iba. Hindi namin ibinebenta ang tala mo at hindi namin ibinibigay sa advertiser. Ibibigay lang namin ito sa gobyerno kung may batas o utos ng korte na nag-uutos, at sasabihin namin sa iyo maliban kung ipinagbabawal kaming magsabi.\n\nAng paghahambing ng tindahan ay inilalabas bilang gitnang numero lamang, sa hindi bababa sa dalawampung tindahang magkatulad ang uri at laki. Walang pangalan ng tindahan at walang kahit isang benta.';

  @override
  String get privacyKeepHeading => 'Gaano katagal namin ito itinatago';

  @override
  String get privacyKeepBody =>
      'Ang tala ng negosyo mo, habang bukas ang account mo.\n\nKung sino ang gumawa ng ano sa tindahan: dalawang taon.\n\nError report: siyamnapung araw.\n\nTeleponong na-sign out mo: isang taon.\n\nKapag isinara mo ang account, buburahin namin ang lahat pagkalipas ng tatlumpung araw, at ang tatlumpung araw ay para lang may maibalik kung namali ka ng pindot. Ang matitira ay ang halaga at petsa ng bayad na natanggap namin, na walang kahit anong nakakabit sa iyo, dahil kailangang makapagsulit ang negosyo sa perang natanggap nito.';

  @override
  String get privacyRightsHeading => 'Ang mga karapatan mo';

  @override
  String get privacyRightsBody =>
      'Binibigyan ka ng Data Privacy Act ng karapatan sa hawak namin, at ginagawa ng app ang halos lahat nito nang hindi ka na hihingi ng pabor kanino man.\n\nMalaman kung ano ang hawak namin at bakit: ito ang paunawang ito, at makikita rin sa Settings.\n\nKumuha ng kopya: Settings, I-download ang tala ko. Ordinaryong file ito na puwede mong buksan at itago.\n\nItama ang mali: palitan sa app, o sumulat sa amin.\n\nIpabura ito: Settings, Isara ang account ko. Pagkalipas ng tatlumpung araw, wala na ito at hindi na maibabalik.\n\nTumutol, at bawiin ang pahintulot na ibinigay mo. Isa rito ang pagpatay sa paghahambing.\n\nMabayaran sa pinsalang dulot kung namalpakan namin ang tala mo, at magreklamo sa National Privacy Commission sa privacy.gov.ph. Hindi mo kailangang lumapit muna sa amin, bagaman mas gusto namin kung gagawin mo.';

  @override
  String get privacySafetyHeading =>
      'Pag-iingat nito, at pagsasabi kapag nabigo kami';

  @override
  String get privacySafetyBody =>
      'Ginugulo ang password bago itago at hindi na ito mababasa pabalik, kahit namin. Naka-encrypt ang daloy sa pagitan ng telepono mo at ng server namin. Ang teleponong ni-sign out mo ay agad na tumitigil.\n\nKung malantad ang tala mo at may tunay itong panganib sa iyo, sasabihin namin sa National Privacy Commission sa loob ng pitumpu\'t dalawang oras mula nang malaman namin, at sasabihin namin sa iyo: kung ano ang nangyari, ano ang kasama, at ano ang dapat gawin.';

  @override
  String get privacyChangesHeading => 'Pagbabago sa paunawang ito';

  @override
  String get privacyChangesBody =>
      'Kapag nagbago ang paunawang ito sa paraang mahalaga, hihilingin ng app na basahin mo ito at sang-ayunan ulit, at itatala ang bersyong sinang-ayunan mo.\n\nHindi katumbas ng pagsang-ayon ang basta paggamit ng app. Tatanungin ka namin nang maliwanag.';

  @override
  String get termsWhatHeading => 'Ano ang Kitaza';

  @override
  String termsWhatBody(Object operator) {
    return 'Ang Kitaza ay talaan para sa maliit na tindahan. Itinatala nito ang binebenta at ginagastos mo, binibilang ang stock, at kinukuwenta ang numero mula sa inilagay mo.\n\nAng kasunduan ay sa pagitan mo at ng $operator.';
  }

  @override
  String get termsNotHeading => 'Ano ang hindi Kitaza';

  @override
  String get termsNotBody =>
      'Hindi ito accountant, at hindi ito pang-file sa BIR. Ang numero nito ay hindi tax return at hindi na-audit na libro.\n\nAng mungkahi nito - kung ano ang i-order ulit, magkano ang isingil - ay kuwenta sa sarili mong tala, na may kasamang pagkukuwenta. Timbangin mo ito, huwag sundin nang basta. Kilala mo ang tindahan mo; hindi ito kilala ng app.\n\nKung may kailangan kang payo tungkol sa buwis, permit o batas, magtanong sa taong may karapatang magbigay nito.';

  @override
  String get termsAccountHeading => 'Ang account mo';

  @override
  String get termsAccountBody =>
      'Kailangang sapat na ang edad mo para pumasok sa kontrata, at totoo ang mga detalyeng ibibigay mo.\n\nItago mo ang password mo. Anumang gawin ng teleponong naka-sign in sa account mo ay ituturing na ikaw ang gumawa, kaya i-sign out ang teleponong wala na sa iyo.\n\nAng tauhang idinagdag mo ay kumikilos para sa iyo. Ikaw ang nagdedesisyon kung ano ang makikita at magagawa ng bawat isa, at ikaw ang may pananagutan sa ginagawa nila sa tindahan mo.';

  @override
  String get termsPayHeading => 'Ang babayaran mo';

  @override
  String get termsPayBody =>
      'Libre ang unang tatlumpung araw at walang hinihinging detalye ng bayad.\n\nPagkatapos nito, bayad muna ang plano - isang buwan o isang taon sa bawat bayad - sa presyong nakikita sa app habang nagbabayad ka. Walang kusang nagre-renew at walang kusang sinisingil. Kapag naubos ang panahon, may pito pang araw ka, at pagkatapos ay titigil ang pag-sync hanggang magbayad ka ulit.\n\nHindi ipinapangalandakan ang tala mo. Ang hindi bayad na account ay nababasa pa rin sa telepono, at nae-export pa rin ang tala nito.\n\nPuwedeng magbago ang presyo, pero hindi para sa panahong nabayaran mo na.';

  @override
  String get termsRefundHeading => 'Refund';

  @override
  String get termsRefundBody =>
      'Kung hindi ginagawa ng serbisyo ang sinasabi ng pahinang ito, sabihin mo sa amin sa loob ng tatlumpung araw mula nang magbayad ka at ibabalik namin nang buo ang bayad na iyon.\n\nHindi namin ibinabalik ang panahong hindi mo lang ginamit. Walang kusang nagre-renew, kaya ang hindi nagamit na panahon ay pinili, hindi aksidente.\n\nKatabi ito ng karapatan mo sa ilalim ng Consumer Act of the Philippines (Republic Act 7394); walang inaalis dito sa mga iyon.';

  @override
  String get termsYoursHeading => 'Sa iyo ang tala mo';

  @override
  String get termsYoursBody =>
      'Ang inilagay mo ay nananatiling sa iyo. Wala kaming inaangkin dito, at hawak namin ito para patakbuhin ang serbisyo para sa iyo at wala nang iba.\n\nPuwede kang kumuha ng kopya kahit kailan, at puwede mong isara ang account at ipabura ito. Sinasabi ng Paunawa sa privacy kung ano mismo ang mangyayari.';

  @override
  String get termsFairHeading => 'Makatarungang paggamit';

  @override
  String get termsFairBody =>
      'Huwag gamitin ang Kitaza para labagin ang batas, para itala ang negosyo ng iba nang walang pahintulot nila, o para atakihin ang serbisyo o pasukin ang account na hindi sa iyo.\n\nMaaari naming suspindihin ang account na gumagawa nito, at sasabihin namin kung bakit.';

  @override
  String get termsLimitsHeading =>
      'Ang ipinapangako at hindi namin ipinapangako';

  @override
  String get termsLimitsBody =>
      'Mag-iingat kami nang makatuwiran para tumakbo ang serbisyo at ligtas ang tala mo. Hindi namin maipapangakong hindi ito bababa kailanman, at hindi namin maipapangakong hindi mawawala o masisira ang telepono - kaya nga kusang nagbaback-up ang app at hinihiling nitong magtago ka ng kopya sa labas ng telepono.\n\nKung saan pinapayagan ng batas ang hangganan, ang sa amin ay ang halagang nabayaran mo sa amin sa nakaraang labindalawang buwan bago ang problema. Walang dito ang naglilimita sa pananagutan sa pandaraya, sa kamatayan o pinsalang dulot ng kapabayaan, o sa anumang sinasabi ng batas na hindi puwedeng limitahan.';

  @override
  String get termsEndingHeading => 'Pagtatapos nito';

  @override
  String get termsEndingBody =>
      'Puwede mong isara ang account mo kahit kailan, mula sa Settings.\n\nTatapusin lang namin ang kasunduan kung may malubha o paulit-ulit na paglabag sa mga tuntuning ito, at bibigyan ka namin ng abiso at panahon para kumuha muna ng kopya ng tala mo.';

  @override
  String get termsLawHeading => 'Aling batas ang sinusunod';

  @override
  String get termsLawBody =>
      'Ang batas ng Republika ng Pilipinas. Ang di-pagkakaunawaang hindi maaayos sa pagitan natin ay dadalhin sa hukuman ng lugar kung saan nakarehistro ang negosyo namin.\n\nKung may bahagi ng pahinang ito na lumabas na hindi maipapatupad, mananatili pa rin ang iba.';

  @override
  String get settingsPrivacy => 'Datos at privacy mo';

  @override
  String get privacyCardTitle => 'Datos at privacy mo';

  @override
  String get privacyCardSubtitle =>
      'Ano ang hawak, paano kumuha ng kopya, at paano isara ang account';

  @override
  String get privacyScreenTitle => 'Datos at privacy mo';

  @override
  String get privacyWhereTitle => 'Nasaan ang tala mo';

  @override
  String get privacyWhereLocal =>
      'Sa teleponong ito lang. Walang tungkol sa tindahan mo ang naipadala sa amin kailanman, at wala ring maipapadala.';

  @override
  String get privacyWhereCloud =>
      'Sa teleponong ito at sa server namin, para makita ito ng iba mong telepono at ng tauhan mo.';

  @override
  String get privacyDocumentsTitle => 'Ang sinang-ayunan mo';

  @override
  String get privacyDownloadTitle => 'I-download ang tala ko';

  @override
  String get privacyDownloadLocal =>
      'Lahat ng nasa teleponong ito, bilang file na puwede mong itago o buksan sa iba.';

  @override
  String get privacyDownloadCloud =>
      'Lahat ng hawak namin tungkol sa iyo, bilang file na puwede mong itago o buksan sa iba.';

  @override
  String get privacyDownloadWorking => 'Tinitipon ang tala mo…';

  @override
  String get privacyDownloadFailed =>
      'Hindi natipon ang tala mo. Subukan ulit.';

  @override
  String get privacyCloseTitle => 'Isara ang account ko';

  @override
  String get privacyCloseSubtitle =>
      'Burahin ang lahat ng hawak namin tungkol sa iyo';

  @override
  String get privacyCloseScreenTitle => 'Isara ang account ko';

  @override
  String get privacyCloseExplain =>
      'Buburahin sa server namin ang account mo, ang mga tindahan mo, at bawat benta, gastos at paninda sa mga ito.';

  @override
  String privacyCloseGrace(int days) {
    return 'Walang bubura sa loob ng $days araw. Hanggang doon, puwede kang magbago ng isip, at tuloy ang lahat gaya ng dati.';
  }

  @override
  String get privacyCloseKeeps =>
      'Ang itatago namin: ang halaga at petsa ng mga bayad mo, na walang nakakabit tungkol sa iyo. Kailangang makapagsulit ang negosyo sa perang natanggap nito.';

  @override
  String get privacyClosePhone =>
      'Hindi gagalawin ang tala sa teleponong ito. Kumuha muna ng kopya kung gusto mong itago.';

  @override
  String get privacyCloseConfirmLabel =>
      'I-type ang pangalan ng tindahan mo para kumpirmahin';

  @override
  String get privacyCloseConfirmWrong =>
      'Hindi ito tugma sa pangalan ng tindahan mo.';

  @override
  String get privacyCloseSubmit => 'Isara ang account ko';

  @override
  String privacyCloseScheduled(Object date) {
    return 'Buburahin ang account mo sa $date.';
  }

  @override
  String get privacyCloseCancel => 'Panatilihin ang account ko';

  @override
  String get privacyCloseCancelled => 'Mananatiling bukas ang account mo.';

  @override
  String get privacyCloseFailed =>
      'Hindi ito nagawa. Subukan ulit kapag may signal.';

  @override
  String get privacyLocalOnlyTitle => 'Walang isasara';

  @override
  String get privacyLocalOnlyBody =>
      'Nasa telepono mo lang ang tindahang ito. Para alisin ito, i-delete ang app - pero kumuha muna ng kopya ng tala mo.';

  @override
  String get privacyNpcTitle => 'Kung magkamali kami';

  @override
  String get privacyNpcBody =>
      'Puwede kang magreklamo sa National Privacy Commission sa privacy.gov.ph. Hindi mo kailangang lumapit muna sa amin.';
}
