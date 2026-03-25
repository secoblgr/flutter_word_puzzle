import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/features/auth/presentation/bloc/auth_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthCheckRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive(context).maxContentWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(s),
                    const SizedBox(height: 28),
                    _buildStatsBar(s),
                    const SizedBox(height: 28),
                    _buildPlayButton(s),
                    const SizedBox(height: 20),
                    _buildMenuRow(s),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header — avatar, name, logout
  // ---------------------------------------------------------------------------

  Widget _buildHeader(AppStrings s) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String name = 'Player';
        String? photoUrl;

        if (state is AuthAuthenticated) {
          name = state.user.name;
          photoUrl = state.user.photoUrl;
        }

        return Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(photoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(name)),
                    )
                  : _avatarFallback(name),
            ),
            const SizedBox(width: 14),
            // Greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.welcomeBack,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Language toggle
            Consumer<AppLanguageNotifier>(
              builder: (context, langNotifier, _) {
                final lang = langNotifier.language;
                return GestureDetector(
                  onTap: () => langNotifier.toggle(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        lang.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // Logout
            GestureDetector(
              onTap: () =>
                  context.read<AuthBloc>().add(AuthSignOutRequested()),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.white38, size: 20),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
      },
    );
  }

  Widget _avatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'P',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats bar — score & total level
  // ---------------------------------------------------------------------------

  Widget _buildStatsBar(AppStrings s) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        int score = 0;
        int totalLevel = 0;

        if (state is AuthAuthenticated) {
          score = state.user.score;
          // Sum all category levels.
          if (state.user.categoryLevels.isNotEmpty) {
            totalLevel = state.user.categoryLevels.values
                .fold(0, (sum, lv) => sum + lv);
          } else {
            totalLevel = state.user.level;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.secondary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              // Score
              Expanded(
                child: _StatItem(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.timerWarning,
                  label: s.totalScore,
                  value: _formatNumber(score),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              // Total levels
              Expanded(
                child: _StatItem(
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.secondary,
                  label: s.totalLevels,
                  value: '$totalLevel',
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1);
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  // ---------------------------------------------------------------------------
  // Play button — main CTA
  // ---------------------------------------------------------------------------

  Widget _buildPlayButton(AppStrings s) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            final uid = state is AuthAuthenticated ? state.user.id : '';
            final catLevels =
                state is AuthAuthenticated ? state.user.categoryLevels : <String, int>{};
            final lang = context.read<AppLanguageNotifier>().language.name;
            context.go('/categories', extra: {
              'userId': uid,
              'categoryLevels': catLevels,
              'language': lang,
            });
          },
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF8B7AFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                const SizedBox(width: 8),
                Text(
                  s.playGame,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.15);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Menu row — Duel, Leaderboard, Friends
  // ---------------------------------------------------------------------------

  Widget _buildMenuRow(AppStrings s) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final uid = state is AuthAuthenticated ? state.user.id : '';

        final items = [
          _QuickAction(
            icon: Icons.sports_esports_rounded,
            label: s.duel,
            color: AppColors.secondary,
            onTap: () => context.go('/duel', extra: {'userId': uid}),
          ),
          _QuickAction(
            icon: Icons.leaderboard_rounded,
            label: s.rankings,
            color: const Color(0xFFFF9800),
            onTap: () => context.go('/leaderboard'),
          ),
          _QuickAction(
            icon: Icons.people_rounded,
            label: s.friends,
            color: AppColors.accent,
            onTap: () => context.go('/friends', extra: {'userId': uid}),
          ),
        ];

        return Row(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 6,
                  right: index == items.length - 1 ? 0 : 6,
                ),
                child: GestureDetector(
                  onTap: item.onTap,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              Icon(item.icon, color: item.color, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: (300 + 100 * index).ms, duration: 350.ms)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      delay: (300 + 100 * index).ms,
                      duration: 350.ms,
                    ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Helper widgets
// -----------------------------------------------------------------------------

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
