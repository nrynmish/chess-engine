import 'package:flutter/material.dart';
import 'position.dart';
import 'piece.dart';

enum GameMode { offline, online, engine }

enum GameStatus {
  whiteTurn,
  blackTurn,
  engineThinking,
  check,
  checkmate,
  stalemate,
}

class CastlingRights {
  bool whiteKingside;
  bool whiteQueenside;
  bool blackKingside;
  bool blackQueenside;

  CastlingRights({
    this.whiteKingside = true,
    this.whiteQueenside = true,
    this.blackKingside = true,
    this.blackQueenside = true,
  });

  CastlingRights copy() => CastlingRights(
    whiteKingside: whiteKingside,
    whiteQueenside: whiteQueenside,
    blackKingside: blackKingside,
    blackQueenside: blackQueenside,
  );
}

class GameState extends ChangeNotifier {
  List<List<Piece?>> board;
  Position? selectedPosition;
  GameStatus status = GameStatus.whiteTurn;
  PieceColor currentTurn = PieceColor.white;
  double evaluation = 0.0;
  List<Position> validMoves = [];
  bool isEngineThinking = false;
  GameMode currentMode = GameMode.offline;

  CastlingRights castlingRights = CastlingRights();

  Position? enPassantTarget;

  Position? pendingPromotion;

  GameState() : board = _createInitialBoard();

  static List<List<Piece?>> _createInitialBoard() {
    return List.generate(8, (row) {
      return List.generate(8, (col) {
        if (row == 1) return const Piece(PieceType.pawn, PieceColor.black);
        if (row == 6) return const Piece(PieceType.pawn, PieceColor.white);
        if (row == 0 || row == 7) {
          final color = row == 0 ? PieceColor.black : PieceColor.white;
          switch (col) {
            case 0:
              return Piece(PieceType.rook, color);
            case 1:
              return Piece(PieceType.knight, color);
            case 2:
              return Piece(PieceType.bishop, color);
            case 3:
              return Piece(PieceType.queen, color);
            case 4:
              return Piece(PieceType.king, color);
            case 5:
              return Piece(PieceType.bishop, color);
            case 6:
              return Piece(PieceType.knight, color);
            case 7:
              return Piece(PieceType.rook, color);
          }
        }
        return null;
      });
    });
  }

  void reset() {
    board = GameState._createInitialBoard();
    selectedPosition = null;
    status = GameStatus.whiteTurn;
    currentTurn = PieceColor.white;
    evaluation = 0.0;
    validMoves = [];
    isEngineThinking = false;
    castlingRights = CastlingRights();
    enPassantTarget = null;
    pendingPromotion = null;
    notifyListeners();
  }

  void setMode(GameMode mode) {
    currentMode = mode;
    reset();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}
