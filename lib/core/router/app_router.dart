import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:word_puzzle/features/auth/presentation/pages/splash_page.dart';
import 'package:word_puzzle/features/auth/presentation/pages/login_page.dart';
import 'package:word_puzzle/features/game/presentation/pages/category_select_page.dart';
import 'package:word_puzzle/features/game/presentation/pages/game_page.dart';
import 'package:word_puzzle/features/game/presentation/pages/result_page.dart';
import 'package:word_puzzle/features/leaderboard/presentation/pages/leaderboard_page.dart';
import 'package:word_puzzle/features/friends/presentation/pages/friends_page.dart';
import 'package:word_puzzle/features/duel/presentation/pages/duel_lobby_page.dart';
import 'package:word_puzzle/features/duel/presentation/pages/duel_room_page.dart';
import 'package:word_puzzle/features/home/presentation/pages/home_page.dart';
import 'package:word_puzzle/features/auth/presentation/pages/profile_page.dart';

class AppRouter {
  AppRouter._();

  /// Global navigator key for showing overlays (duel invite popups, etc.)
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return CategorySelectPage(
            userId: args['userId'] as String? ?? '',
            categoryLevels: Map<String, int>.from(
              args['categoryLevels'] as Map? ?? {},
            ),
            language: args['language'] as String? ?? 'en',
          );
        },
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return GamePage(
            level: args['level'] as int? ?? 1,
            userId: args['userId'] as String? ?? '',
            category: args['category'] as String? ?? 'animals',
            language: args['language'] as String? ?? 'en',
          );
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return ResultPage(
            totalScore: args['totalScore'] as int? ?? 0,
            level: args['level'] as int? ?? 1,
            timeTaken: args['timeTaken'] as int? ?? 0,
            userId: args['userId'] as String? ?? '',
            category: args['category'] as String? ?? 'animals',
            language: args['language'] as String? ?? 'en',
          );
        },
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardPage(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          final userId = args['userId'] as String? ?? '';
          return FriendsPage(userId: userId);
        },
      ),
      GoRoute(
        path: '/duel',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          final userId = args['userId'] as String? ?? '';
          return DuelLobbyPage(userId: userId);
        },
      ),
      GoRoute(
        path: '/duel/room',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return DuelRoomPage(
            duelId: args['duelId'] as String? ?? '',
            userId: args['userId'] as String? ?? '',
          );
        },
      ),
    ],
  );
}
