import 'models.dart';

class GameEngine {
  final Board board;
  Player currentPlayer;
  int currentTurn;

  final Map<Player, int> nextValue;

  GameEngine()
    : board = Board(),
      currentPlayer = Player.red,
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

    nextValue[currentPlayer] = nextValue[currentPlayer]! + 1;
    currentPlayer = currentPlayer.opponent;
  }

  (int, int)? getBlackHole() {
    if (!isGameOver) return null;

    for (final entry in board.grid.entries) {
      if (entry.value == null) {
        return entry.key;
      }
    }
    return null;
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
      return null;
    }
  }
}
