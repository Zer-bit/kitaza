import 'package:kitaza_app/data/models/legal_document.dart';
import 'package:kitaza_app/data/models/privacy_state.dart';
import 'package:kitaza_app/data/remote/privacy_api.dart';

/// Stands in for the server's privacy endpoints.
class FakePrivacyApi implements PrivacyApi {
  PrivacyState reported = const PrivacyState();
  final List<LegalDocument> agreedTo = [];
  Map<String, dynamic> exported = const {'account': {}};
  int deletionRequests = 0;
  int cancellations = 0;

  @override
  Future<PrivacyState> state() async => reported;

  @override
  Future<void> agree(LegalDocument document) async => agreedTo.add(document);

  @override
  Future<Map<String, dynamic>> export() async => exported;

  @override
  Future<PendingDeletion> requestDeletion() async {
    deletionRequests++;
    final pending = PendingDeletion(
      requestedAt: DateTime.now(),
      deletesAt: DateTime.now().add(const Duration(days: 30)),
    );
    reported = PrivacyState(agreed: reported.agreed, deletion: pending);
    return pending;
  }

  @override
  Future<void> cancelDeletion() async {
    cancellations++;
    reported = PrivacyState(agreed: reported.agreed);
  }
}
