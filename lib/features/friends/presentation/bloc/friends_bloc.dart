import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:word_puzzle/features/friends/data/datasources/friends_remote_datasource.dart';
import 'package:word_puzzle/features/friends/domain/entities/friend_entity.dart';
import 'package:word_puzzle/features/friends/domain/usecases/add_friend.dart';
import 'package:word_puzzle/features/friends/domain/usecases/get_friends.dart';
import 'package:word_puzzle/features/friends/domain/usecases/remove_friend.dart';
import 'package:word_puzzle/features/friends/domain/repositories/friends_repository.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class FriendsEvent extends Equatable {
  const FriendsEvent();

  @override
  List<Object?> get props => [];
}

class FriendsLoadRequested extends FriendsEvent {
  final String userId;
  const FriendsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class FriendAddRequested extends FriendsEvent {
  final String userId;
  final String friendId;
  const FriendAddRequested({required this.userId, required this.friendId});

  @override
  List<Object?> get props => [userId, friendId];
}

class FriendRemoveRequested extends FriendsEvent {
  final String userId;
  final String friendId;
  const FriendRemoveRequested({required this.userId, required this.friendId});

  @override
  List<Object?> get props => [userId, friendId];
}

class FriendsSearchRequested extends FriendsEvent {
  final String query;
  const FriendsSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

class FriendSearchByIdRequested extends FriendsEvent {
  final String friendId;
  const FriendSearchByIdRequested(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

/// Send a friend request (not add directly).
class FriendRequestSendRequested extends FriendsEvent {
  final String fromId;
  final String toId;
  const FriendRequestSendRequested({required this.fromId, required this.toId});

  @override
  List<Object?> get props => [fromId, toId];
}

/// Accept a friend request.
class FriendRequestAcceptRequested extends FriendsEvent {
  final String requestId;
  final String userId;
  final String friendId;
  const FriendRequestAcceptRequested({
    required this.requestId,
    required this.userId,
    required this.friendId,
  });

  @override
  List<Object?> get props => [requestId, userId, friendId];
}

/// Reject a friend request.
class FriendRequestRejectRequested extends FriendsEvent {
  final String requestId;
  final String userId;
  const FriendRequestRejectRequested({
    required this.requestId,
    required this.userId,
  });

  @override
  List<Object?> get props => [requestId, userId];
}

/// Load pending friend requests.
class FriendRequestsLoadRequested extends FriendsEvent {
  final String userId;
  const FriendRequestsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class FriendsState extends Equatable {
  const FriendsState();

  @override
  List<Object?> get props => [];
}

class FriendsInitial extends FriendsState {
  const FriendsInitial();
}

class FriendsLoading extends FriendsState {
  const FriendsLoading();
}

/// Main loaded state: contains friends + pending requests.
class FriendsLoaded extends FriendsState {
  final List<FriendEntity> friends;
  final List<FriendRequestModel> pendingRequests;

  const FriendsLoaded(this.friends, {this.pendingRequests = const []});

  @override
  List<Object?> get props => [friends, pendingRequests];
}

class FriendsSearchResults extends FriendsState {
  final List<FriendEntity> users;
  const FriendsSearchResults(this.users);

  @override
  List<Object?> get props => [users];
}

class FriendRequestSent extends FriendsState {
  final String message;
  const FriendRequestSent(this.message);

  @override
  List<Object?> get props => [message];
}

class FriendsError extends FriendsState {
  final String message;
  const FriendsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final GetFriends _getFriends;
  final AddFriend _addFriend;
  final RemoveFriend _removeFriend;
  final FriendsRepository _repository;

  FriendsBloc({
    required GetFriends getFriends,
    required AddFriend addFriend,
    required RemoveFriend removeFriend,
    required FriendsRepository repository,
  })  : _getFriends = getFriends,
        _addFriend = addFriend,
        _removeFriend = removeFriend,
        _repository = repository,
        super(const FriendsInitial()) {
    on<FriendsLoadRequested>(_onLoadRequested);
    on<FriendAddRequested>(_onAddRequested);
    on<FriendRemoveRequested>(_onRemoveRequested);
    on<FriendsSearchRequested>(_onSearchRequested);
    on<FriendSearchByIdRequested>(_onSearchByIdRequested);
    on<FriendRequestSendRequested>(_onSendRequest);
    on<FriendRequestAcceptRequested>(_onAcceptRequest);
    on<FriendRequestRejectRequested>(_onRejectRequest);
    on<FriendRequestsLoadRequested>(_onLoadRequests);
  }

  Future<void> _onLoadRequested(
    FriendsLoadRequested event,
    Emitter<FriendsState> emit,
  ) async {
    emit(const FriendsLoading());

    final result = await _getFriends(event.userId);
    final requestsResult = await _repository.getPendingRequests(event.userId);

    final pendingRequests = requestsResult.fold(
      (_) => <FriendRequestModel>[],
      (requests) => requests,
    );

    result.fold(
      (failure) => emit(FriendsError(failure.message)),
      (friends) => emit(FriendsLoaded(friends, pendingRequests: pendingRequests)),
    );
  }

  Future<void> _onAddRequested(
    FriendAddRequested event,
    Emitter<FriendsState> emit,
  ) async {
    emit(const FriendsLoading());

    final result = await _addFriend(
      AddFriendParams(userId: event.userId, friendId: event.friendId),
    );

    await result.fold(
      (failure) async => emit(FriendsError(failure.message)),
      (_) async {
        final loadResult = await _getFriends(event.userId);
        final requestsResult = await _repository.getPendingRequests(event.userId);
        final pendingRequests = requestsResult.fold(
          (_) => <FriendRequestModel>[],
          (r) => r,
        );
        loadResult.fold(
          (failure) => emit(FriendsError(failure.message)),
          (friends) => emit(FriendsLoaded(friends, pendingRequests: pendingRequests)),
        );
      },
    );
  }

  Future<void> _onRemoveRequested(
    FriendRemoveRequested event,
    Emitter<FriendsState> emit,
  ) async {
    emit(const FriendsLoading());

    final result = await _removeFriend(
      RemoveFriendParams(userId: event.userId, friendId: event.friendId),
    );

    await result.fold(
      (failure) async => emit(FriendsError(failure.message)),
      (_) async {
        final loadResult = await _getFriends(event.userId);
        final requestsResult = await _repository.getPendingRequests(event.userId);
        final pendingRequests = requestsResult.fold(
          (_) => <FriendRequestModel>[],
          (r) => r,
        );
        loadResult.fold(
          (failure) => emit(FriendsError(failure.message)),
          (friends) => emit(FriendsLoaded(friends, pendingRequests: pendingRequests)),
        );
      },
    );
  }

  Future<void> _onSearchRequested(
    FriendsSearchRequested event,
    Emitter<FriendsState> emit,
  ) async {
    emit(const FriendsLoading());

    final result = await _repository.searchUsers(event.query);

    result.fold(
      (failure) => emit(FriendsError(failure.message)),
      (users) => emit(FriendsSearchResults(users)),
    );
  }

  Future<void> _onSearchByIdRequested(
    FriendSearchByIdRequested event,
    Emitter<FriendsState> emit,
  ) async {
    emit(const FriendsLoading());

    final result = await _repository.findUserByCode(event.friendId);

    result.fold(
      (failure) => emit(FriendsError(failure.message)),
      (user) {
        if (user != null) {
          emit(FriendsSearchResults([user]));
        } else {
          emit(const FriendsSearchResults([]));
        }
      },
    );
  }

  Future<void> _onSendRequest(
    FriendRequestSendRequested event,
    Emitter<FriendsState> emit,
  ) async {
    final result = await _repository.sendFriendRequest(event.fromId, event.toId);

    result.fold(
      (failure) => emit(FriendsError(failure.message)),
      (_) => emit(const FriendRequestSent('Friend request sent!')),
    );
  }

  Future<void> _onAcceptRequest(
    FriendRequestAcceptRequested event,
    Emitter<FriendsState> emit,
  ) async {
    emit(const FriendsLoading());

    final result = await _repository.acceptFriendRequest(
      event.requestId,
      event.userId,
      event.friendId,
    );

    await result.fold(
      (failure) async => emit(FriendsError(failure.message)),
      (_) async {
        // Reload everything.
        add(FriendsLoadRequested(event.userId));
      },
    );
  }

  Future<void> _onRejectRequest(
    FriendRequestRejectRequested event,
    Emitter<FriendsState> emit,
  ) async {
    emit(const FriendsLoading());

    final result = await _repository.rejectFriendRequest(event.requestId);

    await result.fold(
      (failure) async => emit(FriendsError(failure.message)),
      (_) async {
        // Reload everything.
        add(FriendsLoadRequested(event.userId));
      },
    );
  }

  Future<void> _onLoadRequests(
    FriendRequestsLoadRequested event,
    Emitter<FriendsState> emit,
  ) async {
    // Just reload all friends + requests.
    add(FriendsLoadRequested(event.userId));
  }
}
