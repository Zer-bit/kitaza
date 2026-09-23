import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitaza_app/data/remote/realtime_channel.dart';

/// A real websocket server on a real port, so the app's own client is
/// exercised end to end rather than against a stand-in.
class FakeServer {
  FakeServer._(this._server);

  final HttpServer _server;
  final List<WebSocket> _connected = [];

  /// The tokens each connection arrived with, in order.
  final List<String?> tokensSeen = [];

  static Future<FakeServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = FakeServer._(server);
    unawaited(fake._accept());
    return fake;
  }

  String get baseUrl => 'ws://127.0.0.1:${_server.port}';

  Future<void> _accept() async {
    await for (final request in _server) {
      tokensSeen.add(request.uri.queryParameters['token']);
      _connected.add(await WebSocketTransformer.upgrade(request));
    }
  }

  Future<void> waitForConnection({int atLeast = 1}) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (_connected.length < atLeast && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(_connected.length, greaterThanOrEqualTo(atLeast));
  }

  void send(String frame) => _connected.last.add(frame);

  Future<void> hangUp() => _connected.last.close();

  Future<void> stop() async {
    for (final socket in _connected) {
      await socket.close();
    }
    await _server.close(force: true);
  }
}

void main() {
  late FakeServer server;

  setUp(() async => server = await FakeServer.start());
  tearDown(() async => server.stop());

  RealtimeChannel channelOn(
    FakeServer server, {
    Future<String?> Function()? token,
  }) {
    final channel = RealtimeChannel(
      storeId: 'store-1',
      baseUrl: server.baseUrl,
      minBackoff: const Duration(milliseconds: 20),
      readAccessToken: token ?? () async => 'access-token',
    );
    addTearDown(channel.dispose);
    return channel;
  }

  test('an event from the server becomes an event in the app', () async {
    final channel = channelOn(server);
    final received = channel.events.first;
    await channel.connect();
    await server.waitForConnection();

    server.send('{"topic":"sale_recorded"}');

    expect((await received).topic, RealtimeTopic.saleRecorded);
    expect(server.tokensSeen.single, 'access-token');
  });

  test('a topic this version does not know becomes a plain refresh', () async {
    final channel = channelOn(server);
    final received = channel.events.first;
    await channel.connect();
    await server.waitForConnection();

    // A newer server sending something older phones have never heard of must
    // still make them sync, not crash or fall silent.
    server.send('{"topic":"something_invented_later"}');

    expect((await received).topic, RealtimeTopic.dashboardStale);
  });

  test('a frame that is not JSON is ignored, not fatal', () async {
    final channel = channelOn(server);
    final events = <RealtimeEvent>[];
    channel.events.listen(events.add);
    await channel.connect();
    await server.waitForConnection();

    server.send('not json at all');
    server.send('{"topic":"expense_recorded"}');
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(events.map((event) => event.topic), [RealtimeTopic.expenseRecorded]);
  });

  test('a dropped connection comes back by itself', () async {
    final channel = channelOn(server);
    await channel.connect();
    await server.waitForConnection();

    await server.hangUp();

    await server.waitForConnection(atLeast: 2);
    final received = channel.events.first;
    server.send('{"topic":"sale_recorded"}');
    expect((await received).topic, RealtimeTopic.saleRecorded);
  });

  test(
    'reconnecting asks for the token again, never reusing a stale one',
    () async {
      // The HTTP layer renews access tokens in the background. A socket that
      // captured one at startup would knock forever with an expired token.
      var issued = 0;
      final channel = channelOn(server, token: () async => 'token-${++issued}');
      await channel.connect();
      await server.waitForConnection();

      await server.hangUp();
      await server.waitForConnection(atLeast: 2);

      expect(server.tokensSeen, ['token-1', 'token-2']);
    },
  );

  test('no token yet means wait and try again, not give up', () async {
    String? token;
    final channel = channelOn(server, token: () async => token);
    await channel.connect();

    expect(server.tokensSeen, isEmpty, reason: 'nothing to connect with');

    token = 'arrived-late';
    await server.waitForConnection();
    expect(server.tokensSeen.single, 'arrived-late');
  });
}
