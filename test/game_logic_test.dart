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
      // Board should have 21 empty spots
      expect(engine.board.grid.length, 21);
      expect(engine.board.grid.values.every((p) => p == null), true);
    });

    test('Place piece updates state', () {
      engine.placePiece(0, 0); // Red plays 1 at (0,0)

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
      // Simulate a game
      // We need to fill 20 spots.
      // Board has 21 spots.
      // Let's just fill them sequentially for simplicity in this test,
      // skipping one to be the black hole.

      final spots = engine.board.grid.keys.toList();
      // Leave the last one empty
      for (int i = 0; i < 20; i++) {
        engine.placePiece(spots[i].$1, spots[i].$2);
      }

      expect(engine.isGameOver, true);
      expect(engine.getBlackHole(), spots[20]);
    });

    test('Scoring calculation', () {
      // Let's set up a specific scenario around a black hole.
      // Suppose Black Hole is at (1, 0).
      // Neighbors are (0,0), (0,1) [invalid], (1,-1) [invalid], (1,1), (2,0), (2,1).
      // Valid neighbors for (1,0) in our grid:
      // (0,0) - Top Left (if exists)
      // (0,1) - Top Right (if exists) - Wait, (0,1) is not valid for row 0 (only 0,0).
      // Let's check getNeighbors logic first.

      // Grid structure:
      // R0: (0,0)
      // R1: (1,0), (1,1)
      // R2: (2,0), (2,1), (2,2)

      // Neighbors of (1,0):
      // Top-Left: (0,-1) X
      // Top-Right: (0,0) OK
      // Left: (1,-1) X
      // Right: (1,1) OK
      // Bottom-Left: (2,0) OK
      // Bottom-Right: (2,1) OK

      // So neighbors of (1,0) are (0,0), (1,1), (2,0), (2,1).

      // Let's manually place pieces to test scoring.
      // We can't easily manually place with engine.placePiece because it enforces order.
      // But we can access board.grid directly for setup in test? No, grid is final but mutable map.

      final testBoard = Board();
      // Neighbors of (1,0):
      testBoard.grid[(0, 0)] = const Piece(owner: Player.red, value: 5);
      testBoard.grid[(1, 1)] = const Piece(owner: Player.blue, value: 3);
      testBoard.grid[(2, 0)] = const Piece(owner: Player.red, value: 2);
      testBoard.grid[(2, 1)] = const Piece(owner: Player.blue, value: 4);

      // We need to inject this board into engine or just test calculation logic if we extract it.
      // Since GameEngine creates its own board, we might need to mock or just play out a game.
      // Or, for this test, we can just use the Board class directly if we move scoring there?
      // Scoring is in GameEngine.

      // Let's just play out a game where we control placement to surround the last spot.
      // This is tedious.
      // Alternative: Make Board.grid accessible or settable? It is accessible.

      engine.board.grid[(0, 0)] = const Piece(owner: Player.red, value: 5);
      engine.board.grid[(1, 1)] = const Piece(owner: Player.blue, value: 3);
      engine.board.grid[(2, 0)] = const Piece(owner: Player.red, value: 2);
      engine.board.grid[(2, 1)] = const Piece(owner: Player.blue, value: 4);

      // Force game over state
      engine.nextValue[Player.red] = 11;
      engine.nextValue[Player.blue] = 11;

      // Ensure (1,0) is empty (it is by default) and others are filled (we only filled neighbors).
      // The getBlackHole checks for the *single* empty spot.
      // So we need to fill ALL other spots.
      for (final key in engine.board.grid.keys) {
        if (key == (1, 0)) continue;
        if (engine.board.grid[key] == null) {
          engine.board.grid[key] = const Piece(
            owner: Player.red,
            value: 1,
          ); // Filler
        }
      }

      // Now (1,0) is the black hole.
      // Neighbors of (1,0) are (0,0) [R5], (1,1) [B3], (2,0) [R2], (2,1) [B4].
      // Red sum: 5 + 2 = 7.
      // Blue sum: 3 + 4 = 7.

      final scores = engine.calculateScores();
      expect(scores[Player.red], 7);
      expect(scores[Player.blue], 7);
      expect(engine.getWinner(), null); // Draw

      // Change one value to break tie
      engine.board.grid[(0, 0)] = const Piece(
        owner: Player.red,
        value: 1,
      ); // Red sum now 1+2=3.
      final scores2 = engine.calculateScores();
      expect(scores2[Player.red], 3);
      expect(scores2[Player.blue], 7);
      expect(engine.getWinner(), Player.red); // Lower score wins
    });
  });
}
