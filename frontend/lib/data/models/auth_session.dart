import '../../core/config/storage_mode.dart';
import 'owner_account.dart';
import 'store_profile.dart';

/// The signed-in state of this device. `mode` decides whether anything is ever
/// sent over the network.
class AuthSession {
  const AuthSession({
    required this.owner,
    required this.store,
    required this.mode,
    this.accessToken,
    this.refreshToken,
  });

  final OwnerAccount owner;
  final StoreProfile store;
  final StorageMode mode;
  final String? accessToken;
  final String? refreshToken;

  bool get isCloud => mode.isCloud;

  factory AuthSession.fromJson(
    Map<String, dynamic> json, {
    required StorageMode mode,
  }) {
    final stores = (json['stores'] as List?) ?? const [];

    return AuthSession(
      owner: OwnerAccount.fromJson(json['owner'] as Map<String, dynamic>),
      store: stores.isEmpty
          ? const StoreProfile(id: '', name: 'My store')
          : StoreProfile.fromJson(stores.first as Map<String, dynamic>),
      mode: mode,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
    );
  }

  AuthSession copyWith({String? accessToken, StoreProfile? store}) =>
      AuthSession(
        owner: owner,
        store: store ?? this.store,
        mode: mode,
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken,
      );
}
