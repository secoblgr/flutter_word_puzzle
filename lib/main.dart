import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:word_puzzle/core/router/app_router.dart';
import 'package:word_puzzle/core/theme/app_theme.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/widgets/duel_invite_listener.dart';
import 'package:word_puzzle/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:word_puzzle/features/game/presentation/bloc/game_bloc.dart';
import 'package:word_puzzle/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:word_puzzle/features/friends/presentation/bloc/friends_bloc.dart';
import 'package:word_puzzle/features/duel/presentation/bloc/duel_bloc.dart';
import 'package:word_puzzle/firebase_options.dart';
import 'package:word_puzzle/injection/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.init();

  runApp(const WordPuzzleApp());
}

class WordPuzzleApp extends StatelessWidget {
  const WordPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppLanguageNotifier(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
          BlocProvider<GameBloc>(create: (_) => di.sl<GameBloc>()),
          BlocProvider<LeaderboardBloc>(create: (_) => di.sl<LeaderboardBloc>()),
          BlocProvider<FriendsBloc>(create: (_) => di.sl<FriendsBloc>()),
          BlocProvider<DuelBloc>(create: (_) => di.sl<DuelBloc>()),
        ],
        // DuelInviteListener wraps the entire app and listens for
        // incoming/accepted/rejected duel invites via Firestore real-time.
        child: DuelInviteListener(
          navigatorKey: AppRouter.navigatorKey,
          child: MaterialApp.router(
            title: 'Word Puzzle',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
  }
}
