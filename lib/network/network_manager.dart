import 'network_manager_interface.dart';
import 'network_manager_webrtc.dart';

class NetworkManager implements NetworkManagerInterface {
  final NetworkManagerImplementation _impl = NetworkManagerImplementation();

  @override
  Stream<Map<String, dynamic>> get messageStream => _impl.messageStream;

  @override
  Future<String> createOffer() => _impl.createOffer();

  @override
  Future<String> createAnswer(String code) => _impl.createAnswer(code);

  @override
  Future<void> completeConnection(String answer) =>
      _impl.completeConnection(answer);

  @override
  void send(Map<String, dynamic> data) => _impl.send(data);

  @override
  void dispose() => _impl.dispose();
}
