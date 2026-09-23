/// A document an owner agrees to, and the version they agreed to.
///
/// The version travels with the agreement because agreeing to one version
/// says nothing about a later one. Raising a version here asks every owner to
/// read what changed and agree again, which is the point of having it.
enum LegalDocument {
  privacyNotice('privacy_notice', '2026-09-01'),
  terms('terms', '2026-09-01');

  const LegalDocument(this.wireName, this.currentVersion);

  /// What the server calls it.
  final String wireName;

  /// The version in force in this build. It must match the server's, or
  /// registration is refused - deliberately, so an app showing an out-of-date
  /// notice cannot collect consent for it.
  final String currentVersion;

  static LegalDocument? parse(String raw) {
    for (final document in values) {
      if (document.wireName == raw) return document;
    }
    return null;
  }
}

/// One section of a document: a heading and the paragraphs under it.
class LegalSection {
  const LegalSection({required this.heading, required this.paragraphs});

  final String heading;
  final List<String> paragraphs;
}
