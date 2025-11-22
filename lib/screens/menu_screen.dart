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
  final TextEditingController _offerController = TextEditingController();
  bool _isLoading = false;

  void _startGame({NetworkManager? networkManager, bool isHost = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            GameScreen(networkManager: networkManager, isHost: isHost),
      ),
    );
  }

  Future<void> _createOffer() async {
    setState(() => _isLoading = true);
    final manager = NetworkManager();
    try {
      final offer = await manager.createOffer();

      if (mounted) {
        setState(() => _isLoading = false);

        _showOfferDialog(offer, manager);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating offer: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showOfferDialog(String offer, NetworkManager manager) {
    final answerController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Share This Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Copy this offer and send it to the other player:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  offer,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  maxLines: 5,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: offer));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Offer copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Offer'),
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
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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

  Future<void> _joinWithOffer() async {
    final offer = _offerController.text.trim();
    if (offer.isEmpty) return;

    setState(() => _isLoading = true);
    final manager = NetworkManager();
    try {
      final answer = await manager.createAnswer(offer);

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
                  borderRadius: BorderRadius.circular(8),
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 500;
    final isMediumScreen = screenSize.width < 800;

    double maxWidth = 500;
    if (isMediumScreen) {
      maxWidth = 400;
    }
    if (isSmallScreen) {
      maxWidth = double.infinity;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Black Hole'),
        elevation: 4,
        centerTitle: true,
      ),
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
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title with icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
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
                        Icon(
                          Icons.dark_mode,
                          size: isSmallScreen ? 48 : 64,
                          color: Colors.purple[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Black Hole',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 28 : 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A Strategic Number Game',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  // Local Play Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.cyan.withValues(alpha: 0.3),
                          Colors.blue.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.cyan.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _startGame(),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.videogame_asset,
                                size: isSmallScreen ? 32 : 40,
                                color: Colors.cyan[300],
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              Text(
                                'Local Play',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 8),
                              Text(
                                'Play against the computer',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 32),
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
                  SizedBox(height: isSmallScreen ? 20 : 32),
                  // Network Play Header
                  Column(
                    children: [
                      Text(
                        'Network Play (WebRTC)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      Text(
                        'Play with friends on any platform!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.amber[300],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // Host Game Card
                  _buildNetworkCard(
                    icon: Icons.share,
                    title: 'Host a Game',
                    description:
                        '1. Click "Create Offer"\n'
                        '2. Share with another player\n'
                        '3. Paste their answer to connect',
                    buttonLabel: _isLoading ? 'Creating...' : 'Create Offer',
                    onPressed: _isLoading ? null : _createOffer,
                    isSmallScreen: isSmallScreen,
                    accentColor: Colors.red,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  // Join Game Card
                  _buildNetworkCardWithInput(isSmallScreen: isSmallScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback? onPressed,
    required bool isSmallScreen,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: isSmallScreen ? 24 : 28),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              description,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.send, size: 18),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 10 : 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCardWithInput({required bool isSmallScreen}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.login,
                  color: Colors.orange,
                  size: isSmallScreen ? 24 : 28,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'Join a Game',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              '1. Paste the offer from host\n'
              '2. Click "Join with Offer"\n'
              '3. Share the answer back',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            TextField(
              controller: _offerController,
              decoration: InputDecoration(
                labelText: 'Paste Offer Here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              ),
              maxLines: 3,
              style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _joinWithOffer,
              icon: const Icon(Icons.login, size: 18),
              label: Text(_isLoading ? 'Joining...' : 'Join with Offer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.withValues(alpha: 0.7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 10 : 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
