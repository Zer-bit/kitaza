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
}
