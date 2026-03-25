import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:word_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:word_puzzle/features/leaderboard/domain/usecases/get_leaderboard.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the leaderboard page is opened or refreshed.
class LeaderboardLoadRequested extends LeaderboardEvent {
  final int limit;

  const LeaderboardLoadRequested({this.limit = 50});

  @override
  List<Object?> get props => [limit];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardEntry> entries;

  const LeaderboardLoaded({required this.entries});

  @override
  List<Object?> get props => [entries];
}

class LeaderboardError extends LeaderboardState {
  final String message;

  const LeaderboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final GetLeaderboard _getLeaderboard;

  LeaderboardBloc({required GetLeaderboard getLeaderboard})
      : _getLeaderboard = getLeaderboard,
        super(const LeaderboardInitial()) {
    on<LeaderboardLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    LeaderboardLoadRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());

    final result = await _getLeaderboard(
      GetLeaderboardParams(limit: event.limit),
    );

    result.fold(
      (failure) => emit(LeaderboardError(message: failure.message)),
      (entries) => emit(LeaderboardLoaded(entries: entries)),
    );
  }
}
