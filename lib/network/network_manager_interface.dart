import 'dart:async';

abstract class NetworkManagerInterface {
  Stream<Map<String, dynamic>> get messageStream;

  Future<String> createOffer();

  Future<String> createAnswer(String offer);

  Future<void> completeConnection(String answer);

  void send(Map<String, dynamic> data);

  void dispose();
}
