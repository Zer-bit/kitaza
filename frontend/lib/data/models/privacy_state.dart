import 'legal_document.dart';

/// One agreement on record.
class ConsentGiven {
  const ConsentGiven({
    required this.document,
    required this.version,
    required this.agreedAt,
  });

  final LegalDocument document;
  final String version;
  final DateTime agreedAt;
}

/// A deletion the owner asked for, and the day it stops being reversible.
class PendingDeletion {
  const PendingDeletion({required this.requestedAt, required this.deletesAt});

  final DateTime requestedAt;
  final DateTime deletesAt;

  factory PendingDeletion.fromJson(Map<String, dynamic> json) =>
      PendingDeletion(
        requestedAt: DateTime.parse(json['requested_at'] as String),
        deletesAt: DateTime.parse(json['deletes_at'] as String),
      );
}

/// What the server says about this account's consent and deletion.
class PrivacyState {
  const PrivacyState({
    this.agreed = const [],
    this.outstanding = const [],
    this.deletion,
  });

  final List<ConsentGiven> agreed;

  /// Documents whose current version has not been agreed to. Non-empty after
  /// a notice changes, which is when the app asks again.
  final List<LegalDocument> outstanding;

  final PendingDeletion? deletion;

  bool get isClosing => deletion != null;

  factory PrivacyState.fromJson(Map<String, dynamic> json) => PrivacyState(
    agreed: [
      for (final row in (json['agreed'] as List? ?? const []))
        if (LegalDocument.parse((row as Map)['document'] as String)
            case final document?)
          ConsentGiven(
            document: document,
            version: row['version'] as String,
            agreedAt: DateTime.parse(row['agreed_at'] as String),
          ),
    ],
    outstanding: [
      for (final row in (json['outstanding'] as List? ?? const []))
        ?LegalDocument.parse((row as Map)['document'] as String),
    ],
    deletion: json['deletion'] == null
        ? null
        : PendingDeletion.fromJson(json['deletion'] as Map<String, dynamic>),
  );

  ConsentGiven? agreementFor(LegalDocument document) {
    for (final given in agreed) {
      if (given.document == document) return given;
    }
    return null;
  }
}
