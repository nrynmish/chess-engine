import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../services/game_service.dart';
import '../services/chess_engine_service.dart';
import '../widgets/chess_board.dart';
import '../widgets/evaluation_bar.dart';
import '../widgets/game_controls.dart';

// ─────────────────────────────────────────────
// DEVELOPER FLAG — set to false before release
// ─────────────────────────────────────────────
const bool kDevMode = false;

// ─────────────────────────────────────────────
// BOT DEFINITIONS
// ─────────────────────────────────────────────

enum BotDifficulty { beginner, casual, intermediate, advanced, master, grandmaster }

class BotProfile {
  final String id;
  final String name;
  final String title;       // short tag, e.g. "Beginner", "GM"
  final String description;
  final BotDifficulty difficulty;
  final IconData icon;
  final Color accentColor;
  final int eloRating;
  final int engineDepth;    // Stockfish search depth
  final double errorRate;   // 0-1, chance of suboptimal move

  const BotProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.icon,
    required this.accentColor,
    required this.eloRating,
    required this.engineDepth,
    required this.errorRate,
  });
}

const List<BotProfile> kBotProfiles = [
  BotProfile(
    id: 'stockfish',
    name: 'Stockfish',
    title: 'Pro',
    description: 'Master at the job',
    difficulty: BotDifficulty.grandmaster,
    icon: Icons.child_care_rounded,
    accentColor: Color(0xFF10B981),
    eloRating: 2800,
    engineDepth: 1,
    errorRate: 0.6,
  ),

  BotProfile(
    id: 'yak',
    name: 'Yak',
    title: 'Gay',
    description: 'Master at the blowjob',
    difficulty: BotDifficulty.grandmaster,
    icon: Icons.child_care_rounded,
    accentColor: Color(0xFF10B981),
    eloRating: 800,
    engineDepth: 1,
    errorRate: 0.6,
  ),
];

// ─────────────────────────────────────────────
// BOT SELECTION SHEET
// ─────────────────────────────────────────────

class BotSelectionSheet extends StatefulWidget {
  final BotProfile? currentBot;
  const BotSelectionSheet({super.key, this.currentBot});

  @override
  State<BotSelectionSheet> createState() => _BotSelectionSheetState();
}

class _BotSelectionSheetState extends State<BotSelectionSheet> {
  late BotProfile _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentBot ?? kBotProfiles[1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.85),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHOOSE OPPONENT',
                        style: theme.textTheme.labelLarge?.copyWith(
                          letterSpacing: 3,
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select your bot',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 24,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selected ELO badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selected.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selected.accentColor.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_selected.eloRating}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _selected.accentColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'ELO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: _selected.accentColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bot list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shrinkWrap: true,
              itemCount: kBotProfiles.length,
              itemBuilder: (context, i) {
                final bot = kBotProfiles[i];
                final isSelected = _selected.id == bot.id;
                return _BotCard(
                  bot: bot,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => setState(() => _selected = bot),
                );
              },
            ),
          ),

          // Confirm button
          Padding(
            padding: EdgeInsets.fromLTRB(
              24, 12, 24, 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: TextButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selected.icon,
                      size: 18,
                      color: _selected.accentColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'PLAY AGAINST ${_selected.name.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotCard extends StatelessWidget {
  final BotProfile bot;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _BotCard({
    required this.bot,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? bot.accentColor.withOpacity(isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? bot.accentColor
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? bot.accentColor.withOpacity(0.2)
                        : (isDark ? Colors.white24 : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    bot.icon,
                    size: 26,
                    color: isSelected ? bot.accentColor : (isDark ? Colors.white54 : Colors.black38),
                  ),
                ),
                const SizedBox(width: 14),

                // Name and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            bot.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: bot.accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              bot.title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: bot.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        bot.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ELO + difficulty dots
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${bot.eloRating}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? bot.accentColor : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: List.generate(6, (i) {
                        final filled = i < bot.difficulty.index + 1;
                        return Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? bot.accentColor
                                : (isDark ? Colors.white12 : Colors.black12),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                // Selected check
                if (isSelected) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.check_circle_rounded, color: bot.accentColor, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DEV PANEL (shown only when kDevMode == true)
// ─────────────────────────────────────────────

class _DevPanel extends StatelessWidget {
  final BotProfile bot;
  final GameState state;

  const _DevPanel({required this.bot, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(isDark ? 0.9 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal_rounded, size: 14, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                'DEV PANEL',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'REMOVE BEFORE RELEASE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _devRow('Bot', '${bot.name} (${bot.title})'),
          _devRow('Engine Depth', '${bot.engineDepth}'),
          _devRow('Error Rate', '${(bot.errorRate * 100).toStringAsFixed(0)}%'),
          _devRow('Bot ELO', '${bot.eloRating}'),
          _devRow('Turn', state.currentTurn == PieceColor.white ? 'White' : 'Black'),
          _devRow('Status', state.status.name),
          //_devRow('Half-moves', '${state.halfMoveClock}'),
          //_devRow('FEN', state.fen ?? '—', mono: true, small: true),
        ],
      ),
    );
  }

  Widget _devRow(String key, String value, {bool mono = false, bool small = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              key,
              style: TextStyle(
                fontSize: small ? 9 : 10,
                color: Colors.white54,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: small ? 9 : 10,
                color: Colors.white,
                fontFamily: mono ? 'monospace' : null,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOT HEADER (shown at top of side panel)
// ─────────────────────────────────────────────

class _BotHeader extends StatelessWidget {
  final BotProfile bot;
  final bool isThinking;

  const _BotHeader({required this.bot, required this.isThinking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
      ),
      child: Row(
        children: [
          // Bot avatar
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bot.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bot.accentColor.withOpacity(0.4)),
                ),
                child: Icon(bot.icon, color: bot.accentColor, size: 24),
              ),
              if (isThinking)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bot.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bot.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bot.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: bot.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isThinking ? 'Thinking...' : '${bot.eloRating} ELO',
                    key: ValueKey(isThinking),
                    style: TextStyle(
                      fontSize: 12,
                      color: isThinking ? Colors.green : (isDark ? Colors.white54 : Colors.black45),
                      fontWeight: isThinking ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PLAYER HEADER (shows at bottom of side panel)
// ─────────────────────────────────────────────

class _PlayerHeader extends StatelessWidget {
  final bool isYourTurn;

  const _PlayerHeader({required this.isYourTurn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isYourTurn
              ? (isDark ? Colors.white54 : Colors.black54)
              : (isDark ? Colors.white12 : Colors.black12),
          width: isYourTurn ? 1.5 : 1,
        ),
        color: isYourTurn
            ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03))
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.person_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isYourTurn ? 'Your turn' : 'Waiting...',
                    key: ValueKey(isYourTurn),
                    style: TextStyle(
                      fontSize: 12,
                      color: isYourTurn
                          ? (isDark ? Colors.white70 : Colors.black54)
                          : (isDark ? Colors.white38 : Colors.black26),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isYourTurn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'YOUR TURN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GAME STATUS BANNER
// ─────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final GameStatus status;
  final PieceColor currentTurn;

  const _StatusBanner({required this.status, required this.currentTurn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? message;
    Color? color;
    IconData? icon;

    switch (status) {
      case GameStatus.check:
        message = 'CHECK!';
        color = Colors.amber;
        icon = Icons.warning_amber_rounded;
        break;
      case GameStatus.checkmate:
        message = currentTurn == PieceColor.black ? 'YOU WIN!' : 'CHECKMATE';
        color = currentTurn == PieceColor.black ? Colors.green : Colors.red;
        icon = currentTurn == PieceColor.black
            ? Icons.emoji_events_rounded
            : Icons.flag_rounded;
        break;
      case GameStatus.stalemate:
        message = 'STALEMATE — DRAW';
        color = Colors.orange;
        icon = Icons.handshake_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color!.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            message!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN GAME SCREEN
// ─────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  final String mode;

  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameService _gameService;
  late ChessEngineService _engineService;
  bool _isEngineInitialized = false;
  BotProfile _currentBot = kBotProfiles[1]; // Default: Aria (Intermediate)

  @override
  void initState() {
    super.initState();
    _gameService = GameService();
    _engineService = ChessEngineService();
    _initializeEngine();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showBotSelection());
  }

  Future<void> _initializeEngine() async {
    final initialized = await _engineService.initialize();
    if (mounted) {
      setState(() => _isEngineInitialized = initialized);
      if (!initialized && widget.mode != 'offline') {
        _showEngineError();
      }
    }
  }

  void _showEngineError() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Engine Unavailable'),
        content: const Text(
          'Chess engine could not be loaded. You can still play in offline mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBotSelection({bool isChange = false}) async {
    final result = await showModalBottomSheet<BotProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BotSelectionSheet(currentBot: _currentBot),
    );
    if (result != null) {
      setState(() => _currentBot = result);
      if (isChange) {
        // Reset game when bot is changed mid-game
        final gameState = context.read<GameState?>();
        gameState?.reset();
      }
    }
  }

  // ─── RESPONSIVE LAYOUT HELPERS ───────────────

  bool _isTabletOrDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1100;
  }

  double _boardSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (_isDesktop(context)) return (size.width * 0.55).clamp(400.0, 680.0);
    if (_isTabletOrDesktop(context)) return (size.width * 0.6).clamp(360.0, 560.0);
    // Mobile: square board fills width with some padding
    final boardPad = size.width - 32;
    return boardPad.clamp(0.0, 480.0);
  }

  // ─── BUILDS ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState()..currentMode = _getModeFromString(widget.mode),
      child: Consumer<GameState>(
        builder: (context, state, child) {
          final isTablet = _isTabletOrDesktop(context);

          return Scaffold(
            appBar: _buildAppBar(context, state),
            body: isTablet
                ? _buildTabletLayout(context, state)
                : _buildMobileLayout(context, state),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, GameState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _currentBot.icon,
              key: ValueKey(_currentBot.id),
              color: _currentBot.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _currentBot.name,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _currentBot.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _currentBot.eloRating.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _currentBot.accentColor,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (state.isEngineThinking)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        // Change bot
        IconButton(
          icon: const Icon(Icons.swap_horiz_rounded),
          tooltip: 'Change Bot',
          onPressed: () => _showBotSelection(isChange: true),
        ),
        // New game
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'New Game',
          onPressed: state.isEngineThinking
              ? null
              : () {
                  state.reset();
                  _gameService.updateEvaluation(state, _engineService);
                },
        ),
        if (kDevMode)
          IconButton(
            icon: const Icon(Icons.terminal_rounded, color: Color(0xFF6366F1)),
            tooltip: '[DEV] Toggle Panel',
            onPressed: () {
              // Toggle dev panel visibility via state or local bool
              // Wire up to your state management as needed
            },
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── TABLET / DESKTOP: Side by side layout ───

  Widget _buildTabletLayout(BuildContext context, GameState state) {
    final boardSz = _boardSize(context);
    final isDesktop = _isDesktop(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        padding: EdgeInsets.all(isDesktop ? 32 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Board column ──────────────────
            Flexible(
              flex: 3,
              child: Center(
                child: SizedBox(
                  width: boardSz,
                  height: boardSz,
                  child: ChessBoard(gameService: _gameService),
                ),
              ),
            ),

            SizedBox(width: isDesktop ? 40 : 24),

            // ── Side panel ───────────────────
            SizedBox(
              width: isDesktop ? 320 : 260,
              child: _buildSidePanel(context, state),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MOBILE: Stacked layout ──────────────────

  Widget _buildMobileLayout(BuildContext context, GameState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status banner
          _StatusBanner(status: state.status, currentTurn: state.currentTurn),

          // Bot header (compact on mobile)
          _BotHeader(
            bot: _currentBot,
            isThinking: state.isEngineThinking,
          ),

          const SizedBox(height: 12),

          // Board
          AspectRatio(
            aspectRatio: 1,
            child: ChessBoard(gameService: _gameService),
          ),

          const SizedBox(height: 12),

          // Player header
          _PlayerHeader(
            isYourTurn: state.currentTurn == PieceColor.white && !state.isEngineThinking,
          ),

          const SizedBox(height: 12),

          // Evaluation bar (horizontal on mobile)
          if (_isEngineInitialized)
            SizedBox(
              height: 40,
              child: EvaluationBar(
                evaluation: state.evaluation,
                isHorizontal: true,
              ),
            ),

          const SizedBox(height: 12),

          // Game controls
          GameControls(
            gameService: _gameService,
            engineService: _engineService,
            engineAvailable: _isEngineInitialized,
          ),

          if (kDevMode) ...[
            const SizedBox(height: 12),
            _DevPanel(bot: _currentBot, state: state),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── SIDE PANEL (tablet/desktop) ─────────────

  Widget _buildSidePanel(BuildContext context, GameState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bot header
        _BotHeader(
          bot: _currentBot,
          isThinking: state.isEngineThinking,
        ),

        const SizedBox(height: 8),

        // Status banner
        _StatusBanner(status: state.status, currentTurn: state.currentTurn),

        const SizedBox(height: 8),

        const SizedBox(height: 8),

        // Game controls
        GameControls(
          gameService: _gameService,
          engineService: _engineService,
          engineAvailable: _isEngineInitialized,
        ),

        const SizedBox(height: 8),

        // Player header
        _PlayerHeader(
          isYourTurn: state.currentTurn == PieceColor.white && !state.isEngineThinking,
        ),

        // Dev panel
        if (kDevMode) ...[
          const SizedBox(height: 12),
          _DevPanel(bot: _currentBot, state: state),
        ],
      ],
    );
  }

  GameMode _getModeFromString(String mode) {
    switch (mode) {
      case 'offline':
        return GameMode.offline;
      case 'engine':
        return GameMode.engine;
      default:
        return GameMode.offline;
    }
  }
}
