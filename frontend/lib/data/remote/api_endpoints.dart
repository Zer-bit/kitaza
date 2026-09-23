/// Every server path in one place, so a backend route rename is a one-file
/// change on the client.
abstract final class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/me';
  static const String join = '/auth/join';
  static const String stores = '/stores';
  static const String devices = '/devices';
  static const String billing = '/billing';
  static const String billingCheckout = '/billing/checkout';
  static const String accountPrivacy = '/account/privacy';
  static const String accountConsent = '/account/consent';
  static const String accountExport = '/account/export';
  static const String accountDeletion = '/account/deletion';

  static String store(String storeId) => '/stores/$storeId';
  static String device(String sessionId) => '/devices/$sessionId';
  static String staff(String storeId) => '/stores/$storeId/staff';
  static String staffMember(String storeId, String staffId) =>
      '/stores/$storeId/staff/$staffId';
  static String staffInvite(String storeId, String staffId) =>
      '/stores/$storeId/staff/$staffId/invite';
  static String activity(String storeId) => '/stores/$storeId/activity';
  static String benchmarks(String storeId) => '/stores/$storeId/benchmarks';

  static String syncPush(String storeId) => '/stores/$storeId/sync/push';
  static String syncPull(String storeId) => '/stores/$storeId/sync/pull';
  static String dashboard(String storeId) => '/stores/$storeId/dashboard';
  static String reportSummary(String storeId) =>
      '/stores/$storeId/reports/summary';

  static String realtime(String baseUrl, String storeId, String token) =>
      '$baseUrl/ws/store/$storeId?token=$token';
}
