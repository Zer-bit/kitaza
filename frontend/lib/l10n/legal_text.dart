import '../data/models/legal_document.dart';
import 'generated/app_localizations.dart';

/// The privacy notice and the terms, assembled from the translations.
///
/// A body holds its paragraphs separated by a blank line, which keeps a
/// section to two strings instead of one per paragraph - easier to translate,
/// and much easier to check that both languages say the same thing.
extension LegalText on AppLocalizations {
  String legalTitle(LegalDocument document) => switch (document) {
    LegalDocument.privacyNotice => legalPrivacyTitle,
    LegalDocument.terms => legalTermsTitle,
  };

  List<LegalSection> legalSections(LegalDocument document) =>
      switch (document) {
        LegalDocument.privacyNotice => [
          _section(privacyWhoHeading, privacyWhoBody(legalOperator)),
          _section(privacyOfflineHeading, privacyOfflineBody),
          _section(privacyWhatHeading, privacyWhatBody),
          _section(privacyNeverHeading, privacyNeverBody),
          _section(privacyWhyHeading, privacyWhyBody),
          _section(privacySharedHeading, privacySharedBody),
          _section(privacyKeepHeading, privacyKeepBody),
          _section(privacyRightsHeading, privacyRightsBody),
          _section(privacySafetyHeading, privacySafetyBody),
          _section(privacyChangesHeading, privacyChangesBody),
        ],
        LegalDocument.terms => [
          _section(termsWhatHeading, termsWhatBody(legalOperator)),
          _section(termsNotHeading, termsNotBody),
          _section(termsAccountHeading, termsAccountBody),
          _section(termsPayHeading, termsPayBody),
          _section(termsRefundHeading, termsRefundBody),
          _section(termsYoursHeading, termsYoursBody),
          _section(termsFairHeading, termsFairBody),
          _section(termsLimitsHeading, termsLimitsBody),
          _section(termsEndingHeading, termsEndingBody),
          _section(termsLawHeading, termsLawBody),
        ],
      };

  String legalReadLabel(LegalDocument document) => switch (document) {
    LegalDocument.privacyNotice => legalReadPrivacy,
    LegalDocument.terms => legalReadTerms,
  };
}

LegalSection _section(String heading, String body) => LegalSection(
  heading: heading,
  paragraphs: body
      .split('\n\n')
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList(growable: false),
);
