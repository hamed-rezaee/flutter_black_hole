import 'dart:async';

abstract class NetworkManagerInterface {
  Stream<Map<String, dynamic>> get messageStream;

  Future<String> createCode();

  Future<String> createAnswer(String code);

  Future<void> completeConnection(String answer);

  void send(Map<String, dynamic> data);

  void dispose();
}
