import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import 'api_endpoints.dart';

enum RealtimeTopic {
  saleRecorded,
  saleVoided,
  expenseRecorded,
  expenseRemoved,
  withdrawalRecorded,
  productChanged,
  stockLow,
  dashboardStale;

  static RealtimeTopic parse(String? raw) => switch (raw) {
    'sale_recorded' => RealtimeTopic.saleRecorded,
    'sale_voided' => RealtimeTopic.saleVoided,
    'expense_recorded' => RealtimeTopic.expenseRecorded,
    'expense_removed' => RealtimeTopic.expenseRemoved,
    'withdrawal_recorded' => RealtimeTopic.withdrawalRecorded,
    'product_changed' => RealtimeTopic.productChanged,
    'stock_low' => RealtimeTopic.stockLow,
    _ => RealtimeTopic.dashboardStale,
  };
}

class RealtimeEvent {
  const RealtimeEvent({required this.topic, this.message});

  final RealtimeTopic topic;
  final String? message;
}

/// Keeps a live connection to the store's event stream so a sale rung up on
/// the counter tablet updates the owner's phone immediately.
///
/// Reconnects with backoff and simply stays quiet when there is no network -
/// the app is fully usable without it.
class RealtimeChannel {
  RealtimeChannel({required this.storeId, required this.readAccessToken});

  final String storeId;

  /// Read afresh on every connection attempt. Access tokens are short-lived
  /// and renewed by the HTTP layer, so one captured at construction would
  /// leave a reconnecting socket knocking with an expired token forever.
  final Future<String?> Function() readAccessToken;

  static const Duration _minBackoff = Duration(seconds: 2);
  static const Duration _maxBackoff = Duration(seconds: 60);

  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Duration _backoff = _minBackoff;
  bool _disposed = false;

  Stream<RealtimeEvent> get events => _events.stream;

  Future<void> connect() async {
    if (_disposed) return;

    _reconnectTimer?.cancel();

    final token = await readAccessToken();
    if (_disposed) return;
    if (token == null || token.isEmpty) {
      _scheduleReconnect();
      return;
    }

    try {
      final uri = Uri.parse(
        ApiEndpoints.realtime(AppConfig.realtimeBaseUrl, storeId, token),
      );
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;

      _subscription = channel.stream.listen(
        _handleFrame,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } on Exception {
      _scheduleReconnect();
    }
  }

  void _handleFrame(dynamic frame) {
    // A frame arriving means the link is healthy, so reset the backoff.
    _backoff = _minBackoff;

    if (frame is! String) return;

    try {
      final payload = jsonDecode(frame) as Map<String, dynamic>;
      _events.add(
        RealtimeEvent(
          topic: RealtimeTopic.parse(payload['topic'] as String?),
          message: payload['message'] as String?,
        ),
      );
    } on FormatException {
      // A frame we cannot read is not worth tearing down the connection for.
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;

    _subscription?.cancel();
    _subscription = null;
    _channel = null;

    _reconnectTimer = Timer(_backoff, connect);
    _backoff = Duration(
      seconds: (_backoff.inSeconds * 2).clamp(
        _minBackoff.inSeconds,
        _maxBackoff.inSeconds,
      ),
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    await _events.close();
  }
}
