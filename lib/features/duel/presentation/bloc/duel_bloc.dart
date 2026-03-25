import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:word_puzzle/features/duel/data/datasources/duel_remote_datasource.dart';
import 'package:word_puzzle/features/duel/domain/entities/duel_entity.dart';
import 'package:word_puzzle/features/duel/domain/usecases/create_duel.dart';
import 'package:word_puzzle/features/duel/domain/usecases/join_duel.dart';
import 'package:word_puzzle/features/duel/domain/usecases/submit_duel_result.dart';
import 'package:word_puzzle/features/duel/domain/usecases/watch_duel.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class DuelEvent extends Equatable {
  const DuelEvent();

  @override
  List<Object?> get props => [];
}

class DuelCreateRequested extends DuelEvent {
  final String playerId;
  const DuelCreateRequested({required this.playerId});

  @override
  List<Object?> get props => [playerId];
}

class DuelJoinRequested extends DuelEvent {
  final String duelId;
  final String playerId;
  const DuelJoinRequested({required this.duelId, required this.playerId});

  @override
  List<Object?> get props => [duelId, playerId];
}

class DuelWatchStarted extends DuelEvent {
  final String duelId;
  const DuelWatchStarted({required this.duelId});

  @override
  List<Object?> get props => [duelId];
}

class DuelResultSubmitted extends DuelEvent {
  final String duelId;
  final String playerId;
  final int score;
  final bool isFinal;
  const DuelResultSubmitted({
    required this.duelId,
    required this.playerId,
    required this.score,
    this.isFinal = false,
  });

  @override
  List<Object?> get props => [duelId, playerId, score, isFinal];
}

class DuelLoadAvailableRequested extends DuelEvent {
  const DuelLoadAvailableRequested();
}

/// Send a duel invite to a friend.
class DuelInviteSendRequested extends DuelEvent {
  final String fromId;
  final String toId;
  const DuelInviteSendRequested({required this.fromId, required this.toId});

  @override
  List<Object?> get props => [fromId, toId];
}

/// Accept a duel invite.
class DuelInviteAcceptRequested extends DuelEvent {
  final String inviteId;
  final String userId;
  const DuelInviteAcceptRequested({required this.inviteId, required this.userId});

  @override
  List<Object?> get props => [inviteId, userId];
}

/// Reject a duel invite.
class DuelInviteRejectRequested extends DuelEvent {
  final String inviteId;
  final String userId;
  const DuelInviteRejectRequested({required this.inviteId, required this.userId});

  @override
  List<Object?> get props => [inviteId, userId];
}

/// Load pending duel invites for a user.
class DuelInvitesLoadRequested extends DuelEvent {
  final String userId;
  const DuelInvitesLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Internal events for watch stream.
class _DuelUpdated extends DuelEvent {
  final DuelEntity duel;
  const _DuelUpdated(this.duel);

  @override
  List<Object?> get props => [duel];
}

class _DuelWatchError extends DuelEvent {
  final String message;
  const _DuelWatchError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class DuelState extends Equatable {
  const DuelState();

  @override
  List<Object?> get props => [];
}

class DuelInitial extends DuelState {
  const DuelInitial();
}

class DuelLoading extends DuelState {
  const DuelLoading();
}

class DuelCreated extends DuelState {
  final DuelEntity duel;
  const DuelCreated({required this.duel});

  @override
  List<Object?> get props => [duel];
}

class DuelWaiting extends DuelState {
  final DuelEntity duel;
  const DuelWaiting({required this.duel});

  @override
  List<Object?> get props => [duel];
}

class DuelPlaying extends DuelState {
  final DuelEntity duel;
  const DuelPlaying({required this.duel});

  @override
  List<Object?> get props => [duel];
}

class DuelFinished extends DuelState {
  final DuelEntity duel;
  const DuelFinished({required this.duel});

  @override
  List<Object?> get props => [duel];
}

class DuelAvailableList extends DuelState {
  final List<DuelEntity> duels;
  final List<DuelInviteModel> pendingInvites;
  const DuelAvailableList({required this.duels, this.pendingInvites = const []});

  @override
  List<Object?> get props => [duels, pendingInvites];
}

class DuelInviteSent extends DuelState {
  final String message;
  const DuelInviteSent({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Emitted when a duel invite is accepted — contains the duelId to navigate to.
class DuelInviteAccepted extends DuelState {
  final String duelId;
  const DuelInviteAccepted({required this.duelId});

  @override
  List<Object?> get props => [duelId];
}

class DuelInviteRejected extends DuelState {
  const DuelInviteRejected();
}

class DuelError extends DuelState {
  final String message;
  const DuelError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class DuelBloc extends Bloc<DuelEvent, DuelState> {
  final CreateDuel _createDuel;
  final JoinDuel _joinDuel;
  final WatchDuel _watchDuel;
  final SubmitDuelResult _submitDuelResult;

  StreamSubscription<dynamic>? _duelSubscription;

  DuelBloc({
    required CreateDuel createDuel,
    required JoinDuel joinDuel,
    required WatchDuel watchDuel,
    required SubmitDuelResult submitDuelResult,
  })  : _createDuel = createDuel,
        _joinDuel = joinDuel,
        _watchDuel = watchDuel,
        _submitDuelResult = submitDuelResult,
        super(const DuelInitial()) {
    on<DuelCreateRequested>(_onCreateRequested);
    on<DuelJoinRequested>(_onJoinRequested);
    on<DuelWatchStarted>(_onWatchStarted);
    on<DuelResultSubmitted>(_onResultSubmitted);
    on<DuelLoadAvailableRequested>(_onLoadAvailable);
    on<DuelInviteSendRequested>(_onInviteSend);
    on<DuelInviteAcceptRequested>(_onInviteAccept);
    on<DuelInviteRejectRequested>(_onInviteReject);
    on<DuelInvitesLoadRequested>(_onInvitesLoad);
    on<_DuelUpdated>(_onDuelUpdated);
    on<_DuelWatchError>(_onDuelWatchError);
  }

  Future<void> _onCreateRequested(
    DuelCreateRequested event,
    Emitter<DuelState> emit,
  ) async {
    emit(const DuelLoading());

    final wordIds = List.generate(5, (i) => 'w${i + 1}');

    final result = await _createDuel(
      CreateDuelParams(playerId: event.playerId, wordIds: wordIds),
    );

    result.fold(
      (failure) => emit(DuelError(message: failure.message)),
      (duel) {
        emit(DuelCreated(duel: duel));
        add(DuelWatchStarted(duelId: duel.id));
      },
    );
  }

  Future<void> _onJoinRequested(
    DuelJoinRequested event,
    Emitter<DuelState> emit,
  ) async {
    emit(const DuelLoading());

    final result = await _joinDuel(
      JoinDuelParams(duelId: event.duelId, playerId: event.playerId),
    );

    result.fold(
      (failure) => emit(DuelError(message: failure.message)),
      (duel) {
        emit(DuelPlaying(duel: duel));
        add(DuelWatchStarted(duelId: duel.id));
      },
    );
  }

  Future<void> _onWatchStarted(
    DuelWatchStarted event,
    Emitter<DuelState> emit,
  ) async {
    await _duelSubscription?.cancel();

    _duelSubscription = _watchDuel(event.duelId).listen(
      (either) {
        either.fold(
          (failure) => add(_DuelWatchError(failure.message)),
          (duel) => add(_DuelUpdated(duel)),
        );
      },
      onError: (error) {
        add(_DuelWatchError(error.toString()));
      },
    );
  }

  Future<void> _onResultSubmitted(
    DuelResultSubmitted event,
    Emitter<DuelState> emit,
  ) async {
    final result = await _submitDuelResult(
      SubmitDuelResultParams(
        duelId: event.duelId,
        playerId: event.playerId,
        score: event.score,
        isFinal: event.isFinal,
      ),
    );

    result.fold(
      (failure) => emit(DuelError(message: failure.message)),
      (_) {},
    );
  }

  Future<void> _onLoadAvailable(
    DuelLoadAvailableRequested event,
    Emitter<DuelState> emit,
  ) async {
    emit(const DuelLoading());

    final result = await _createDuel.repository.getAvailableDuels();

    result.fold(
      (failure) => emit(DuelError(message: failure.message)),
      (duels) => emit(DuelAvailableList(duels: duels)),
    );
  }

  // ---------------------------------------------------------------------------
  // Duel invite handlers
  // ---------------------------------------------------------------------------

  Future<void> _onInviteSend(
    DuelInviteSendRequested event,
    Emitter<DuelState> emit,
  ) async {
    final result = await _createDuel.repository.sendDuelInvite(event.fromId, event.toId);

    result.fold(
      (failure) => emit(DuelError(message: failure.message)),
      (_) => emit(const DuelInviteSent(message: 'Duel invite sent!')),
    );
  }

  Future<void> _onInviteAccept(
    DuelInviteAcceptRequested event,
    Emitter<DuelState> emit,
  ) async {
    emit(const DuelLoading());

    final result = await _createDuel.repository.acceptDuelInvite(
      event.inviteId,
      event.userId,
    );

    result.fold(
      (failure) => emit(DuelError(message: failure.message)),
      (duelId) {
        emit(DuelInviteAccepted(duelId: duelId));
      },
    );
  }

  Future<void> _onInviteReject(
    DuelInviteRejectRequested event,
    Emitter<DuelState> emit,
  ) async {
    final result = await _createDuel.repository.rejectDuelInvite(event.inviteId);

    result.fold(
      (failure) => emit(DuelError(message: failure.message)),
      (_) => emit(const DuelInviteRejected()),
    );
  }

  Future<void> _onInvitesLoad(
    DuelInvitesLoadRequested event,
    Emitter<DuelState> emit,
  ) async {
    emit(const DuelLoading());

    final duelsResult = await _createDuel.repository.getAvailableDuels();
    final invitesResult = await _createDuel.repository.getPendingDuelInvites(event.userId);

    final duels = duelsResult.fold((_) => <DuelEntity>[], (d) => d);
    final invites = invitesResult.fold((_) => <DuelInviteModel>[], (i) => i);

    emit(DuelAvailableList(duels: duels, pendingInvites: invites));
  }

  void _onDuelUpdated(
    _DuelUpdated event,
    Emitter<DuelState> emit,
  ) {
    final duel = event.duel;
    switch (duel.status) {
      case DuelStatus.waiting:
        emit(DuelWaiting(duel: duel));
      case DuelStatus.playing:
        emit(DuelPlaying(duel: duel));
      case DuelStatus.finished:
        emit(DuelFinished(duel: duel));
    }
  }

  void _onDuelWatchError(
    _DuelWatchError event,
    Emitter<DuelState> emit,
  ) {
    emit(DuelError(message: event.message));
  }

  @override
  Future<void> close() {
    _duelSubscription?.cancel();
    return super.close();
  }
}
