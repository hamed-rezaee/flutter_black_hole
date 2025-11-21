import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'network_manager_interface.dart';

class NetworkManagerImplementation implements NetworkManagerInterface {
  HttpServer? _server;
  WebSocket?
  _serverSocket; // The socket on the server side connected to the client
  WebSocketChannel? _clientChannel; // The channel on the client side

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  @override
  Future<String> getIpAddress() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  @override
  Future<void> hostGame() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 4040);
      debugPrint('Hosting on ${_server!.address.address}:${_server!.port}');

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          debugPrint('Client connected via WebSocket');

          if (_serverSocket != null) {
            socket.close(WebSocketStatus.normalClosure, 'Game full');
            return;
          }

          _serverSocket = socket;
          _setupServerSocketListener();

          // Notify local UI that client connected
          _messageController.add({'type': 'CONNECTED'});

          // Send handshake
          send({'type': 'HANDSHAKE', 'player': 'blue'});
        }
      });
    } catch (e) {
      debugPrint('Error hosting: $e');
      rethrow;
    }
  }

  void _setupServerSocketListener() {
    _serverSocket!.listen(
      (data) {
        _handleMessage(data);
      },
      onDone: () {
        debugPrint('Server socket done');
        _messageController.add({'type': 'DISCONNECT'});
        _serverSocket = null;
      },
      onError: (e) {
        debugPrint('Server socket error: $e');
        _messageController.add({'type': 'DISCONNECT'});
        _serverSocket = null;
      },
    );
  }

  @override
  Future<void> joinGame(String ip) async {
    try {
      final uri = Uri.parse('ws://$ip:4040');
      _clientChannel = IOWebSocketChannel.connect(uri);
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
    if (_serverSocket != null) {
      _serverSocket!.add(msg);
    } else if (_clientChannel != null) {
      _clientChannel!.sink.add(msg);
    }
  }

  @override
  void dispose() {
    _serverSocket?.close();
    _server?.close();
    _clientChannel?.sink.close();
    _messageController.close();
  }
}
