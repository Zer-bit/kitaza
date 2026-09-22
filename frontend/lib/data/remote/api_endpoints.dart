/// Every server path in one place, so a backend route rename is a one-file
/// change on the client.
abstract final class ApiEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/me';

  static String syncPush(String storeId) => '/stores/$storeId/sync/push';
  static String syncPull(String storeId) => '/stores/$storeId/sync/pull';
  static String dashboard(String storeId) => '/stores/$storeId/dashboard';
  static String reportSummary(String storeId) =>
      '/stores/$storeId/reports/summary';

  static String realtime(String baseUrl, String storeId, String token) =>
      '$baseUrl/ws/store/$storeId?token=$token';
}
