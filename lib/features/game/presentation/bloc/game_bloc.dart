import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/core/utils/score_calculator.dart';
import 'package:word_puzzle/core/utils/word_scrambler.dart';
import 'package:word_puzzle/features/game/domain/entities/score_entity.dart';
import 'package:word_puzzle/features/game/domain/entities/word_entity.dart';
import 'package:word_puzzle/features/game/domain/repositories/game_repository.dart';
import 'package:word_puzzle/features/game/domain/usecases/get_words_for_level.dart';
import 'package:word_puzzle/features/game/domain/usecases/submit_score.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the game screen is opened for a given level.
class GameStarted extends GameEvent {
  final int level;
  final String userId;
  final String category;
  final String language;

  const GameStarted({
    required this.level,
    required this.userId,
    this.category = 'animals',
    this.language = 'en',
  });

  @override
  List<Object?> get props => [level, userId, category, language];
}

/// Fired when the player taps a letter from the scrambled set.
class GameLetterSelected extends GameEvent {
  final String letter;
  final int index;

  const GameLetterSelected({required this.letter, required this.index});

  @override
  List<Object?> get props => [letter, index];
}

/// Fired when the player taps a letter in the answer area to remove it.
class GameLetterRemoved extends GameEvent {
  final int index;

  const GameLetterRemoved({required this.index});

  @override
  List<Object?> get props => [index];
}

/// Fired when the player submits their assembled word.
class GameWordSubmitted extends GameEvent {
  const GameWordSubmitted();
}

/// Internal tick event from the countdown timer stream.
class GameTimerTicked extends GameEvent {
  final int remainingSeconds;

  const GameTimerTicked({required this.remainingSeconds});

  @override
  List<Object?> get props => [remainingSeconds];
}

/// Fired to advance to the next word after a correct/wrong animation.
class GameNextWord extends GameEvent {
  const GameNextWord();
}

/// Fired when all words have been answered or the timer runs out.
class GameCompleted extends GameEvent {
  const GameCompleted();
}

/// Fired when the player taps the hint button.
/// Reveals the next correct letter that hasn't been placed yet.
class GameHintRequested extends GameEvent {
  const GameHintRequested();
}

/// Fired after a wrong answer animation completes to reset the answer area.
class GameResetAnswer extends GameEvent {
  const GameResetAnswer();
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {
  const GameInitial();
}

class GameLoading extends GameState {
  const GameLoading();
}

class GamePlaying extends GameState {
  final List<WordEntity> words;
  final int currentWordIndex;
  final List<SelectedLetter> selectedLetters;
  final List<ScrambledLetter> scrambledLetters;
  final int remainingTime;
  final int score;
  final int level;
  final int hintsRemaining;

  const GamePlaying({
    required this.words,
    required this.currentWordIndex,
    required this.selectedLetters,
    required this.scrambledLetters,
    required this.remainingTime,
    required this.score,
    required this.level,
    this.hintsRemaining = AppConstants.maxHintsPerGame,
  });

  /// The word the player is currently trying to solve.
  WordEntity get currentWord => words[currentWordIndex];

  /// The answer string assembled so far.
  String get currentAnswer =>
      selectedLetters.map((sl) => sl.letter).join();

  GamePlaying copyWith({
    List<WordEntity>? words,
    int? currentWordIndex,
    List<SelectedLetter>? selectedLetters,
    List<ScrambledLetter>? scrambledLetters,
    int? remainingTime,
    int? score,
    int? level,
    int? hintsRemaining,
  }) {
    return GamePlaying(
      words: words ?? this.words,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      selectedLetters: selectedLetters ?? this.selectedLetters,
      scrambledLetters: scrambledLetters ?? this.scrambledLetters,
      remainingTime: remainingTime ?? this.remainingTime,
      score: score ?? this.score,
      level: level ?? this.level,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
    );
  }

  @override
  List<Object?> get props => [
        words,
        currentWordIndex,
        selectedLetters,
        scrambledLetters,
        remainingTime,
        score,
        level,
        hintsRemaining,
      ];
}

class GameWordCorrect extends GameState {
  final String word;
  final int earnedPoints;

  const GameWordCorrect({required this.word, required this.earnedPoints});

  @override
  List<Object?> get props => [word, earnedPoints];
}

class GameWordWrong extends GameState {
  const GameWordWrong();
}

class GameLevelComplete extends GameState {
  final int totalScore;
  final int level;
  final int timeTaken;

  const GameLevelComplete({
    required this.totalScore,
    required this.level,
    required this.timeTaken,
  });

  @override
  List<Object?> get props => [totalScore, level, timeTaken];
}

class GameError extends GameState {
  final String message;

  const GameError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// Helper models
// ---------------------------------------------------------------------------

/// A letter selected by the player, tracking which scrambled index it came from.
class SelectedLetter extends Equatable {
  final String letter;
  final int scrambledIndex;

  const SelectedLetter({required this.letter, required this.scrambledIndex});

  @override
  List<Object?> get props => [letter, scrambledIndex];
}

/// A letter in the scrambled set with its used/available state.
class ScrambledLetter extends Equatable {
  final String letter;
  final bool isUsed;

  const ScrambledLetter({required this.letter, this.isUsed = false});

  ScrambledLetter copyWith({bool? isUsed}) {
    return ScrambledLetter(letter: letter, isUsed: isUsed ?? this.isUsed);
  }

  @override
  List<Object?> get props => [letter, isUsed];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class GameBloc extends Bloc<GameEvent, GameState> {
  final GetWordsForLevel _getWordsForLevel;
  final SubmitScore _submitScore;
  final GameRepository _repository;

  StreamSubscription<int>? _timerSubscription;
  String _userId = '';
  String _category = 'animals';
  int _startTime = 0;

  /// Snapshot of the [GamePlaying] state preserved across transient states
  /// like [GameWordCorrect] / [GameWordWrong] so we can resume from it.
  GamePlaying? _lastPlayingState;

  GameBloc({
    required GetWordsForLevel getWordsForLevel,
    required SubmitScore submitScore,
    required GameRepository repository,
  })  : _getWordsForLevel = getWordsForLevel,
        _submitScore = submitScore,
        _repository = repository,
        super(const GameInitial()) {
    on<GameStarted>(_onGameStarted);
    on<GameLetterSelected>(_onLetterSelected);
    on<GameLetterRemoved>(_onLetterRemoved);
    on<GameWordSubmitted>(_onWordSubmitted);
    on<GameTimerTicked>(_onTimerTicked);
    on<GameNextWord>(_onNextWord);
    on<GameCompleted>(_onCompleted);
    on<GameHintRequested>(_onHintRequested);
    on<GameResetAnswer>(_onResetAnswer);
  }

  // -------------------------------------------------------------------------
  // Event handlers
  // -------------------------------------------------------------------------

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameLoading());
    _userId = event.userId;
    _category = event.category;

    final result = await _getWordsForLevel(
      GetWordsForLevelParams(
        level: event.level,
        userId: event.userId,
        category: event.category,
        language: event.language,
      ),
    );

    result.fold(
      (failure) => emit(GameError(message: failure.message)),
      (words) {
        if (words.isEmpty) {
          emit(const GameError(message: 'No words available for this level'));
          return;
        }

        final scrambled = _scrambleWord(words.first.word);
        final playingState = GamePlaying(
          words: words,
          currentWordIndex: 0,
          selectedLetters: const [],
          scrambledLetters: scrambled,
          remainingTime: AppConstants.baseTimerSeconds,
          score: 0,
          level: event.level,
          hintsRemaining: AppConstants.maxHintsPerGame,
        );

        _lastPlayingState = playingState;
        _startTime = AppConstants.baseTimerSeconds;
        emit(playingState);
        _startTimer(AppConstants.baseTimerSeconds);
      },
    );
  }

  void _onLetterSelected(
    GameLetterSelected event,
    Emitter<GameState> emit,
  ) {
    final current = _currentPlayingState;
    if (current == null) return;

    // Ignore if already used.
    if (current.scrambledLetters[event.index].isUsed) return;

    final updatedScrambled = List<ScrambledLetter>.from(current.scrambledLetters);
    updatedScrambled[event.index] =
        updatedScrambled[event.index].copyWith(isUsed: true);

    final updatedSelected = List<SelectedLetter>.from(current.selectedLetters)
      ..add(SelectedLetter(letter: event.letter, scrambledIndex: event.index));

    final newState = current.copyWith(
      selectedLetters: updatedSelected,
      scrambledLetters: updatedScrambled,
    );
    _lastPlayingState = newState;
    emit(newState);

    // Auto-check when all letters are placed.
    if (updatedSelected.length == current.currentWord.word.length) {
      add(const GameWordSubmitted());
    }
  }

  void _onLetterRemoved(
    GameLetterRemoved event,
    Emitter<GameState> emit,
  ) {
    final current = _currentPlayingState;
    if (current == null) return;
    if (event.index >= current.selectedLetters.length) return;

    final removed = current.selectedLetters[event.index];
    final updatedScrambled = List<ScrambledLetter>.from(current.scrambledLetters);
    updatedScrambled[removed.scrambledIndex] =
        updatedScrambled[removed.scrambledIndex].copyWith(isUsed: false);

    final updatedSelected = List<SelectedLetter>.from(current.selectedLetters)
      ..removeAt(event.index);

    final newState = current.copyWith(
      selectedLetters: updatedSelected,
      scrambledLetters: updatedScrambled,
    );
    _lastPlayingState = newState;
    emit(newState);
  }

  void _onWordSubmitted(
    GameWordSubmitted event,
    Emitter<GameState> emit,
  ) {
    final current = _currentPlayingState;
    if (current == null) return;

    final answer = current.currentAnswer;
    final correctWord = current.currentWord.word;

    if (answer.toUpperCase() == correctWord.toUpperCase()) {
      final points = ScoreCalculator.calculate(
        remainingSeconds: current.remainingTime,
        level: current.level,
      );

      _lastPlayingState = current.copyWith(
        score: current.score + points,
        remainingTime: (current.remainingTime + AppConstants.bonusTimePerCorrect)
            .clamp(0, 999),
      );

      emit(GameWordCorrect(word: correctWord, earnedPoints: points));
    } else {
      emit(const GameWordWrong());
    }
  }

  void _onNextWord(
    GameNextWord event,
    Emitter<GameState> emit,
  ) {
    final current = _lastPlayingState;
    if (current == null) return;

    final nextIndex = current.currentWordIndex + 1;

    if (nextIndex >= current.words.length) {
      add(const GameCompleted());
      return;
    }

    final scrambled = _scrambleWord(current.words[nextIndex].word);
    final newState = current.copyWith(
      currentWordIndex: nextIndex,
      selectedLetters: const [],
      scrambledLetters: scrambled,
    );

    _lastPlayingState = newState;
    _restartTimer(newState.remainingTime);
    emit(newState);
  }

  void _onTimerTicked(
    GameTimerTicked event,
    Emitter<GameState> emit,
  ) {
    if (event.remainingSeconds <= 0) {
      _timerSubscription?.cancel();
      add(const GameCompleted());
      return;
    }

    final current = _currentPlayingState;
    if (current == null) return;

    final newState = current.copyWith(remainingTime: event.remainingSeconds);
    _lastPlayingState = newState;
    emit(newState);
  }

  Future<void> _onCompleted(
    GameCompleted event,
    Emitter<GameState> emit,
  ) async {
    _timerSubscription?.cancel();

    final current = _lastPlayingState;
    if (current == null) return;

    final timeTaken = _startTime - current.remainingTime;

    // Submit score to backend (fire-and-forget).
    // Save level+1 so the user progresses to the next level in this category.
    _submitScore(ScoreEntity(
      userId: _userId,
      score: current.score,
      time: DateTime.now(),
      level: current.level + 1,
      category: _category,
    ));

    // Mark all words in this level as solved (fire-and-forget).
    final solvedIds = current.words.map((w) => w.id).toList();
    _repository.markWordsSolved(_userId, solvedIds);

    emit(GameLevelComplete(
      totalScore: current.score,
      level: current.level,
      timeTaken: timeTaken,
    ));
  }

  // -------------------------------------------------------------------------
  // Reset answer (after wrong attempt)
  // -------------------------------------------------------------------------

  void _onResetAnswer(
    GameResetAnswer event,
    Emitter<GameState> emit,
  ) {
    final current = _currentPlayingState;
    if (current == null) return;

    // Mark all scrambled letters as available again.
    final resetScrambled = current.scrambledLetters
        .map((sl) => sl.copyWith(isUsed: false))
        .toList();

    final newState = current.copyWith(
      selectedLetters: const [],
      scrambledLetters: resetScrambled,
    );
    _lastPlayingState = newState;
    emit(newState);
  }

  // -------------------------------------------------------------------------
  // Hint handler
  // -------------------------------------------------------------------------

  void _onHintRequested(
    GameHintRequested event,
    Emitter<GameState> emit,
  ) {
    final current = _currentPlayingState;
    if (current == null) return;
    if (current.hintsRemaining <= 0) return;

    final correctWord = current.currentWord.word.toUpperCase();
    final currentlyPlaced = current.selectedLetters.length;

    // Already all letters placed — nothing to hint.
    if (currentlyPlaced >= correctWord.length) return;

    // First: clear any incorrectly placed letters from the answer.
    // Check if the currently placed letters match the correct prefix.
    // If they don't, clear them all so the hint starts fresh.
    var workingSelected = List<SelectedLetter>.from(current.selectedLetters);
    var workingScrambled = List<ScrambledLetter>.from(current.scrambledLetters);

    // Verify existing placements are correct, if not — clear all.
    bool prefixCorrect = true;
    for (int i = 0; i < workingSelected.length; i++) {
      if (workingSelected[i].letter.toUpperCase() != correctWord[i]) {
        prefixCorrect = false;
        break;
      }
    }

    if (!prefixCorrect) {
      // Reset all placed letters back to scrambled pool.
      for (final sel in workingSelected) {
        workingScrambled[sel.scrambledIndex] =
            workingScrambled[sel.scrambledIndex].copyWith(isUsed: false);
      }
      workingSelected = [];
    }

    // Now find the needed letter in the scrambled pool.
    final actualNeeded = correctWord[workingSelected.length];
    int? scrambledIdx;
    for (int i = 0; i < workingScrambled.length; i++) {
      if (!workingScrambled[i].isUsed &&
          workingScrambled[i].letter.toUpperCase() == actualNeeded) {
        scrambledIdx = i;
        break;
      }
    }

    if (scrambledIdx == null) return; // Safety: letter not found.

    // Place the letter.
    workingScrambled[scrambledIdx] =
        workingScrambled[scrambledIdx].copyWith(isUsed: true);
    workingSelected.add(SelectedLetter(
      letter: workingScrambled[scrambledIdx].letter,
      scrambledIndex: scrambledIdx,
    ));

    final newState = current.copyWith(
      selectedLetters: workingSelected,
      scrambledLetters: workingScrambled,
      hintsRemaining: current.hintsRemaining - 1,
    );
    _lastPlayingState = newState;
    emit(newState);
  }

  // -------------------------------------------------------------------------
  // Timer helpers
  // -------------------------------------------------------------------------

  void _startTimer(int seconds) {
    _timerSubscription?.cancel();
    _timerSubscription = Stream.periodic(
      const Duration(seconds: 1),
      (tick) => seconds - tick - 1,
    ).listen((remaining) {
      add(GameTimerTicked(remainingSeconds: remaining));
    });
  }

  void _restartTimer(int seconds) {
    _startTimer(seconds);
  }

  // -------------------------------------------------------------------------
  // Scramble helper
  // -------------------------------------------------------------------------

  List<ScrambledLetter> _scrambleWord(String word) {
    final scrambled = WordScrambler.scramble(word);
    return scrambled
        .split('')
        .map((ch) => ScrambledLetter(letter: ch))
        .toList();
  }

  // -------------------------------------------------------------------------
  // State accessor
  // -------------------------------------------------------------------------

  /// Returns the most recent [GamePlaying] state, whether current or cached.
  GamePlaying? get _currentPlayingState {
    if (state is GamePlaying) return state as GamePlaying;
    return _lastPlayingState;
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}
