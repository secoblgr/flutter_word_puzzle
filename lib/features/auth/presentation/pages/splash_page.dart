import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/features/auth/presentation/bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Trigger auth check once the widget is ready.
    Future.microtask(() {
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthCheckRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthUnauthenticated || state is AuthError) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive(context).maxContentWidth,
            ),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.extension_rounded,
                size: 96,
                color: AppColors.primary,
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
              const SizedBox(height: 48),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
