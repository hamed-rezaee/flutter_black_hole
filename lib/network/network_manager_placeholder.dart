import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Conditional import for ServerSocket/HttpServer which are only in dart:io
// We can't use dart:io in web.
// So we need to separate the Host logic (Desktop only) from Client logic (All platforms).

class NetworkManager {
  // Server side (Desktop only)

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  WebSocketChannel? _channel;

  // Host logic is only for Desktop/Mobile (dart:io platforms)
  // We can't easily support Hosting on Web without a relay.

  Future<void> hostGame() async {
    if (kIsWeb) {
      throw UnsupportedError('Hosting is not supported on Web');
    }
    await _hostGameImpl();
  }

  Future<void> joinGame(String ip) async {
    // Join works on all platforms via WebSocket
    final uri = Uri.parse('ws://$ip:4040');
    try {
      _channel = WebSocketChannel.connect(uri);
      _setupChannelListener();
    } catch (e) {
      debugPrint('Error joining: $e');
      rethrow;
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      // If we are host, we might need to send to the connected client.
      // In WebSocket model, if we are server, we have a socket/channel for the client.
      _sendToClient(data);
    }
  }

  void dispose() {
    _channel?.sink.close();
    _stopHosting();
    _messageController.close();
  }

  // ----------------------------------------------------------------
  // Platform specific implementations
  // We will use a "stub" approach if we can't use conditional imports easily in one file.
  // But we can use `if (dart.library.io)` import.

  // Actually, let's put the IO logic in a separate class that is conditionally imported.
  // But for now, to keep it in one file and avoid complex refactoring,
  // we can use `universal_io` or just separate files.
  // Let's try to implement the IO part in a separate file `server_stub.dart` (default) and `server_io.dart`.

  // Wait, I can just use `network_implementation.dart` with conditional export.

  // Let's stick to this file but use a helper for the server part.

  Future<void> _hostGameImpl() async {
    // This method will be implemented by a helper that imports dart:io
    // But we can't call it from here if we don't import it.
    // So we need the factory pattern.
    throw UnimplementedError('Implemented in platform specific file');
  }

  void _sendToClient(Map<String, dynamic> data) {}
  void _stopHosting() {}
  void _setupChannelListener() {
    _channel!.stream.listen(
      (message) {
        try {
          final json = jsonDecode(message);
          _messageController.add(json);
        } catch (e) {
          debugPrint('Error parsing message: $e');
        }
      },
      onDone: () {
        debugPrint('Connection closed');
        _messageController.add({'type': 'DISCONNECT'});
      },
      onError: (e) {
        debugPrint('Socket error: $e');
        _messageController.add({'type': 'DISCONNECT'});
      },
    );
  }

  Future<String> getIpAddress() async {
    return '127.0.0.1'; // Placeholder
  }
}
