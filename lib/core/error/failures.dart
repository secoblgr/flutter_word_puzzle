import 'package:equatable/equatable.dart';

/// Base failure class for the application.
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error occurred'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error occurred'});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication failed'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class GameFailure extends Failure {
  const GameFailure({super.message = 'Game error occurred'});
}

class DuelFailure extends Failure {
  const DuelFailure({super.message = 'Duel error occurred'});
}
