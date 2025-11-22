import 'package:flutter/material.dart';
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
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: false,
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
  Player? _localPlayer;
  bool _waitingForOpponent = false;

  @override
  void initState() {
    super.initState();
    _isRemoteGame = widget.networkManager != null;

    if (_isRemoteGame) {
      _localPlayer = widget.isHost ? Player.red : Player.blue;
      _waitingForOpponent = true;

      widget.networkManager!.messageStream.listen(_handleNetworkMessage);
    }

    _startNewGame();
  }

  void _handleNetworkMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    debugPrint('Received network message: $message');

    switch (message['type']) {
      case 'HANDSHAKE':
        debugPrint('Handshake received');
        setState(() {});
        break;
      case 'MOVE':
        final row = message['row'] as int;
        final col = message['col'] as int;
        debugPrint('Move received: row=$row, col=$col');
        setState(() {
          _engine.placePiece(row, col);
          _waitingForOpponent = false;
        });
        break;
      case 'DISCONNECT':
        debugPrint('Disconnect received');
        _showDisconnectDialog();
        break;
      case 'CONNECTED':
        debugPrint('Connection established!');
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

    if (_isRemoteGame) {
      if (_engine.currentPlayer != _localPlayer) return;
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
    double verticalPadding = 32;
    double horizontalPadding = 16;

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRemoteGame) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: _localPlayer == Player.red
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                            border: Border.all(
                              color: _localPlayer == Player.red
                                  ? Colors.red.withValues(alpha: 0.5)
                                  : Colors.blue.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            'You are ${_localPlayer?.name.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _localPlayer == Player.red
                                  ? Colors.red[300]
                                  : Colors.blue[300],
                            ),
                          ),
                        ),
                        SizedBox(height: verticalPadding),
                      ],
                      _buildStatusDisplay(),
                      SizedBox(height: verticalPadding),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: BoardWidget(
                          board: _engine.board,
                          onSpotTap: _handleSpotTap,
                        ),
                      ),
                      SizedBox(height: verticalPadding),
                      if (_engine.isGameOver) _buildGameOverDisplay(),
                    ],
                  ),
                ),
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
                  'Waiting for Connection...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Establishing WebRTC connection',
                  style: TextStyle(fontSize: 14),
                ),
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
        ? const Color(0xFFFF5252)
        : const Color(0xFF42A5F5);
    final nextVal = _engine.nextValue[_engine.currentPlayer];

    String statusText = 'Current Turn';
    if (_isRemoteGame) {
      if (_engine.currentPlayer == _localPlayer) {
        statusText = 'Your Turn';
      } else {
        statusText = "Opponent's Turn";
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: playerColor.withValues(alpha: 0.4), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _engine.currentPlayer.name.toUpperCase(),
                  style: TextStyle(
                    color: playerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                SizedBox(width: 16),
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
      resultColor = winner == Player.red
          ? const Color(0xFFFF5252)
          : const Color(0xFF42A5F5);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[850]!.withValues(alpha: 0.9),
            Colors.grey[900]!.withValues(alpha: 1.0),
          ],
        ),
        border: Border.all(color: resultColor.withValues(alpha: 0.5), width: 3),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              resultText,
              style: TextStyle(
                fontSize: 24,
                color: resultColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: Column(
                children: [
                  _buildScoreRow(
                    'Red',
                    scores[Player.red] ?? 0,
                    const Color(0xFFFF5252),
                  ),
                  SizedBox(height: 12),
                  _buildScoreRow(
                    'Blue',
                    scores[Player.blue] ?? 0,
                    const Color(0xFF42A5F5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              '(Lowest score wins)',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_isRemoteGame) {
                  Navigator.of(context).pop();
                } else {
                  _startNewGame();
                }
              },
              icon: Icon(_isRemoteGame ? Icons.exit_to_app : Icons.refresh),
              label: Text(_isRemoteGame ? 'Back to Menu' : 'Play Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: resultColor.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String player, int score, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              score.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Text(
          '$player Score',
          style: TextStyle(fontSize: 15, color: Colors.grey[300]),
        ),
      ],
    );
  }
}
