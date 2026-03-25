import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/constants.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.wrong,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        builder: (context, state) {
          final lang = context.watch<AppLanguageNotifier>().language;
          final s = AppStrings(lang);
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive(context).maxContentWidth,
                ),
                child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- App Logo / Title ---
                    _buildLogo(),
                    const SizedBox(height: 64),

                    // --- Sign-In Buttons ---
                    _buildGoogleSignInButton(context, state, s),
                    const SizedBox(height: 16),
                    _buildGuestSignInButton(context, state, s),
                  ],
                ),
              ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Icon(
          Icons.extension_rounded,
          size: 80,
          color: AppColors.primary,
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.5, 0.5), delay: 200.ms),
        const SizedBox(height: 24),
        Text(
          AppConstants.appName,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.3),
        const SizedBox(height: 8),
        Text(
          'Challenge your vocabulary',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
      ],
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, AuthState state, AppStrings s) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: state is AuthLoading
            ? null
            : () => context
                .read<AuthBloc>()
                .add(const AuthGoogleSignInRequested()),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          disabledBackgroundColor: Colors.white24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        icon: Image.asset(
          'assets/images/google_logo.png',
          height: 24,
          width: 24,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.g_mobiledata_rounded,
            size: 28,
            color: Colors.red,
          ),
        ),
        label: Text(
          s.signInWithGoogle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 700.ms)
        .slideY(begin: 0.3);
  }

  Widget _buildGuestSignInButton(BuildContext context, AuthState state, AppStrings s) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: state is AuthLoading
            ? null
            : () => context
                .read<AuthBloc>()
                .add(const AuthAnonymousSignInRequested()),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: BorderSide(color: AppColors.darkBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledForegroundColor: Colors.white24,
        ),
        icon: const Icon(Icons.person_outline_rounded),
        label: Text(
          s.continueAsGuest,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 900.ms)
        .slideY(begin: 0.3);
  }
}
