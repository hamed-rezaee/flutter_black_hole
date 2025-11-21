import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../network/network_manager.dart';
import '../main.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _ipController = TextEditingController();
  bool _isLoading = false;

  void _startGame({NetworkManager? networkManager, bool isHost = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GameScreen(networkManager: networkManager, isHost: isHost),
      ),
    );
  }

  Future<void> _hostGame() async {
    if (kIsWeb) {
      _showWebWarning();
      return;
    }
    setState(() => _isLoading = true);
    final manager = NetworkManager();
    try {
      await manager.hostGame();

      if (mounted) {
        _startGame(networkManager: manager, isHost: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinGame() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() => _isLoading = true);
    final manager = NetworkManager();
    try {
      await manager.joinGame(ip);
      if (mounted) {
        _startGame(networkManager: manager, isHost: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showWebWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Supported on Web'),
        content: const Text(
          'Network play uses direct TCP sockets which are not supported in the browser.\n\n'
          'Please run the app on Desktop (Windows/macOS/Linux) or Mobile (Android/iOS) to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Black Hole')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => _startGame(),
                child: const Text('Local Play'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              const Text(
                'Network Play',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _hostGame,
                child: const Text('Host Game'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'Host IP Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _joinGame,
                    child: const Text('Join'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
