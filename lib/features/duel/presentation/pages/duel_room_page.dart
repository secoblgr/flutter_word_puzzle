import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/core/utils/daily_quest_manager.dart';
import 'package:word_puzzle/core/utils/score_calculator.dart';
import 'package:word_puzzle/core/utils/sound_manager.dart';
import 'package:word_puzzle/core/utils/word_scrambler.dart';
import 'package:word_puzzle/features/duel/domain/entities/duel_entity.dart';
import 'package:word_puzzle/features/duel/presentation/bloc/duel_bloc.dart';
import 'package:word_puzzle/features/game/presentation/widgets/letter_tile.dart';
import 'package:word_puzzle/features/game/presentation/widgets/timer_widget.dart';

/// Real-time 1-v-1 duel screen.
///
/// Words come from Firestore (duelWords field) so both players see
/// the same words in the same order. Score is synced to Firestore
/// in real-time after each correct answer.
class DuelRoomPage extends StatefulWidget {
  final String duelId;
  final String userId;

  const DuelRoomPage({
    super.key,
    required this.duelId,
    required this.userId,
  });

  @override
  State<DuelRoomPage> createState() => _DuelRoomPageState();
}

class _DuelRoomPageState extends State<DuelRoomPage> {
  int _remainingSeconds = AppConstants.duelTimerSeconds;
  int _score = 0;
  int _currentWordIndex = 0;
  bool _submitted = false;
  bool _timerStarted = false;
  bool _showCorrectAnim = false;
  bool _showWrongAnim = false;
  int _hintsRemaining = 3;
  bool _duelResultHandled = false;

  List<_ScrambleLetter> _scrambledLetters = [];
  List<_SelectedLetter> _selectedLetters = [];

  /// Words loaded from Firestore (same for both players).
  List<DuelWord> _words = [];
  bool _wordsLoaded = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start watching the duel for real-time updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DuelBloc>().add(DuelWatchStarted(duelId: widget.duelId));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Load words from the duel entity (fetched via Firestore watch).
  void _loadWordsFromDuel(DuelEntity duel) {
    if (_wordsLoaded) return;
    if (duel.duelWords.isEmpty) return;

    _words = duel.duelWords;
    _wordsLoaded = true;
    _scrambleCurrentWord();
  }

  void _startTimer() {
    if (_timerStarted) return;
    _timerStarted = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds == 10) {
          SoundManager.instance.playTimerWarning();
        }
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          timer.cancel();
          _submitFinalScore();
        }
      });
    });
  }

  void _scrambleCurrentWord() {
    if (_currentWordIndex >= _words.length) return;
    final word = _words[_currentWordIndex].word;
    final scrambled = WordScrambler.scramble(word);
    setState(() {
      _scrambledLetters = scrambled
          .split('')
          .map((ch) => _ScrambleLetter(letter: ch))
          .toList();
      _selectedLetters = [];
      _showCorrectAnim = false;
      _showWrongAnim = false;
    });
  }

  void _selectLetter(int index) {
    if (_scrambledLetters[index].isUsed) return;
    setState(() {
      _scrambledLetters[index] =
          _scrambledLetters[index].copyWith(isUsed: true);
      _selectedLetters.add(
        _SelectedLetter(
            letter: _scrambledLetters[index].letter, scrambledIndex: index),
      );
    });

    // Auto-check when all letters placed.
    if (_selectedLetters.length == _words[_currentWordIndex].word.length) {
      _checkAnswer();
    }
  }

  void _removeLetter(int index) {
    if (index >= _selectedLetters.length) return;
    final removed = _selectedLetters[index];
    setState(() {
      _scrambledLetters[removed.scrambledIndex] =
          _scrambledLetters[removed.scrambledIndex].copyWith(isUsed: false);
      _selectedLetters.removeAt(index);
    });
  }

  void _useHint() {
    if (_hintsRemaining <= 0) return;
    if (_currentWordIndex >= _words.length) return;

    final currentWord = _words[_currentWordIndex].word;

    // Find the next un-placed correct position.
    int targetPos = -1;
    for (int i = 0; i < currentWord.length; i++) {
      if (i < _selectedLetters.length &&
          _selectedLetters[i].letter.toUpperCase() ==
              currentWord[i].toUpperCase()) {
        continue; // Already correct at this position.
      }
      targetPos = i;
      break;
    }
    if (targetPos == -1) return; // All correct already.

    final neededChar = currentWord[targetPos].toUpperCase();

    setState(() {
      // Clear any letters at targetPos and beyond.
      while (_selectedLetters.length > targetPos) {
        final removed = _selectedLetters.removeLast();
        _scrambledLetters[removed.scrambledIndex] =
            _scrambledLetters[removed.scrambledIndex].copyWith(isUsed: false);
      }

      // Find the needed letter in scrambled pool.
      for (int i = 0; i < _scrambledLetters.length; i++) {
        if (!_scrambledLetters[i].isUsed &&
            _scrambledLetters[i].letter.toUpperCase() == neededChar) {
          _scrambledLetters[i] = _scrambledLetters[i].copyWith(isUsed: true);
          _selectedLetters.add(
            _SelectedLetter(letter: _scrambledLetters[i].letter, scrambledIndex: i),
          );
          break;
        }
      }

      _hintsRemaining--;
      SoundManager.instance.playHint();
    });

    // Auto-check if all letters placed.
    if (_selectedLetters.length == currentWord.length) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final currentWord = _words[_currentWordIndex];
    final answer = _selectedLetters.map((s) => s.letter).join();

    if (answer.toUpperCase() == currentWord.word.toUpperCase()) {
      SoundManager.instance.playCorrect();
      // Correct!
      final points = ScoreCalculator.calculate(
        remainingSeconds: _remainingSeconds,
        level: currentWord.difficulty,
      );
      setState(() {
        _score += points;
        _showCorrectAnim = true;
      });

      // Update score in Firestore immediately (real-time sync).
      _updateScoreInFirestore();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _currentWordIndex++;
          _showCorrectAnim = false;
        });

        if (_currentWordIndex >= _words.length) {
          _submitFinalScore();
        } else {
          _scrambleCurrentWord();
        }
      });
    } else {
      SoundManager.instance.playWrong();
      // Wrong — flash red and reset.
      setState(() => _showWrongAnim = true);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _showWrongAnim = false;
          for (int i = 0; i < _scrambledLetters.length; i++) {
            _scrambledLetters[i] =
                _scrambledLetters[i].copyWith(isUsed: false);
          }
          _selectedLetters.clear();
        });
      });
    }
  }

  /// Update current score in Firestore (real-time for opponent to see).
  /// This is NOT a final submission — just a live score update.
  void _updateScoreInFirestore() {
    context.read<DuelBloc>().add(
          DuelResultSubmitted(
            duelId: widget.duelId,
            playerId: widget.userId,
            score: _score,
            isFinal: false, // Just a live update, not done yet.
          ),
        );
  }

  /// Submit final score and mark player as DONE.
  /// Called when all words are solved or time runs out.
  void _submitFinalScore() {
    if (_submitted) return;
    _submitted = true;
    _timer?.cancel();

    context.read<DuelBloc>().add(
          DuelResultSubmitted(
            duelId: widget.duelId,
            playerId: widget.userId,
            score: _score,
            isFinal: true, // Player is done — mark as submitted.
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive(context).maxContentWidth,
            ),
            child: BlocConsumer<DuelBloc, DuelState>(
              listener: _blocListener,
              builder: (context, state) {
                return Stack(
                  children: [
                    _buildMainContent(context, state, s),
                    if (state is DuelFinished)
                      _buildWinnerOverlay(context, state.duel, s),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _blocListener(BuildContext context, DuelState state) {
    // Load words from duel entity.
    final duel = _extractDuel(state);
    if (duel != null) {
      _loadWordsFromDuel(duel);
    }

    // Start timer when game is playing (both players in room).
    if (state is DuelPlaying && _wordsLoaded) {
      _startTimer();
    }

    // Daily quest: duel won
    if (state is DuelFinished && !_duelResultHandled) {
      _duelResultHandled = true;
      final duel = state.duel;
      if (duel.winnerId == widget.userId) {
        DailyQuestManager.instance.onDuelWon(widget.userId);
      }
    }

    if (state is DuelError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.wrong,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }

  Widget _buildMainContent(BuildContext context, DuelState state, AppStrings s) {
    final duel = _extractDuel(state);

    // Show loading until words are loaded.
    if (!_wordsLoaded) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Loading duel...',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 4),
          _buildTopActions(context, s),
          const SizedBox(height: 8),
          _buildPlayerBar(duel, s),
          const SizedBox(height: 12),
          _buildTimer(),
          const SizedBox(height: 12),
          _buildOpponentProgress(duel, s),
          const SizedBox(height: 12),
          _buildWordProgress(),
          const SizedBox(height: 12),
          if (_currentWordIndex < _words.length && !_submitted) ...[
            _buildDefinitionCard(s),
            const Spacer(),
            _buildAnswerArea(),
            const SizedBox(height: 20),
            _buildScrambledLetters(),
            const SizedBox(height: 12),
            _buildHintButton(s),
          ] else ...[
            const Spacer(),
            _buildWaitingForOpponent(s),
            const Spacer(),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  DuelEntity? _extractDuel(DuelState state) {
    if (state is DuelWaiting) return state.duel;
    if (state is DuelPlaying) return state.duel;
    if (state is DuelFinished) return state.duel;
    if (state is DuelCreated) return state.duel;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Top actions
  // ---------------------------------------------------------------------------

  Widget _buildTopActions(BuildContext context, AppStrings s) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _showLeaveDialog(context, s),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white70, size: 20),
        ),
        const Spacer(),
        Text(s.duel,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  void _showLeaveDialog(BuildContext context, AppStrings s) {
    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.exitDuel,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(s.exitDuelConfirm,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: Text(s.cancel,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dCtx).pop();
                _timer?.cancel();
                if (!_submitted) {
                  _submitted = true;
                  context.read<DuelBloc>().add(
                        DuelResultSubmitted(
                          duelId: widget.duelId,
                          playerId: widget.userId,
                          score: 0,
                          isFinal: true,
                        ),
                      );
                }
                context.go('/home');
              },
              child: Text(s.leaveDuel,
                  style: const TextStyle(
                      color: AppColors.wrong, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Player bar
  // ---------------------------------------------------------------------------

  Widget _buildPlayerBar(DuelEntity? duel, AppStrings s) {
    final opponentScore = duel != null
        ? (widget.userId == duel.player1Id
            ? duel.player2Score
            : duel.player1Score)
        : 0;

    return Row(
      children: [
        Expanded(
          child: _playerChip(
            label: s.you,
            score: _score,
            color: AppColors.primary,
            isReady: true,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Text(s.vs,
              style: const TextStyle(
                  color: AppColors.timerWarning,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _playerChip(
            label: duel?.player2Id != null ? s.opponent : s.waiting,
            score: opponentScore,
            color: AppColors.secondary,
            isReady: duel?.player2Id != null,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _playerChip({
    required String label,
    required int score,
    required Color color,
    required bool isReady,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady
              ? color.withValues(alpha: 0.4)
              : AppColors.darkBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReady ? Icons.person_rounded : Icons.hourglass_empty_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: isReady ? 1 : 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('$score pts',
              style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  Widget _buildTimer() {
    return TimerWidget(
      remainingSeconds: _remainingSeconds,
      totalSeconds: AppConstants.duelTimerSeconds,
    );
  }

  // ---------------------------------------------------------------------------
  // Opponent real-time progress
  // ---------------------------------------------------------------------------

  Widget _buildOpponentProgress(DuelEntity? duel, AppStrings s) {
    final opponentScore = duel != null
        ? (widget.userId == duel.player1Id
            ? duel.player2Score
            : duel.player1Score)
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_rounded,
              color: Colors.white.withValues(alpha: 0.4), size: 18),
          const SizedBox(width: 8),
          Text('${s.opponentScore}: ',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          Text('$opponentScore',
              style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Word progress dots
  // ---------------------------------------------------------------------------

  Widget _buildWordProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_words.length, (i) {
        Color dotColor;
        if (i < _currentWordIndex) {
          dotColor = AppColors.correct;
        } else if (i == _currentWordIndex) {
          dotColor = AppColors.primary;
        } else {
          dotColor = AppColors.darkBorder;
        }
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Definition card
  // ---------------------------------------------------------------------------

  Widget _buildDefinitionCard(AppStrings s) {
    final word = _words[_currentWordIndex];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _showCorrectAnim
              ? AppColors.correct.withValues(alpha: 0.6)
              : _showWrongAnim
                  ? AppColors.wrong.withValues(alpha: 0.6)
                  : AppColors.darkBorder.withValues(alpha: 0.5),
          width: _showCorrectAnim || _showWrongAnim ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  color: AppColors.timerWarning, size: 20),
              const SizedBox(width: 8),
              Text(s.wordOf(_currentWordIndex + 1, _words.length),
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13)),
              const SizedBox(width: 8),
              // Difficulty indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _difficultyColor(word.difficulty)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _difficultyLabel(word.difficulty),
                  style: TextStyle(
                      color: _difficultyColor(word.difficulty),
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(word.definition,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, height: 1.4)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Color _difficultyColor(int diff) {
    if (diff <= 2) return AppColors.correct;
    if (diff <= 4) return AppColors.timerWarning;
    if (diff <= 6) return Colors.orange;
    return AppColors.wrong;
  }

  String _difficultyLabel(int diff) {
    if (diff <= 2) return 'EASY';
    if (diff <= 4) return 'MEDIUM';
    if (diff <= 6) return 'HARD';
    return 'EXPERT';
  }

  // ---------------------------------------------------------------------------
  // Answer area
  // ---------------------------------------------------------------------------

  Widget _buildAnswerArea() {
    final wordLength = _words[_currentWordIndex].word.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: List.generate(wordLength, (index) {
        if (index < _selectedLetters.length) {
          return AnswerLetterTile(
            letter: _selectedLetters[index].letter,
            onTap: () => _removeLetter(index),
          );
        }

        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _showWrongAnim
                  ? AppColors.wrong.withValues(alpha: 0.6)
                  : AppColors.darkBorder.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Hint button
  // ---------------------------------------------------------------------------

  Widget _buildHintButton(AppStrings s) {
    final hasHints = _hintsRemaining > 0;
    return GestureDetector(
      onTap: hasHints ? _useHint : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: hasHints
              ? const Color(0xFFFF9800).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasHints
                ? const Color(0xFFFF9800).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_rounded,
              size: 18,
              color: hasHints
                  ? const Color(0xFFFF9800)
                  : Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 6),
            Text(
              '${s.hint} ($_hintsRemaining)',
              style: TextStyle(
                color: hasHints
                    ? const Color(0xFFFF9800)
                    : Colors.white.withValues(alpha: 0.3),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scrambled letters
  // ---------------------------------------------------------------------------

  Widget _buildScrambledLetters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(_scrambledLetters.length, (index) {
        final sl = _scrambledLetters[index];
        return LetterTile(
          letter: sl.letter,
          isSelected: sl.isUsed,
          onTap: () => _selectLetter(index),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Waiting state
  // ---------------------------------------------------------------------------

  Widget _buildWaitingForOpponent(AppStrings s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 20),
        Text('${s.score}: $_score',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(s.waitingForOpponent,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 15)),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  // ---------------------------------------------------------------------------
  // Winner overlay
  // ---------------------------------------------------------------------------

  Widget _buildWinnerOverlay(BuildContext context, DuelEntity duel, AppStrings s) {
    final isWinner = duel.winnerId == widget.userId;
    final isDraw = duel.winnerId == null;

    final String title;
    final Color color;
    final IconData icon;

    if (isDraw) {
      title = s.draw;
      color = AppColors.timerWarning;
      icon = Icons.handshake_rounded;
    } else if (isWinner) {
      title = s.youWin;
      color = AppColors.correct;
      icon = Icons.emoji_events_rounded;
    } else {
      title = s.youLose;
      color = AppColors.wrong;
      icon = Icons.sentiment_dissatisfied_rounded;
    }

    return Container(
      color: AppColors.darkBg.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 72)
                .animate()
                .scale(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 20),
            Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 32,
                        fontWeight: FontWeight.bold))
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 16),
            Text('${duel.player1Score}  -  ${duel.player2Score}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600))
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(s.backToHome,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ---------------------------------------------------------------------------
// Local helper models
// ---------------------------------------------------------------------------

class _ScrambleLetter {
  final String letter;
  final bool isUsed;

  const _ScrambleLetter({required this.letter, this.isUsed = false});

  _ScrambleLetter copyWith({bool? isUsed}) {
    return _ScrambleLetter(letter: letter, isUsed: isUsed ?? this.isUsed);
  }
}

class _SelectedLetter {
  final String letter;
  final int scrambledIndex;

  const _SelectedLetter({required this.letter, required this.scrambledIndex});
}
