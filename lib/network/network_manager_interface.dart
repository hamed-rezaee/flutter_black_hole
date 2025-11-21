import 'dart:async';

abstract class NetworkManagerInterface {
  Stream<Map<String, dynamic>> get messageStream;
  Future<void> hostGame();
  Future<void> joinGame(String ip);
  Future<String> getIpAddress();
  void send(Map<String, dynamic> data);
  void dispose();
}
