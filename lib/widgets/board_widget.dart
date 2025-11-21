import 'package:flutter/material.dart';
import '../models.dart';
import 'piece_widget.dart';

class BoardWidget extends StatelessWidget {
  final Board board;
  final void Function(int row, int col) onSpotTap;
  final double spotSize;

  const BoardWidget({
    super.key,
    required this.board,
    required this.onSpotTap,
    this.spotSize = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    // We need to render 6 rows.
    // Row 0 has 1 item, Row 1 has 2 items, etc.
    // We will center each row.

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(row + 1, (col) {
            final piece = board.grid[(row, col)];
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: GestureDetector(
                onTap: () => onSpotTap(row, col),
                child: Container(
                  width: spotSize,
                  height: spotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[800], // Dark background for empty spots
                    border: Border.all(color: Colors.grey[600]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: piece != null
                      ? PieceWidget(piece: piece, size: spotSize)
                      : null,
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}
