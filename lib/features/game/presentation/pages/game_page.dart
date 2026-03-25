import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/core/utils/daily_quest_manager.dart';
import 'package:word_puzzle/core/utils/sound_manager.dart';
import 'package:word_puzzle/features/game/presentation/bloc/game_bloc.dart';
import 'package:word_puzzle/features/game/presentation/widgets/letter_tile.dart';
import 'package:word_puzzle/features/game/presentation/widgets/timer_widget.dart';

/// The main game screen where users unscramble words.
class GamePage extends StatefulWidget {
  final int level;
  final String userId;
  final String category;
  final String language;

  const GamePage({
    super.key,
    required this.level,
    required this.userId,
    this.category = 'animals',
    this.language = 'en',
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _showWrongFlash = false;
  bool _timerWarningSounded = false;

  // Floating score overlay state
  OverlayEntry? _scoreOverlay;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GameBloc>().add(
              GameStarted(
                level: widget.level,
                userId: widget.userId,
                category: widget.category,
                language: widget.language,
              ),
            );
      }
    });
  }

  @override
  void dispose() {
    _scoreOverlay?.remove();
    _shakeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Floating "+N" score popup
  // ---------------------------------------------------------------------------

  void _showFloatingScore(int points) {
    _scoreOverlay?.remove();

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _FloatingScoreWidget(
        points: points,
        onDone: () {
          _scoreOverlay?.remove();
          _scoreOverlay = null;
        },
      ),
    );

    _scoreOverlay = entry;
    overlay.insert(entry);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: _blocListener,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.darkBg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive(context).maxContentWidth,
                ),
                child: _buildBody(context, state),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Listener — no SnackBars, soft transitions
  // ---------------------------------------------------------------------------

  void _blocListener(BuildContext context, GameState state) {
    // Timer warning sound at exactly 10 seconds remaining.
    if (state is GamePlaying && state.remainingTime == 10 && !_timerWarningSounded) {
      _timerWarningSounded = true;
      SoundManager.instance.playTimerWarning();
    }
    // Reset timer warning flag when a new word starts.
    if (state is GamePlaying && state.remainingTime > 10) {
      _timerWarningSounded = false;
    }

    if (state is GameWordCorrect) {
      SoundManager.instance.playCorrect();
      // Show floating score popup.
      _showFloatingScore(state.earnedPoints);

      // Auto-advance after a short delay.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (context.mounted) {
          context.read<GameBloc>().add(const GameNextWord());
        }
      });
    }

    if (state is GameWordWrong) {
      SoundManager.instance.playWrong();
      // Trigger shake + red flash, then reset.
      setState(() => _showWrongFlash = true);
      _shakeController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _showWrongFlash = false);
          Future.delayed(const Duration(milliseconds: 150), () {
            if (context.mounted) {
              context.read<GameBloc>().add(const GameResetAnswer());
            }
          });
        }
      });
    }

    if (state is GameLevelComplete) {
      SoundManager.instance.playLevelUp();
      // Daily quest: game completed
      DailyQuestManager.instance.onGameCompleted(widget.userId);
      context.go('/result', extra: {
        'totalScore': state.totalScore,
        'level': state.level,
        'timeTaken': state.timeTaken,
        'userId': widget.userId,
        'category': widget.category,
        'language': widget.language,
      });
    }

    if (state is GameError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(state.message, textAlign: TextAlign.center),
          backgroundColor: AppColors.wrong,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        ));
    }
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _buildBody(BuildContext context, GameState state) {
    if (state is GameLoading || state is GameInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is GameError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.wrong, size: 48),
            const SizedBox(height: 16),
            Text(state.message,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Builder(builder: (context) {
              final lang = context.watch<AppLanguageNotifier>().language;
              final s = AppStrings(lang);
              return ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(s.backToHome),
              );
            }),
          ],
        ),
      );
    }

    final playing = _resolvePlayingState(state, context);
    if (playing == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildTopBar(context, playing),
          const SizedBox(height: 24),
          _buildWordProgress(playing),
          const SizedBox(height: 20),
          _buildDefinitionCard(playing),
          const Spacer(),
          _buildAnswerArea(context, playing),
          const SizedBox(height: 28),
          _buildScrambledLetters(context, playing),
          const SizedBox(height: 20),
          _buildHintButton(context, playing),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  GamePlaying? _resolvePlayingState(GameState state, BuildContext context) {
    if (state is GamePlaying) return state;
    final bloc = context.read<GameBloc>();
    if (bloc.state is GamePlaying) return bloc.state as GamePlaying;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Top bar — no .animate() to prevent re-triggering
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(BuildContext context, GamePlaying state) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go('/home'),
          icon:
              const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${s.level} ${state.level}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const Spacer(),
        const Icon(Icons.star_rounded,
            color: AppColors.timerWarning, size: 20),
        const SizedBox(width: 4),
        // AnimatedSwitcher for smooth score changes.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.5),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Text(
            '${state.score}',
            key: ValueKey(state.score),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(width: 16),
        TimerWidget(remainingSeconds: state.remainingTime),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Word progress
  // ---------------------------------------------------------------------------

  Widget _buildWordProgress(GamePlaying state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(state.words.length, (index) {
        final isActive = index == state.currentWordIndex;
        final isPast = index < state.currentWordIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isPast
                ? AppColors.correct
                : isActive
                    ? AppColors.primary
                    : AppColors.darkBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Definition card — uses AnimatedSwitcher for soft transitions
  // ---------------------------------------------------------------------------

  Widget _buildDefinitionCard(GamePlaying state) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return Column(
      children: [
        Text(
          s.unscrambleTheWord,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: Container(
            key: ValueKey(state.currentWordIndex),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.darkBorder.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.timerWarning, size: 24),
                const SizedBox(height: 8),
                Text(
                  state.currentWord.definition,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Answer area — shake + red flash on wrong
  // ---------------------------------------------------------------------------

  Widget _buildAnswerArea(BuildContext context, GamePlaying state) {
    final wordLength = state.currentWord.word.length;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(state.currentWordIndex),
          constraints: const BoxConstraints(minHeight: 56),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(wordLength, (index) {
              if (index < state.selectedLetters.length) {
                final sl = state.selectedLetters[index];
                return _AnswerSlot(
                  letter: sl.letter,
                  showWrongFlash: _showWrongFlash,
                  onTap: () => context.read<GameBloc>().add(
                        GameLetterRemoved(index: index),
                      ),
                );
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _showWrongFlash
                        ? AppColors.wrong.withValues(alpha: 0.5)
                        : AppColors.darkBorder.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scrambled letters — no initial .animate() to prevent full-page re-trigger
  // ---------------------------------------------------------------------------

  Widget _buildScrambledLetters(BuildContext context, GamePlaying state) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Wrap(
        key: ValueKey(state.currentWordIndex),
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(state.scrambledLetters.length, (index) {
          final sl = state.scrambledLetters[index];
          return LetterTile(
            letter: sl.letter,
            isSelected: sl.isUsed,
            onTap: () => context.read<GameBloc>().add(
                  GameLetterSelected(letter: sl.letter, index: index),
                ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hint button — compact, minimal design
  // ---------------------------------------------------------------------------

  Widget _buildHintButton(BuildContext context, GamePlaying state) {
    final hasHints = state.hintsRemaining > 0;

    return GestureDetector(
      onTap: hasHints
          ? () {
              SoundManager.instance.playHint();
              context.read<GameBloc>().add(const GameHintRequested());
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: hasHints
              ? AppColors.timerWarning.withValues(alpha: 0.12)
              : AppColors.darkCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasHints
                ? AppColors.timerWarning.withValues(alpha: 0.3)
                : AppColors.darkBorder.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_rounded,
              size: 16,
              color: hasHints
                  ? AppColors.timerWarning
                  : Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 6),
            Text(
              '${'💡' * state.hintsRemaining}${'  ' * (3 - state.hintsRemaining)}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Floating "+N" score popup overlay
// =============================================================================

class _FloatingScoreWidget extends StatefulWidget {
  final int points;
  final VoidCallback onDone;

  const _FloatingScoreWidget({
    required this.points,
    required this.onDone,
  });

  @override
  State<_FloatingScoreWidget> createState() => _FloatingScoreWidgetState();
}

class _FloatingScoreWidgetState extends State<_FloatingScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
    ]).animate(_controller);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: const Offset(0, -0.4),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.5, end: 1.15)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _opacityAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Text(
                  '+${widget.points}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.correct,
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(
                        color: AppColors.correct.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Answer slot with red flash
// =============================================================================

class _AnswerSlot extends StatelessWidget {
  final String letter;
  final bool showWrongFlash;
  final VoidCallback? onTap;

  const _AnswerSlot({
    required this.letter,
    required this.showWrongFlash,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: showWrongFlash
              ? AppColors.wrong.withValues(alpha: 0.2)
              : AppColors.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: showWrongFlash
                ? AppColors.wrong
                : AppColors.secondary.withValues(alpha: 0.5),
            width: showWrongFlash ? 2.0 : 1.5,
          ),
          boxShadow: showWrongFlash
              ? [
                  BoxShadow(
                    color: AppColors.wrong.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: showWrongFlash ? AppColors.wrong : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
