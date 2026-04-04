import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';

/// Shows automatically when [state.pendingPromotion] is non-null.
/// Place this in your game screen's Stack, above the chess board.
class PromotionDialog extends StatelessWidget {
  final GameState state;
  final GameService gameService;

  const PromotionDialog({
    super.key,
    required this.state,
    required this.gameService,
  });

  @override
  Widget build(BuildContext context) {
    if (state.pendingPromotion == null) return const SizedBox.shrink();

    // Determine which color is promoting so we show the right piece images
    final pos = state.pendingPromotion!;
    final color = state.board[pos.row][pos.col]!.color;
    final colorCode = color == PieceColor.white ? 'w' : 'b';

    const choices = [
      PieceType.queen,
      PieceType.rook,
      PieceType.bishop,
      PieceType.knight,
    ];

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Promote pawn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: choices.map((type) {
                    final code = '${colorCode}${_typeChar(type)}';
                    return GestureDetector(
                      onTap: () => gameService.completePromotion(state, type),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Image.asset(
                          'assets/pieces/$code.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              code,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeChar(PieceType type) {
    switch (type) {
      case PieceType.queen:
        return 'q';
      case PieceType.rook:
        return 'r';
      case PieceType.bishop:
        return 'b';
      case PieceType.knight:
        return 'n';
      default:
        return 'q';
    }
  }
}
