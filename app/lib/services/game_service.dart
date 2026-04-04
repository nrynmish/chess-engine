import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/position.dart';
import '../models/piece.dart';
import '../utils/move_validator.dart';
import 'chess_engine_service.dart';

class GameService {
  final MoveValidator _moveValidator = MoveValidator();

  void handleSquareTap(GameState state, int row, int col) {
    if (state.isEngineThinking) return;

    // If there is a pending promotion, ignore taps until resolved
    if (state.pendingPromotion != null) return;

    final piece = state.board[row][col];

    if (state.selectedPosition == null) {
      // Select a piece if it belongs to the current player
      if (piece != null && piece.color == state.currentTurn) {
        state.selectedPosition = Position(row, col);
        state.validMoves = _moveValidator.getLegalMoves(state, row, col);
        state.notifyListeners();
      }
    } else {
      _handleMove(state, row, col);
    }
  }

  /// Call this after a promotion dialog to complete the pending promotion.
  void completePromotion(GameState state, PieceType chosenType) {
    final pos = state.pendingPromotion;
    if (pos == null) return;

    final promotedColor = state.board[pos.row][pos.col]!.color;
    state.board[pos.row][pos.col] = Piece(chosenType, promotedColor);
    state.pendingPromotion = null;

    _finalizeMove(state);
  }

  void updateEvaluation(GameState state, ChessEngineService engineService) {
    if (engineService.isAvailable) {
      state.evaluation = engineService.evaluatePosition(state);
      state.notifyListeners();
    }
  }

  void resetGame(GameState state) => state.reset();

  // ─────────────────────────────────────────────────────────────────────────
  // INTERNAL
  // ─────────────────────────────────────────────────────────────────────────

  void _handleMove(GameState state, int toR, int toC) {
    final fromR = state.selectedPosition!.row;
    final fromC = state.selectedPosition!.col;

    // Deselect on same-square tap
    if (fromR == toR && fromC == toC) {
      state.selectedPosition = null;
      state.validMoves = [];
      state.notifyListeners();
      return;
    }

    // Re-select a different piece of the same color
    final targetPiece = state.board[toR][toC];
    if (targetPiece != null && targetPiece.color == state.currentTurn) {
      state.selectedPosition = Position(toR, toC);
      state.validMoves = _moveValidator.getLegalMoves(state, toR, toC);
      state.notifyListeners();
      return;
    }

    // Attempt the move
    if (_moveValidator.isValidMove(state, fromR, fromC, toR, toC)) {
      _applyMove(state, fromR, fromC, toR, toC);
    } else {
      state.selectedPosition = null;
      state.validMoves = [];
      state.notifyListeners();
    }
  }

  void _applyMove(GameState state, int fromR, int fromC, int toR, int toC) {
    final piece = state.board[fromR][fromC]!;

    // ── En passant capture ─────────────────────────────────────────────────
    // Detect: pawn moves diagonally to an empty square
    final isEnPassant =
        piece.type == PieceType.pawn &&
        fromC != toC &&
        state.board[toR][toC] == null;

    if (isEnPassant) {
      // Remove the captured pawn (it sits on the same rank as the moving pawn)
      state.board[fromR][toC] = null;
    }

    // ── Castling ────────────────────────────────────────────────────────────
    final isCastling = piece.type == PieceType.king && (toC - fromC).abs() == 2;

    if (isCastling) {
      if (toC == 6) {
        // Kingside: move rook from h-file to f-file
        state.board[fromR][5] = state.board[fromR][7];
        state.board[fromR][7] = null;
      } else {
        // Queenside: move rook from a-file to d-file
        state.board[fromR][3] = state.board[fromR][0];
        state.board[fromR][0] = null;
      }
    }

    // ── Move the piece ───────────────────────────────────────────────────────
    state.board[toR][toC] = state.board[fromR][fromC];
    state.board[fromR][fromC] = null;

    // ── Update castling rights ───────────────────────────────────────────────
    _updateCastlingRights(state, piece, fromR, fromC);

    // ── Update en passant target ─────────────────────────────────────────────
    // Set only when a pawn just moved two squares
    if (piece.type == PieceType.pawn && (toR - fromR).abs() == 2) {
      // The en passant target square is the square "behind" the pawn
      final epRow = (fromR + toR) ~/ 2;
      state.enPassantTarget = Position(epRow, fromC);
    } else {
      state.enPassantTarget = null;
    }

    // ── Clear selection ──────────────────────────────────────────────────────
    state.selectedPosition = null;
    state.validMoves = [];

    // ── Pawn promotion ───────────────────────────────────────────────────────
    if (piece.type == PieceType.pawn && (toR == 0 || toR == 7)) {
      state.pendingPromotion = Position(toR, toC);
      // Don't switch turns yet — wait for completePromotion()
      state.notifyListeners();
      return;
    }

    _finalizeMove(state);
  }

  /// Switch turns and compute check / checkmate / stalemate.
  void _finalizeMove(GameState state) {
    // Switch turn
    state.currentTurn = state.currentTurn == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;

    // Determine new status
    final inCheck = _moveValidator.isKingInCheck(
      state.board,
      state.currentTurn,
    );
    final hasLegal = _moveValidator.hasLegalMoves(state);

    if (!hasLegal) {
      state.status = inCheck ? GameStatus.checkmate : GameStatus.stalemate;
    } else if (inCheck) {
      state.status = GameStatus.check;
    } else {
      state.status = state.currentTurn == PieceColor.white
          ? GameStatus.whiteTurn
          : GameStatus.blackTurn;
    }

    state.notifyListeners();
  }

  void _updateCastlingRights(
    GameState state,
    Piece movedPiece,
    int fromR,
    int fromC,
  ) {
    final r = state.castlingRights;

    // King moves → lose all castling rights for that color
    if (movedPiece.type == PieceType.king) {
      if (movedPiece.isWhite) {
        r.whiteKingside = false;
        r.whiteQueenside = false;
      } else {
        r.blackKingside = false;
        r.blackQueenside = false;
      }
      return;
    }

    // Rook moves from its original square → lose that side's right
    if (movedPiece.type == PieceType.rook) {
      if (fromR == 7 && fromC == 7) r.whiteKingside = false;
      if (fromR == 7 && fromC == 0) r.whiteQueenside = false;
      if (fromR == 0 && fromC == 7) r.blackKingside = false;
      if (fromR == 0 && fromC == 0) r.blackQueenside = false;
    }
  }
}
