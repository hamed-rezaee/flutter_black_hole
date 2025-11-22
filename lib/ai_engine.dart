import 'models.dart';
import 'game_engine.dart';

class AIEngine {
  static const int _maxDepth = 6;
  static const double _positionWeight = 1.0;
  static const double _mobilityWeight = 0.5;

  static (int, int)? getBestMove(GameEngine engine, {int depth = _maxDepth}) {
    final validMoves = _getValidMoves(engine);

    if (validMoves.isEmpty) {
      return null;
    }

    if (validMoves.length == 1) {
      return validMoves.first;
    }

    double bestScore = double.negativeInfinity;
    (int, int)? bestMove;

    for (final move in validMoves) {
      final testEngine = _copyGameEngine(engine);
      testEngine.placePiece(move.$1, move.$2);

      final score = _minimax(
        testEngine,
        depth - 1,
        false,
        double.negativeInfinity,
        double.infinity,
      );

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  static double _minimax(
    GameEngine engine,
    int depth,
    bool isMaximizing,
    double alpha,
    double beta,
  ) {
    if (depth == 0 || engine.isGameOver) {
      return _evaluatePosition(engine);
    }

    if (isMaximizing) {
      double maxScore = double.negativeInfinity;
      final moves = _getValidMoves(engine);

      for (final move in moves) {
        final testEngine = _copyGameEngine(engine);
        testEngine.placePiece(move.$1, move.$2);

        final score = _minimax(testEngine, depth - 1, false, alpha, beta);
        maxScore = score > maxScore ? score : maxScore;
        alpha = score > alpha ? score : alpha;

        if (beta <= alpha) {
          break;
        }
      }

      return maxScore;
    } else {
      double minScore = double.infinity;
      final moves = _getValidMoves(engine);

      for (final move in moves) {
        final testEngine = _copyGameEngine(engine);
        testEngine.placePiece(move.$1, move.$2);

        final score = _minimax(testEngine, depth - 1, true, alpha, beta);
        minScore = score < minScore ? score : minScore;
        beta = score < beta ? score : beta;

        if (beta <= alpha) {
          break;
        }
      }

      return minScore;
    }
  }

  static double _evaluatePosition(GameEngine engine) {
    if (engine.isGameOver) {
      final winner = engine.getWinner();
      if (winner == Player.blue) {
        return 1000;
      } else if (winner == Player.red) {
        return -1000;
      } else {
        return 0;
      }
    }

    double score = 0;

    final blackHolePos = _getPredictedBlackHole(engine);
    if (blackHolePos != null) {
      score += _evaluateBlackHoleProximity(engine, blackHolePos);
    }

    score += _evaluateMobility(engine);

    return score;
  }

  static List<(int, int)> _getValidMoves(GameEngine engine) {
    final moves = <(int, int)>[];

    for (final entry in engine.board.grid.entries) {
      if (entry.value == null) {
        moves.add(entry.key);
      }
    }

    return moves;
  }

  static (int, int)? _getPredictedBlackHole(GameEngine engine) {
    if (engine.isGameOver) {
      return engine.getBlackHole();
    }

    int totalPieces = 0;
    for (final piece in engine.board.grid.values) {
      if (piece != null) {
        totalPieces++;
      }
    }

    final totalBoardSpots = 21;

    if (totalPieces > totalBoardSpots - 5) {
      for (final entry in engine.board.grid.entries) {
        if (entry.value == null) {
          return entry.key;
        }
      }
    }

    return null;
  }

  static double _evaluateBlackHoleProximity(
    GameEngine engine,
    (int, int) blackHole,
  ) {
    double score = 0;

    final neighbors = engine.board.getNeighbors(blackHole.$1, blackHole.$2);
    int aiPiecesNear = 0;
    int humanPiecesNear = 0;
    int aiValueNear = 0;
    int humanValueNear = 0;

    for (final pos in neighbors) {
      final piece = engine.board.grid[pos];
      if (piece != null) {
        if (piece.owner == Player.blue) {
          aiPiecesNear++;
          aiValueNear += piece.value;
        } else {
          humanPiecesNear++;
          humanValueNear += piece.value;
        }
      }
    }

    score += aiValueNear * 10;
    score -= humanValueNear * 10;

    score += aiPiecesNear * 5;
    score -= humanPiecesNear * 5;

    return score * _positionWeight;
  }

  static double _evaluateMobility(GameEngine engine) {
    final moves = _getValidMoves(engine);
    return moves.length * _mobilityWeight;
  }

  static GameEngine _copyGameEngine(GameEngine engine) {
    final newEngine = GameEngine();

    for (final entry in engine.board.grid.entries) {
      if (entry.value != null) {
        newEngine.board.grid[entry.key] = entry.value;
      }
    }

    newEngine.currentPlayer = engine.currentPlayer;
    newEngine.currentTurn = engine.currentTurn;
    newEngine.nextValue[Player.red] = engine.nextValue[Player.red]!;
    newEngine.nextValue[Player.blue] = engine.nextValue[Player.blue]!;

    return newEngine;
  }
}
