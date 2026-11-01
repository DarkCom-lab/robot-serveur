import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

/// Gestionnaire de connexion WebSocket pour les flux d'état robot en temps réel.
class WebSocketClient {
  final String _wsUrl;
  WebSocketChannel? _channel;
  StreamController<dynamic>? _controller;
  Timer? _reconnectTimer;
  bool _isManuallyClosed = false;

  WebSocketClient({String? wsUrl}) : _wsUrl = wsUrl ?? AppConfig.wsUrl;

  Stream<dynamic> get stream {
    _controller ??= StreamController<dynamic>.broadcast(
      onListen: _connect,
      onCancel: _disconnect,
    );
    return _controller!.stream;
  }

  void _connect() {
    if (_isManuallyClosed) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data as String);
            _controller?.add(parsed);
          } catch (e) {
            _controller?.add(data);
          }
        },
        onError: (error) {
          _scheduleReconnect();
        },
        onDone: () {
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isManuallyClosed) return;
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      _connect();
    });
  }

  void send(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _isManuallyClosed = true;
    _disconnect();
    _controller?.close();
  }
}
