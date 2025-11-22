enum Player {
  red,
  blue;

  Player get opponent => this == Player.red ? Player.blue : Player.red;
}

class Piece {
  final Player owner;
  final int value;

  const Piece({required this.owner, required this.value});

  @override
  String toString() => '${owner.name.toUpperCase()} $value';
}

class Board {
  final Map<(int, int), Piece?> grid;

  Board() : grid = _createInitialGrid();

  static Map<(int, int), Piece?> _createInitialGrid() {
    final map = <(int, int), Piece?>{};
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col <= row; col++) {
        map[(row, col)] = null;
      }
    }
    return map;
  }

  bool isValidPosition(int row, int col) {
    return grid.containsKey((row, col));
  }

  bool isSpotEmpty(int row, int col) {
    return grid[(row, col)] == null;
  }

  void placePiece(int row, int col, Piece piece) {
    if (!isValidPosition(row, col)) {
      throw ArgumentError('Invalid position ($row, $col)');
    }
    if (!isSpotEmpty(row, col)) {
      throw StateError('Spot ($row, $col) is not empty');
    }
    grid[(row, col)] = piece;
  }

  List<(int, int)> getNeighbors(int row, int col) {
    final potentialNeighbors = [
      (row - 1, col - 1),
      (row - 1, col),
      (row, col - 1),
      (row, col + 1),
      (row + 1, col),
      (row + 1, col + 1),
    ];

    return potentialNeighbors.where((pos) => grid.containsKey(pos)).toList();
  }
}
