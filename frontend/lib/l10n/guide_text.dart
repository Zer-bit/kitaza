import '../data/models/guide_lesson.dart';
import 'generated/app_localizations.dart';

/// The wording of every lesson, kept out of the widgets so the guide's
/// structure and its text can be read separately.
extension GuideText on AppLocalizations {
  String guideLessonTitle(GuideLesson lesson) => switch (lesson) {
    GuideLesson.firstDay => guideFirstDayTitle,
    GuideLesson.recordingSales => guideRecordingSalesTitle,
    GuideLesson.whatYouSell => guideWhatYouSellTitle,
    GuideLesson.moneyGoingOut => guideMoneyGoingOutTitle,
    GuideLesson.readingYourNumbers => guideReadingYourNumbersTitle,
    GuideLesson.whatKitazaSuggests => guideWhatKitazaSuggestsTitle,
    GuideLesson.keepingRecordsSafe => guideKeepingRecordsSafeTitle,
    GuideLesson.yourHelpers => guideYourHelpersTitle,
  };

  String guideLessonSummary(GuideLesson lesson) => switch (lesson) {
    GuideLesson.firstDay => guideFirstDaySummary,
    GuideLesson.recordingSales => guideRecordingSalesSummary,
    GuideLesson.whatYouSell => guideWhatYouSellSummary,
    GuideLesson.moneyGoingOut => guideMoneyGoingOutSummary,
    GuideLesson.readingYourNumbers => guideReadingYourNumbersSummary,
    GuideLesson.whatKitazaSuggests => guideWhatKitazaSuggestsSummary,
    GuideLesson.keepingRecordsSafe => guideKeepingRecordsSafeSummary,
    GuideLesson.yourHelpers => guideYourHelpersSummary,
  };

  List<GuideStep> guideSteps(GuideLesson lesson) => switch (lesson) {
    GuideLesson.firstDay => [
      GuideStep(title: guideFirstDayStep1Title, body: guideFirstDayStep1Body),
      GuideStep(title: guideFirstDayStep2Title, body: guideFirstDayStep2Body),
      GuideStep(title: guideFirstDayStep3Title, body: guideFirstDayStep3Body),
      GuideStep(title: guideFirstDayStep4Title, body: guideFirstDayStep4Body),
    ],
    GuideLesson.recordingSales => [
      GuideStep(
        title: guideRecordingSalesStep1Title,
        body: guideRecordingSalesStep1Body,
      ),
      GuideStep(
        title: guideRecordingSalesStep2Title,
        body: guideRecordingSalesStep2Body,
      ),
      GuideStep(
        title: guideRecordingSalesStep3Title,
        body: guideRecordingSalesStep3Body,
      ),
      GuideStep(
        title: guideRecordingSalesStep4Title,
        body: guideRecordingSalesStep4Body,
      ),
      GuideStep(
        title: guideRecordingSalesStep5Title,
        body: guideRecordingSalesStep5Body,
      ),
    ],
    GuideLesson.whatYouSell => [
      GuideStep(
        title: guideWhatYouSellStep1Title,
        body: guideWhatYouSellStep1Body,
      ),
      GuideStep(
        title: guideWhatYouSellStep2Title,
        body: guideWhatYouSellStep2Body,
      ),
      GuideStep(
        title: guideWhatYouSellStep3Title,
        body: guideWhatYouSellStep3Body,
      ),
      GuideStep(
        title: guideWhatYouSellStep4Title,
        body: guideWhatYouSellStep4Body,
      ),
      GuideStep(
        title: guideWhatYouSellStep5Title,
        body: guideWhatYouSellStep5Body,
      ),
    ],
    GuideLesson.moneyGoingOut => [
      GuideStep(
        title: guideMoneyGoingOutStep1Title,
        body: guideMoneyGoingOutStep1Body,
      ),
      GuideStep(
        title: guideMoneyGoingOutStep2Title,
        body: guideMoneyGoingOutStep2Body,
      ),
      GuideStep(
        title: guideMoneyGoingOutStep3Title,
        body: guideMoneyGoingOutStep3Body,
      ),
      GuideStep(
        title: guideMoneyGoingOutStep4Title,
        body: guideMoneyGoingOutStep4Body,
      ),
    ],
    GuideLesson.readingYourNumbers => [
      GuideStep(
        title: guideReadingYourNumbersStep1Title,
        body: guideReadingYourNumbersStep1Body,
      ),
      GuideStep(
        title: guideReadingYourNumbersStep2Title,
        body: guideReadingYourNumbersStep2Body,
      ),
      GuideStep(
        title: guideReadingYourNumbersStep3Title,
        body: guideReadingYourNumbersStep3Body,
      ),
      GuideStep(
        title: guideReadingYourNumbersStep4Title,
        body: guideReadingYourNumbersStep4Body,
      ),
    ],
    GuideLesson.whatKitazaSuggests => [
      GuideStep(
        title: guideWhatKitazaSuggestsStep1Title,
        body: guideWhatKitazaSuggestsStep1Body,
      ),
      GuideStep(
        title: guideWhatKitazaSuggestsStep2Title,
        body: guideWhatKitazaSuggestsStep2Body,
      ),
      GuideStep(
        title: guideWhatKitazaSuggestsStep3Title,
        body: guideWhatKitazaSuggestsStep3Body,
      ),
      GuideStep(
        title: guideWhatKitazaSuggestsStep4Title,
        body: guideWhatKitazaSuggestsStep4Body,
      ),
    ],
    GuideLesson.keepingRecordsSafe => [
      GuideStep(
        title: guideKeepingRecordsSafeStep1Title,
        body: guideKeepingRecordsSafeStep1Body,
      ),
      GuideStep(
        title: guideKeepingRecordsSafeStep2Title,
        body: guideKeepingRecordsSafeStep2Body,
      ),
      GuideStep(
        title: guideKeepingRecordsSafeStep3Title,
        body: guideKeepingRecordsSafeStep3Body,
      ),
      GuideStep(
        title: guideKeepingRecordsSafeStep4Title,
        body: guideKeepingRecordsSafeStep4Body,
      ),
    ],
    GuideLesson.yourHelpers => [
      GuideStep(
        title: guideYourHelpersStep1Title,
        body: guideYourHelpersStep1Body,
      ),
      GuideStep(
        title: guideYourHelpersStep2Title,
        body: guideYourHelpersStep2Body,
      ),
      GuideStep(
        title: guideYourHelpersStep3Title,
        body: guideYourHelpersStep3Body,
      ),
      GuideStep(
        title: guideYourHelpersStep4Title,
        body: guideYourHelpersStep4Body,
      ),
    ],
  };
}
