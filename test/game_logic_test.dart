import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_black_hole/models.dart';
import 'package:flutter_black_hole/game_engine.dart';

void main() {
  group('GameEngine', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Initial state is correct', () {
      expect(engine.currentPlayer, Player.red);
      expect(engine.nextValue[Player.red], 1);
      expect(engine.nextValue[Player.blue], 1);
      expect(engine.isGameOver, false);

      expect(engine.board.grid.length, 21);
      expect(engine.board.grid.values.every((p) => p == null), true);
    });

    test('Place piece updates state', () {
      engine.placePiece(0, 0);

      expect(engine.board.grid[(0, 0)]?.owner, Player.red);
      expect(engine.board.grid[(0, 0)]?.value, 1);

      expect(engine.currentPlayer, Player.blue);
      expect(engine.nextValue[Player.red], 2);
      expect(engine.nextValue[Player.blue], 1);
    });

    test('Cannot place on occupied spot', () {
      engine.placePiece(0, 0);
      expect(() => engine.placePiece(0, 0), throwsStateError);
    });

    test('Game ends after 20 moves', () {
      final spots = engine.board.grid.keys.toList();

      for (int i = 0; i < 20; i++) {
        engine.placePiece(spots[i].$1, spots[i].$2);
      }

      expect(engine.isGameOver, true);
      expect(engine.getBlackHole(), spots[20]);
    });

    test('Scoring calculation', () {
      final testBoard = Board();

      testBoard.grid[(0, 0)] = const Piece(owner: Player.red, value: 5);
      testBoard.grid[(1, 1)] = const Piece(owner: Player.blue, value: 3);
      testBoard.grid[(2, 0)] = const Piece(owner: Player.red, value: 2);
      testBoard.grid[(2, 1)] = const Piece(owner: Player.blue, value: 4);

      engine.board.grid[(0, 0)] = const Piece(owner: Player.red, value: 5);
      engine.board.grid[(1, 1)] = const Piece(owner: Player.blue, value: 3);
      engine.board.grid[(2, 0)] = const Piece(owner: Player.red, value: 2);
      engine.board.grid[(2, 1)] = const Piece(owner: Player.blue, value: 4);

      engine.nextValue[Player.red] = 11;
      engine.nextValue[Player.blue] = 11;

      for (final key in engine.board.grid.keys) {
        if (key == (1, 0)) continue;
        if (engine.board.grid[key] == null) {
          engine.board.grid[key] = const Piece(owner: Player.red, value: 1);
        }
      }

      final scores = engine.calculateScores();
      expect(scores[Player.red], 7);
      expect(scores[Player.blue], 7);
      expect(engine.getWinner(), null);

      engine.board.grid[(0, 0)] = const Piece(owner: Player.red, value: 1);
      final scores2 = engine.calculateScores();
      expect(scores2[Player.red], 3);
      expect(scores2[Player.blue], 7);
      expect(engine.getWinner(), Player.red);
    });
  });
}
