import 'package:flutter/material.dart';

/// Responsive breakpoints and helper utilities.
///
/// Usage:
/// ```dart
/// final r = Responsive(context);
/// r.isMobile   // < 600
/// r.isTablet   // 600 - 1024
/// r.isDesktop  // > 1024
/// r.wp(80)     // 80% of screen width, capped at maxContentWidth
/// r.hp(50)     // 50% of screen height
/// r.fontSize(16) // scaled font
/// ```
class Responsive {
  final BuildContext context;

  const Responsive(this.context);

  double get width => MediaQuery.sizeOf(context).width;
  double get height => MediaQuery.sizeOf(context).height;

  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;

  /// Maximum content width — prevents over-stretching on large screens.
  double get maxContentWidth {
    if (isMobile) return width;
    if (isTablet) return 540;
    return 480; // Desktop: centered card-like layout.
  }

  /// Returns horizontal padding to center content on large screens.
  EdgeInsets get contentPadding {
    if (isMobile) return const EdgeInsets.symmetric(horizontal: 20);
    final side = (width - maxContentWidth) / 2;
    return EdgeInsets.symmetric(horizontal: side.clamp(20, double.infinity));
  }

  /// Percentage of width (respecting max content width).
  double wp(double percent) => maxContentWidth * percent / 100;

  /// Percentage of height.
  double hp(double percent) => height * percent / 100;

  /// Scale factor for fonts/sizes.
  double get scaleFactor {
    if (isMobile) return 1.0;
    if (isTablet) return 1.1;
    return 1.15;
  }

  /// Scaled font size.
  double fontSize(double base) => base * scaleFactor;

  /// Grid cross-axis count based on screen width.
  int get gridColumns {
    if (isMobile) return 2;
    if (isTablet) return 3;
    return 4;
  }

  /// Letter tile size.
  double get letterTileSize {
    if (isMobile) return 48;
    if (isTablet) return 56;
    return 56;
  }

  /// Answer tile size.
  double get answerTileSize {
    if (isMobile) return 44;
    if (isTablet) return 52;
    return 52;
  }

  /// Spacing between tiles.
  double get tileSpacing {
    if (isMobile) return 6;
    return 8;
  }
}

/// A wrapper widget that constrains content to [Responsive.maxContentWidth]
/// and centers it on tablet/desktop.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ResponsiveCenter({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// Scaffold wrapper that adds responsive centering + optional background.
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.backgroundColor,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive(context).maxContentWidth,
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}
