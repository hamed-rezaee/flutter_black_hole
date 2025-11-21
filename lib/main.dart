import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_engine.dart';
import 'models.dart';
import 'widgets/board_widget.dart';
import 'widgets/piece_widget.dart';
import 'network/network_manager.dart';
import 'screens/menu_screen.dart';

void main() {
  runApp(const BlackHoleApp());
}

class BlackHoleApp extends StatelessWidget {
  const BlackHoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Black Hole',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MenuScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  final NetworkManager? networkManager;
  final bool isHost;

  const GameScreen({super.key, this.networkManager, this.isHost = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine _engine;
  bool _isRemoteGame = false;
  Player? _localPlayer; // Null for local play (both), otherwise assigned
  bool _waitingForOpponent = false;
  String? _hostIp;

  @override
  void initState() {
    super.initState();
    _isRemoteGame = widget.networkManager != null;

    if (_isRemoteGame) {
      // Host is Red, Client is Blue (default, confirmed by handshake)
      _localPlayer = widget.isHost ? Player.red : Player.blue;
      _waitingForOpponent = widget.isHost; // Host waits for connection

      if (widget.isHost) {
        _fetchHostIp();
      }

      widget.networkManager!.messageStream.listen(_handleNetworkMessage);
    }

    _startNewGame();
  }

  Future<void> _fetchHostIp() async {
    final ip = await widget.networkManager!.getIpAddress();
    if (mounted) {
      setState(() {
        _hostIp = ip;
      });
    }
  }

  void _handleNetworkMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    switch (message['type']) {
      case 'HANDSHAKE':
        // Client receives this
        setState(() {
          // If we are client, we are blue. Host is red.
        });
        break;
      case 'MOVE':
        final row = message['row'] as int;
        final col = message['col'] as int;
        setState(() {
          _engine.placePiece(row, col);
          _waitingForOpponent =
              false; // Opponent moved, now my turn (if logic holds)
        });
        break;
      case 'DISCONNECT':
        _showDisconnectDialog();
        break;
      case 'CONNECTED':
        setState(() => _waitingForOpponent = false);
        break;
    }
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Disconnected'),
        content: const Text('Opponent disconnected.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  void _startNewGame() {
    setState(() {
      _engine = GameEngine();
    });
  }

  void _handleSpotTap(int row, int col) {
    if (_engine.isGameOver) return;
    if (_waitingForOpponent) return;

    // Network checks
    if (_isRemoteGame) {
      if (_engine.currentPlayer != _localPlayer) return; // Not my turn
    }

    try {
      setState(() {
        _engine.placePiece(row, col);
      });

      if (_isRemoteGame) {
        widget.networkManager!.send({'type': 'MOVE', 'row': row, 'col': col});
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    widget.networkManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Black Hole'),
        actions: [
          if (!_isRemoteGame)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startNewGame,
              tooltip: 'New Game',
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRemoteGame) ...[
                    Text(
                      'You are ${_localPlayer?.name.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildStatusDisplay(),
                  const SizedBox(height: 32),
                  BoardWidget(
                    board: _engine.board,
                    onSpotTap: _handleSpotTap,
                    spotSize: 45.0,
                  ),
                  const SizedBox(height: 32),
                  if (_engine.isGameOver) _buildGameOverDisplay(),
                ],
              ),
            ),
          ),
          if (_waitingForOpponent) _buildWaitingOverlay(),
        ],
      ),
    );
  }

  Widget _buildWaitingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Waiting for Opponent...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_hostIp != null) ...[
                  const SizedBox(height: 16),
                  const Text('Share this IP address:'),
                  const SizedBox(height: 8),
                  SelectableText(
                    _hostIp!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _hostIp!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('IP copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy IP'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDisplay() {
    if (_engine.isGameOver) return const SizedBox.shrink();

    final playerColor = _engine.currentPlayer == Player.red
        ? Colors.red
        : Colors.blue;
    final nextVal = _engine.nextValue[_engine.currentPlayer];

    String statusText = 'Current Turn';
    if (_isRemoteGame) {
      if (_engine.currentPlayer == _localPlayer) {
        statusText = 'Your Turn';
      } else {
        statusText = "Opponent's Turn";
      }
    }

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(statusText, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _engine.currentPlayer.name.toUpperCase(),
                  style: TextStyle(
                    color: playerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(width: 16),
                PieceWidget(
                  piece: Piece(owner: _engine.currentPlayer, value: nextVal!),
                  size: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverDisplay() {
    final scores = _engine.calculateScores();
    final winner = _engine.getWinner();

    String resultText;
    Color resultColor;

    if (winner == null) {
      resultText = "It's a Draw!";
      resultColor = Colors.white;
    } else {
      resultText = "${winner.name.toUpperCase()} Wins!";
      resultColor = winner == Player.red ? Colors.red : Colors.blue;
    }

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'GAME OVER',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              resultText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: resultColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Red Score: ${scores[Player.red]}'),
            Text('Blue Score: ${scores[Player.blue]}'),
            const SizedBox(height: 8),
            const Text('(Lowest score wins)'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_isRemoteGame) {
                  Navigator.of(context).pop(); // Back to menu
                } else {
                  _startNewGame();
                }
              },
              icon: Icon(_isRemoteGame ? Icons.exit_to_app : Icons.refresh),
              label: Text(_isRemoteGame ? 'Back to Menu' : 'Play Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
