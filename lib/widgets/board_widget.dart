import 'package:flutter/material.dart';
import '../models.dart';
import 'piece_widget.dart';

class BoardWidget extends StatefulWidget {
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
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  int? _hoveredRow;
  int? _hoveredCol;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 500;
    final isMediumScreen = screenSize.width < 800;

    double adaptiveSpotSize = widget.spotSize;
    if (isSmallScreen) {
      adaptiveSpotSize = widget.spotSize * 0.75;
    } else if (isMediumScreen) {
      adaptiveSpotSize = widget.spotSize * 0.9;
    }

    final spacing = adaptiveSpotSize * 0.15;

    return Container(
      padding: EdgeInsets.all(spacing * 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!.withValues(alpha: 0.6),
            Colors.grey[800]!.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(6, (row) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: spacing * 0.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(row + 1, (col) {
                  final piece = widget.board.grid[(row, col)];
                  final isHovered = _hoveredRow == row && _hoveredCol == col;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing * 0.5),
                    child: MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _hoveredRow = row;
                          _hoveredCol = col;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _hoveredRow = null;
                          _hoveredCol = null;
                        });
                      },
                      child: GestureDetector(
                        onTap: () => widget.onSpotTap(row, col),
                        child: AnimatedScale(
                          scale: isHovered ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: adaptiveSpotSize,
                            height: adaptiveSpotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.grey[700]!.withValues(
                                    alpha: isHovered ? 0.8 : 0.6,
                                  ),
                                  Colors.grey[900]!.withValues(
                                    alpha: isHovered ? 0.9 : 0.7,
                                  ),
                                ],
                              ),
                              border: Border.all(
                                color: isHovered
                                    ? Colors.purple.withValues(alpha: 0.8)
                                    : Colors.grey[600]!.withValues(alpha: 0.6),
                                width: isHovered ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isHovered
                                      ? Colors.purple.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.3),
                                  blurRadius: isHovered ? 12 : 4,
                                  spreadRadius: isHovered ? 1 : 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: piece != null
                                ? PieceWidget(
                                    piece: piece,
                                    size: adaptiveSpotSize,
                                  )
                                : Center(
                                    child: Container(
                                      width: adaptiveSpotSize * 0.3,
                                      height: adaptiveSpotSize * 0.3,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: isHovered ? 0.3 : 0.1,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }
}
