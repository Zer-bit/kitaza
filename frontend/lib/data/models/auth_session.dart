import '../../core/config/storage_mode.dart';
import 'access_grant.dart';
import 'owner_account.dart';
import 'store_profile.dart';
import 'subscription.dart';

/// The signed-in state of this device. `mode` decides whether anything is ever
/// sent over the network.
class AuthSession {
  AuthSession({
    required this.owner,
    required this.store,
    required this.mode,
    AccessGrant? access,
    List<StoreProfile>? stores,
    this.accessToken,
    this.refreshToken,
    this.ended = false,
    this.subscription = const Subscription.unlimited(),
  }) : access = access ?? AccessGrant.owner(owner.fullName),
       stores = stores ?? [store];

  final OwnerAccount owner;

  /// The store this phone is working in right now.
  final StoreProfile store;

  /// Every store this person may switch to. Staff have exactly one.
  final List<StoreProfile> stores;
  final StorageMode mode;
  final AccessGrant access;
  final String? accessToken;
  final String? refreshToken;

  /// The server signed this phone out - revoked from another device, or a
  /// staff member removed. Its records stay until someone signs back in or
  /// chooses to clear them, because unsent sales may be among them.
  final bool ended;

  /// The owner's plan, which covers their staff too. Unlimited offline.
  final Subscription subscription;

  bool get isCloud => mode.isCloud;

  /// A session as the server describes it. [preferredStoreId] is opened if
  /// this person may still use it, otherwise their first store.
  factory AuthSession.fromJson(
    Map<String, dynamic> json, {
    required StorageMode mode,
    String? preferredStoreId,
  }) {
    final stores = [
      for (final raw in (json['stores'] as List?) ?? const [])
        StoreProfile.fromJson(raw as Map<String, dynamic>),
    ];
    final owner = OwnerAccount.fromJson(json['owner'] as Map<String, dynamic>);
    final access = json['access'] is Map<String, dynamic>
        ? AccessGrant.fromJson(json['access'] as Map<String, dynamic>)
        : AccessGrant.owner(owner.fullName);

    return AuthSession(
      owner: owner,
      store: pickStore(stores, preferredStoreId),
      stores: stores,
      mode: mode,
      access: access,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      subscription: Subscription.fromJson(
        json['subscription'] as Map<String, dynamic>?,
      ),
    );
  }

  static StoreProfile pickStore(List<StoreProfile> stores, String? preferred) {
    if (stores.isEmpty) return const StoreProfile(id: '', name: 'My store');
    return stores.firstWhere(
      (store) => store.id == preferred,
      orElse: () => stores.first,
    );
  }

  AuthSession copyWith({
    String? accessToken,
    StoreProfile? store,
    List<StoreProfile>? stores,
    AccessGrant? access,
    bool? ended,
    Subscription? subscription,
  }) => AuthSession(
    owner: owner,
    store: store ?? this.store,
    stores: stores ?? this.stores,
    mode: mode,
    access: access ?? this.access,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken,
    ended: ended ?? this.ended,
    subscription: subscription ?? this.subscription,
  );
}
