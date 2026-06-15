import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_gradients.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -130,
            right: -90,
            child:
                _Glow(size: 400, color: AppColors.primaryLight, opacity: .14),
          ),
          const Positioned(
            top: 220,
            left: -110,
            child: _Glow(size: 340, color: AppColors.accent, opacity: .10),
          ),
          const Positioned(
            bottom: -180,
            right: -100,
            child: _Glow(size: 440, color: AppColors.accentLight, opacity: .12),
          ),
          child,
        ],
      ),
    );
  }
}

/// Standard frosted glass panel — general usage.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = AppDimensions.radiusMedium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .80),
                Colors.white.withValues(alpha: .55),
                AppColors.primarySurface.withValues(alpha: .26),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: .82),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: .08),
                blurRadius: 22,
                spreadRadius: -8,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: .92),
                blurRadius: 10,
                spreadRadius: -4,
                offset: const Offset(-3, -3),
              ),
            ],
          ),
          child: Stack(
            children: [
              child,
              Positioned(
                top: 1.5,
                left: radius * .6,
                right: radius * .6,
                child: IgnorePointer(
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: .96),
                          Colors.white.withValues(alpha: .60),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap == null
          ? panel
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: panel,
              ),
            ),
    );
  }
}

/// Glass card with a subtle color tint — used for stat/info cards.
class ColoredGlassCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;

  const ColoredGlassCard({
    super.key,
    required this.child,
    required this.color,
    this.padding,
    this.margin,
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .94),
                Colors.white.withValues(alpha: .78),
                AppColors.primarySurface.withValues(alpha: .30),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: .98),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: .07),
                blurRadius: 20,
                spreadRadius: -7,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: .88),
                blurRadius: 8,
                spreadRadius: -3,
                offset: const Offset(-3, -3),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              child,
              Positioned(
                top: 1,
                left: radius * .6,
                right: radius * .6,
                child: IgnorePointer(
                  child: Container(
                    height: 1.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: .95),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap == null
          ? w
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: w,
              ),
            ),
    );
  }
}

/// Solid gradient card for hero banners and action buttons.
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.padding,
    this.radius = 24,
    this.onTap,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final w = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: begin,
          end: end,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: .38),
            blurRadius: 32,
            spreadRadius: -8,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
    return onTap == null
        ? w
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              child: w,
            ),
          );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Glow({required this.size, required this.color, this.opacity = .18});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}
