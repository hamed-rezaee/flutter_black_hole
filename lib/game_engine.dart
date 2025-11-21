import 'models.dart';

class GameEngine {
  final Board board;
  Player currentPlayer;
  int currentTurn; // 1 to 10

  // Track pieces played to ensure sequential order
  // Actually, the rule is: "Discs must be placed in numerical order".
  // So turn 1: Red plays 1, Blue plays 1.
  // Turn 2: Red plays 2, Blue plays 2.
  // ...
  // Wait, standard rule: "Two players alternate turns placing a numbered disc... Discs are numbered 1-10 and must be placed in numerical order."
  // Usually this means Player A plays 1, Player B plays 1, Player A plays 2...
  // Let's track the next value for each player.

  final Map<Player, int> nextValue;

  GameEngine()
    : board = Board(),
      currentPlayer =
          Player.red, // Red starts? Rules don't specify, let's assume Red.
      currentTurn = 1,
      nextValue = {Player.red: 1, Player.blue: 1};

  bool get isGameOver =>
      nextValue[Player.red]! > 10 && nextValue[Player.blue]! > 10;

  Piece get nextPiece =>
      Piece(owner: currentPlayer, value: nextValue[currentPlayer]!);

  void placePiece(int row, int col) {
    if (isGameOver) throw StateError('Game is over');

    final piece = nextPiece;
    board.placePiece(row, col, piece);

    // Update state
    nextValue[currentPlayer] = nextValue[currentPlayer]! + 1;
    currentPlayer = currentPlayer.opponent;
  }

  (int, int)? getBlackHole() {
    if (!isGameOver) return null;

    // Find the single empty spot
    for (final entry in board.grid.entries) {
      if (entry.value == null) {
        return entry.key;
      }
    }
    return null; // Should not happen if logic is correct and game is over
  }

  Map<Player, int> calculateScores() {
    final blackHole = getBlackHole();
    if (blackHole == null) return {Player.red: 0, Player.blue: 0};

    final neighbors = board.getNeighbors(blackHole.$1, blackHole.$2);
    int redScore = 0;
    int blueScore = 0;

    for (final pos in neighbors) {
      final piece = board.grid[pos];
      if (piece != null) {
        if (piece.owner == Player.red) {
          redScore += piece.value;
        } else {
          blueScore += piece.value;
        }
      }
    }

    return {Player.red: redScore, Player.blue: blueScore};
  }

  Player? getWinner() {
    final scores = calculateScores();
    if (scores[Player.red]! < scores[Player.blue]!) {
      return Player.red;
    } else if (scores[Player.blue]! < scores[Player.red]!) {
      return Player.blue;
    } else {
      return null; // Draw
    }
  }
}
