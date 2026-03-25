import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:word_puzzle/core/usecases/usecase.dart';
import 'package:word_puzzle/features/auth/domain/entities/user_entity.dart';
import 'package:word_puzzle/features/auth/domain/usecases/get_current_user.dart';
import 'package:word_puzzle/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:word_puzzle/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:word_puzzle/features/auth/domain/usecases/sign_out.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on app start to check whether a user session already exists.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Fired when the user taps the Google Sign-In button.
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Fired when the user taps the Guest Login button.
class AuthAnonymousSignInRequested extends AuthEvent {
  const AuthAnonymousSignInRequested();
}

/// Fired when the user requests to sign out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogle _signInWithGoogle;
  final SignInAnonymously _signInAnonymously;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;

  AuthBloc({
    required SignInWithGoogle signInWithGoogle,
    required SignInAnonymously signInAnonymously,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
  })  : _signInWithGoogle = signInWithGoogle,
        _signInAnonymously = signInAnonymously,
        _signOut = signOut,
        _getCurrentUser = getCurrentUser,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthAnonymousSignInRequested>(_onAnonymousSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _getCurrentUser(NoParams());

    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signInWithGoogle(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAnonymousSignInRequested(
    AuthAnonymousSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signInAnonymously(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signOut(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }
}
