import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/legal_document.dart';
import '../models/privacy_state.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

/// The rights the Data Privacy Act gives an owner, as endpoints.
class PrivacyApi {
  const PrivacyApi(this._client);

  final ApiClient _client;

  Future<PrivacyState> state() async =>
      PrivacyState.fromJson(await _client.get(ApiEndpoints.accountPrivacy));

  Future<void> agree(LegalDocument document) => _client.post(
    ApiEndpoints.accountConsent,
    body: {'document': document.wireName, 'version': document.currentVersion},
  );

  /// Everything the server holds about this account.
  Future<Map<String, dynamic>> export() =>
      _client.get(ApiEndpoints.accountExport);

  Future<PendingDeletion> requestDeletion() async => PendingDeletion.fromJson(
    await _client.post(ApiEndpoints.accountDeletion),
  );

  Future<void> cancelDeletion() => _client.delete(ApiEndpoints.accountDeletion);
}

final privacyApiProvider = Provider<PrivacyApi>(
  (ref) => PrivacyApi(ref.watch(apiClientProvider)),
);
