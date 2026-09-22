import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/billing_overview.dart';
import '../models/subscription.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class BillingApi {
  const BillingApi(this._client);

  final ApiClient _client;

  Future<BillingOverview> overview() async =>
      BillingOverview.fromJson(await _client.get(ApiEndpoints.billing));

  /// Opens a checkout and returns where to pay.
  Future<Uri> checkout(PlanTier plan, int months) async {
    final body = await _client.post(
      ApiEndpoints.billingCheckout,
      body: {'plan': plan.name, 'months': months},
    );
    return Uri.parse(body['checkout_url'] as String);
  }
}

final billingApiProvider = Provider<BillingApi>(
  (ref) => BillingApi(ref.watch(apiClientProvider)),
);
