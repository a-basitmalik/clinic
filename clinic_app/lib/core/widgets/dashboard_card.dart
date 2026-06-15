import 'package:flutter/material.dart';
import '../../models/dashboard_stat_model.dart';
import '../constants/app_colors.dart';
import 'premium_surface.dart';

class DashboardCard extends StatelessWidget {
  final DashboardStat stat;

  const DashboardCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    return ColoredGlassCard(
      color: stat.color,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconTile(stat: stat),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stat.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10.5,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.more_horiz_rounded,
                    size: 16,
                    color: stat.color.withValues(alpha: .78),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                stat.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: stat.color,
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stat.subtitle ?? 'Live overview',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _ProgressLine(color: stat.color),
            ],
          );
        },
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final DashboardStat stat;

  const _IconTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .92),
            stat.color.withValues(alpha: .09),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .92)),
        boxShadow: [
          BoxShadow(
            color: stat.color.withValues(alpha: .13),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .95),
            blurRadius: 8,
            offset: const Offset(-3, -3),
          ),
        ],
      ),
      child: Icon(stat.icon, color: stat.color, size: 23),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final Color color;

  const _ProgressLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: double.infinity,
          height: 3,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .82),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth * .35,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: .48), color],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: .28),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
