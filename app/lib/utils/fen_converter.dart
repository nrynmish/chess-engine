import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/position.dart';

class FenConverter {
  static String boardToFen(GameState state) {
    final rows = <String>[];

    for (var r = 0; r < 8; r++) {
      var emptyCount = 0;
      var rowStr = '';

      for (var c = 0; c < 8; c++) {
        final piece = state.board[r][c];

        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            rowStr += '$emptyCount';
            emptyCount = 0;
          }
          rowStr += _pieceToFenChar(piece);
        }
      }

      if (emptyCount > 0) rowStr += '$emptyCount';
      rows.add(rowStr);
    }

    // Active color
    final turnChar = state.currentTurn == PieceColor.white ? 'w' : 'b';

    // Castling availability
    final cr = state.castlingRights;
    var castling = '';
    if (cr.whiteKingside) castling += 'K';
    if (cr.whiteQueenside) castling += 'Q';
    if (cr.blackKingside) castling += 'k';
    if (cr.blackQueenside) castling += 'q';
    if (castling.isEmpty) castling = '-';

    // En passant target square (algebraic notation)
    String epSquare;
    if (state.enPassantTarget != null) {
      final ep = state.enPassantTarget!;
      final file = String.fromCharCode('a'.codeUnitAt(0) + ep.col);
      final rank = (8 - ep.row).toString();
      epSquare = '$file$rank';
    } else {
      epSquare = '-';
    }

    return '${rows.join('/')} $turnChar $castling $epSquare 0 1';
  }

  static String _pieceToFenChar(Piece piece) {
    const map = {
      PieceType.pawn: 'p',
      PieceType.knight: 'n',
      PieceType.bishop: 'b',
      PieceType.rook: 'r',
      PieceType.queen: 'q',
      PieceType.king: 'k',
    };
    final ch = map[piece.type]!;
    return piece.isWhite ? ch.toUpperCase() : ch;
  }

  static void fenToBoard(String fen, GameState state) {
    final parts = fen.split(' ');
    if (parts.isEmpty) return;

    // Board
    final rows = parts[0].split('/');
    for (var r = 0; r < 8; r++) {
      var c = 0;
      for (var i = 0; i < rows[r].length; i++) {
        final char = rows[r][i];
        final emptyCount = int.tryParse(char);
        if (emptyCount != null) {
          for (var j = 0; j < emptyCount; j++) state.board[r][c + j] = null;
          c += emptyCount;
        } else {
          state.board[r][c] = _fenCharToPiece(char);
          c++;
        }
      }
    }

    // Active color
    if (parts.length > 1) {
      state.currentTurn = parts[1] == 'w' ? PieceColor.white : PieceColor.black;
    }

    // Castling rights
    if (parts.length > 2) {
      final cr = state.castlingRights;
      final castling = parts[2];
      cr.whiteKingside = castling.contains('K');
      cr.whiteQueenside = castling.contains('Q');
      cr.blackKingside = castling.contains('k');
      cr.blackQueenside = castling.contains('q');
    }

    // En passant
    if (parts.length > 3 && parts[3] != '-') {
      final ep = parts[3];
      final col = ep[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
      final row = 8 - int.parse(ep[1]);
      state.enPassantTarget = Position(row, col);
    } else {
      state.enPassantTarget = null;
    }

    state.notifyListeners();
  }

  static Piece _fenCharToPiece(String char) {
    final isWhite = char == char.toUpperCase();
    final typeChar = char.toLowerCase();

    PieceType type;
    switch (typeChar) {
      case 'p':
        type = PieceType.pawn;
        break;
      case 'n':
        type = PieceType.knight;
        break;
      case 'b':
        type = PieceType.bishop;
        break;
      case 'r':
        type = PieceType.rook;
        break;
      case 'q':
        type = PieceType.queen;
        break;
      case 'k':
        type = PieceType.king;
        break;
      default:
        throw ArgumentError('Invalid FEN character: $char');
    }

    return Piece(type, isWhite ? PieceColor.white : PieceColor.black);
  }
}
