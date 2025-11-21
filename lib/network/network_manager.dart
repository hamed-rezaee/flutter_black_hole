import 'network_manager_interface.dart';
import 'network_manager_io.dart'
    if (dart.library.html) 'network_manager_web.dart';

class NetworkManager implements NetworkManagerInterface {
  final NetworkManagerImplementation _impl = NetworkManagerImplementation();

  @override
  Stream<Map<String, dynamic>> get messageStream => _impl.messageStream;

  @override
  Future<String> getIpAddress() => _impl.getIpAddress();

  @override
  Future<void> hostGame() => _impl.hostGame();

  @override
  Future<void> joinGame(String ip) => _impl.joinGame(ip);

  @override
  void send(Map<String, dynamic> data) => _impl.send(data);

  @override
  void dispose() => _impl.dispose();
}
