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
        color: c,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: c.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Center(
        child: Text(
          '$token',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.38,
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
        color: c.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$token',
          style: TextStyle(
            color: c,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
