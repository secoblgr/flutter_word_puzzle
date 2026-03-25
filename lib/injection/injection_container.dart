import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:word_puzzle/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:word_puzzle/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:word_puzzle/features/auth/domain/repositories/auth_repository.dart';
import 'package:word_puzzle/features/auth/domain/usecases/get_current_user.dart';
import 'package:word_puzzle/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:word_puzzle/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:word_puzzle/features/auth/domain/usecases/sign_out.dart';
import 'package:word_puzzle/features/auth/domain/usecases/update_user_profile.dart';
import 'package:word_puzzle/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:word_puzzle/features/game/data/datasources/game_remote_datasource.dart';
import 'package:word_puzzle/features/game/data/repositories/game_repository_impl.dart';
import 'package:word_puzzle/features/game/domain/repositories/game_repository.dart';
import 'package:word_puzzle/features/game/domain/usecases/get_words_for_level.dart';
import 'package:word_puzzle/features/game/domain/usecases/submit_score.dart';
import 'package:word_puzzle/features/game/presentation/bloc/game_bloc.dart';

import 'package:word_puzzle/features/leaderboard/data/datasources/leaderboard_remote_datasource.dart';
import 'package:word_puzzle/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'package:word_puzzle/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:word_puzzle/features/leaderboard/domain/usecases/get_leaderboard.dart';
import 'package:word_puzzle/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';

import 'package:word_puzzle/features/friends/data/datasources/friends_remote_datasource.dart';
import 'package:word_puzzle/features/friends/data/repositories/friends_repository_impl.dart';
import 'package:word_puzzle/features/friends/domain/repositories/friends_repository.dart';
import 'package:word_puzzle/features/friends/domain/usecases/get_friends.dart';
import 'package:word_puzzle/features/friends/domain/usecases/add_friend.dart';
import 'package:word_puzzle/features/friends/domain/usecases/remove_friend.dart';
import 'package:word_puzzle/features/friends/presentation/bloc/friends_bloc.dart';

import 'package:word_puzzle/features/duel/data/datasources/duel_remote_datasource.dart';
import 'package:word_puzzle/features/duel/data/repositories/duel_repository_impl.dart';
import 'package:word_puzzle/features/duel/domain/repositories/duel_repository.dart';
import 'package:word_puzzle/features/duel/domain/usecases/create_duel.dart';
import 'package:word_puzzle/features/duel/domain/usecases/join_duel.dart';
import 'package:word_puzzle/features/duel/domain/usecases/watch_duel.dart';
import 'package:word_puzzle/features/duel/domain/usecases/submit_duel_result.dart';
import 'package:word_puzzle/features/duel/presentation/bloc/duel_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ──────────────── External ────────────────
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => GoogleSignIn());

  // ──────────────── Auth ────────────────
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignIn: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignInAnonymously(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => UpdateUserProfile(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      signInWithGoogle: sl(),
      signInAnonymously: sl(),
      signOut: sl(),
      getCurrentUser: sl(),
      updateUserProfile: sl(),
    ),
  );

  // ──────────────── Game ────────────────
  sl.registerLazySingleton<GameRemoteDataSource>(
    () => GameRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<GameRepository>(
    () => GameRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetWordsForLevel(sl()));
  sl.registerLazySingleton(() => SubmitScore(sl()));

  sl.registerFactory(
    () => GameBloc(
      getWordsForLevel: sl(),
      submitScore: sl(),
      repository: sl(),
    ),
  );

  // ──────────────── Leaderboard ────────────────
  sl.registerLazySingleton<LeaderboardRemoteDataSource>(
    () => LeaderboardRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<LeaderboardRepository>(
    () => LeaderboardRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetLeaderboard(repository: sl()));

  sl.registerFactory(
    () => LeaderboardBloc(getLeaderboard: sl()),
  );

  // ──────────────── Friends ────────────────
  sl.registerLazySingleton<FriendsRemoteDataSource>(
    () => FriendsRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<FriendsRepository>(
    () => FriendsRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetFriends(sl()));
  sl.registerLazySingleton(() => AddFriend(sl()));
  sl.registerLazySingleton(() => RemoveFriend(sl()));

  sl.registerFactory(
    () => FriendsBloc(
      getFriends: sl(),
      addFriend: sl(),
      removeFriend: sl(),
      repository: sl(),
    ),
  );

  // ──────────────── Duel ────────────────
  sl.registerLazySingleton<DuelRemoteDataSource>(
    () => DuelRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<DuelRepository>(
    () => DuelRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => CreateDuel(sl()));
  sl.registerLazySingleton(() => JoinDuel(sl()));
  sl.registerLazySingleton(() => WatchDuel(sl()));
  sl.registerLazySingleton(() => SubmitDuelResult(sl()));

  sl.registerFactory(
    () => DuelBloc(
      createDuel: sl(),
      joinDuel: sl(),
      watchDuel: sl(),
      submitDuelResult: sl(),
    ),
  );
}
