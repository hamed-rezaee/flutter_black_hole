import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'network_manager_interface.dart';

class NetworkManagerImplementation implements NetworkManagerInterface {
  WebSocketChannel? _clientChannel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  @override
  Future<String> getIpAddress() async {
    return 'Web Client'; // Cannot get local IP on web easily
  }

  @override
  Future<void> hostGame() async {
    throw UnsupportedError(
      'Hosting is not supported on Web. Please host from a Desktop device.',
    );
  }

  @override
  Future<void> joinGame(String ip) async {
    try {
      // WebSockets on web use ws://
      final uri = Uri.parse('ws://$ip:4040');
      _clientChannel = WebSocketChannel.connect(uri);

      _clientChannel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onDone: () {
          debugPrint('Client channel done');
          _messageController.add({'type': 'DISCONNECT'});
        },
        onError: (e) {
          debugPrint('Client channel error: $e');
          _messageController.add({'type': 'DISCONNECT'});
        },
      );
    } catch (e) {
      debugPrint('Error joining: $e');
      rethrow;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final String message = data.toString();
      final json = jsonDecode(message);
      _messageController.add(json);
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  @override
  void send(Map<String, dynamic> data) {
    final msg = jsonEncode(data);
    if (_clientChannel != null) {
      _clientChannel!.sink.add(msg);
    }
  }

  @override
  void dispose() {
    _clientChannel?.sink.close();
    _messageController.close();
  }
}
