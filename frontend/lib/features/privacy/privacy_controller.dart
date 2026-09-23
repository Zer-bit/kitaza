import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/privacy_state.dart';
import '../../data/remote/privacy_api.dart';
import '../authentication/auth_controller.dart';

/// What the server says about this account's agreements and any deletion it
/// has been asked for.
///
/// Null for an offline store: there is no account on a server to describe,
/// which is itself the answer that screen shows.
final privacyStateProvider = FutureProvider<PrivacyState?>((ref) async {
  if (!ref.watch(isCloudModeProvider)) return null;
  return ref.watch(privacyApiProvider).state();
});
