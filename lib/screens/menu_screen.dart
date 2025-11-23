import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../network/network_manager.dart';
import '../main.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  void _startGame({NetworkManager? networkManager, bool isHost = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GameScreen(networkManager: networkManager, isHost: isHost),
      ),
    );
  }

  void _startAIGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameScreen(playAgainstAI: true),
      ),
    );
  }

  Future<void> _createCode() async {
    setState(() => _isLoading = true);
    final manager = NetworkManager();
    try {
      final code = await manager.createCode();

      if (mounted) {
        setState(() => _isLoading = false);

        _showCodeDialog(code, manager);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating game: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCodeDialog(String code, NetworkManager manager) {
    final answerController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Share This Game'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Copy this code and send it to the other player:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: SelectableText(
                  code,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  maxLines: 5,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Paste the answer you receive:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: answerController,
                decoration: InputDecoration(
                  labelText: 'Paste code here',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              manager.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final answer = answerController.text.trim();
              if (answer.isEmpty) return;

              if (context.mounted) {
                Navigator.of(context).pop();

                _startGame(networkManager: manager, isHost: true);

                try {
                  await manager.completeConnection(answer);
                } catch (e) {
                  debugPrint('Error completing connection: $e');
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    final manager = NetworkManager();
    try {
      final answer = await manager.createAnswer(code);

      if (mounted) {
        setState(() => _isLoading = false);

        _showAnswerDialog(answer, manager);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating answer: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAnswerDialog(String answer, NetworkManager manager) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Send This Answer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Copy this answer and send it back to the host:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: SelectableText(
                  answer,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  maxLines: 5,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: answer));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Answer copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Answer'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connection will be established automatically.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame(networkManager: manager, isHost: false);
            },
            child: const Text('Start Game'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double maxWidth = 500;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepPurple.withValues(alpha: 0.4),
                          Colors.purple.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.purple.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Black Hole',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A Strategic Number Game',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  TextButton(
                    onPressed: _startGame,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Start Local Game',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  TextButton(
                    onPressed: _startAIGame,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.cyan.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Play vs AI',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.purple.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Column(
                    children: [
                      Text(
                        'Network Play',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  _buildNetworkCard(
                    title: 'Host a Game',
                    description:
                        '1. Click "Create Game"\n'
                        '2. Share with another player\n'
                        '3. Paste their answer to connect',
                    buttonLabel: _isLoading ? 'Creating...' : 'Create',
                    onPressed: _isLoading ? null : _createCode,
                    accentColor: Colors.red,
                  ),
                  SizedBox(height: 24),

                  _buildNetworkCardWithInput(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkCard({
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback? onPressed,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCardWithInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Join a Game',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '1. Paste the code from host\n'
              '2. Click "Join with Code"\n'
              '3. Share the answer back',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Paste Code Here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              maxLines: 1,
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : _joinWithCode,
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange.withValues(alpha: 0.7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isLoading ? 'Joining...' : 'Join'),
            ),
          ],
        ),
      ),
    );
  }
}
