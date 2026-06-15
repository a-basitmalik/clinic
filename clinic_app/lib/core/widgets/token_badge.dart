import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TokenBadge extends StatelessWidget {
  final int token;
  final double size;
  final Color? color;

  const TokenBadge(this.token, {super.key, this.size = 56, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, c.withValues(alpha: .75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: .38),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: .30), width: 2),
      ),
      child: Center(
        child: Text(
          '$token',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.36,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class TokenBadgeSmall extends StatelessWidget {
  final int token;
  final Color? color;

  const TokenBadgeSmall(this.token, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withValues(alpha: .18), c.withValues(alpha: .08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: .28)),
      ),
      child: Center(
        child: Text(
          '$token',
          style: TextStyle(
            color: c,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
