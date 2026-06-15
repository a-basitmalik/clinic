import 'package:flutter/material.dart';
import '../../models/dashboard_stat_model.dart';
import '../constants/app_colors.dart';
import 'dashboard_card.dart';
import 'premium_surface.dart';

class DashboardQuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardQuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class PremiumDashboardOverview extends StatelessWidget {
  final String eyebrow;
  final String headline;
  final String? description;
  final IconData heroIcon;
  final List<DashboardStat> stats;
  final List<DashboardQuickAction> actions;

  const PremiumDashboardOverview({
    super.key,
    required this.eyebrow,
    required this.headline,
    required this.heroIcon,
    required this.stats,
    this.description,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final wideIndex = stats.indexWhere(_isWideMetric);
    final wideMetric = wideIndex < 0 ? null : stats[wideIndex];
    final tiles = [
      for (var i = 0; i < stats.length; i++)
        if (i != wideIndex) stats[i],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroBanner(
          eyebrow: eyebrow,
          headline: headline,
          description: description,
          icon: heroIcon,
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          primary: false,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisExtent: 126,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: tiles.length,
          itemBuilder: (_, i) => DashboardCard(stat: tiles[i]),
        ),
        if (wideMetric != null) ...[
          const SizedBox(height: 12),
          _WideMetricCard(stat: wideMetric),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _SectionLabel(
            title: 'Quick Actions',
            trailing: Text(
              'View All  ›',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < actions.take(3).length; i++) ...[
                  if (i > 0) const SizedBox(width: 7),
                  Expanded(child: _ActionPill(action: actions[i])),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool _isWideMetric(DashboardStat stat) {
    final title = stat.title.toLowerCase();
    return title.contains('revenue') ||
        title.contains('earning') ||
        title.contains('sales') ||
        title.contains('collected');
  }
}

class PremiumDashboardSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const PremiumDashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title: title, trailing: trailing),
        const SizedBox(height: 10),
        GlassPanel(
          radius: 22,
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String eyebrow;
  final String headline;
  final String? description;
  final IconData icon;

  const _HeroBanner({
    required this.eyebrow,
    required this.headline,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 24,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 154,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: const CustomPaint(painter: _HeroGlowPainter()),
              ),
            ),
            Positioned(
              left: 20,
              top: 20,
              right: 184,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    headline,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      height: 1.12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.6,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 9),
                    Container(
                      width: 130,
                      height: 1,
                      color: Colors.white.withValues(alpha: .84),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 17,
              right: 14,
              bottom: 17,
              width: 174,
              child: _AnalyticsIllustration(icon: icon),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsIllustration extends StatelessWidget {
  final IconData icon;

  const _AnalyticsIllustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 2,
          left: 0,
          right: 18,
          bottom: 22,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .88),
                  AppColors.primaryLight.withValues(alpha: .17),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .92)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: CustomPaint(painter: _AnalyticsPainter()),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .84),
              border: Border.all(
                color: Colors.white.withValues(alpha: .96),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .18),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CustomPaint(
                painter: _DonutPainter(),
                child: Center(
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .82),
                    ),
                    child: Icon(icon, size: 14, color: AppColors.primaryDark),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 5,
          top: 13,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .30),
                  blurRadius: 12,
                ),
              ],
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
          ),
        ),
      ],
    );
  }
}

class _WideMetricCard extends StatelessWidget {
  final DashboardStat stat;

  const _WideMetricCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return ColoredGlassCard(
      color: stat.color,
      radius: 23,
      padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: .92),
                    stat.color.withValues(alpha: .15),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: .92)),
                boxShadow: [
                  BoxShadow(
                    color: stat.color.withValues(alpha: .16),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(stat.icon, color: stat.color, size: 23),
            ),
            const SizedBox(width: 13),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    stat.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: stat.color,
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    stat.subtitle ?? 'Current performance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _PeriodPill(),
                  const SizedBox(height: 5),
                  const Expanded(child: _MiniLineChart()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final DashboardQuickAction action;

  const _ActionPill({required this.action});

  @override
  Widget build(BuildContext context) {
    return ColoredGlassCard(
      color: action.color,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      onTap: action.onTap,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: action.color.withValues(alpha: .08),
              border: Border.all(color: Colors.white.withValues(alpha: .96)),
            ),
            child: Icon(action.icon, color: action.color, size: 17),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              action.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 8,
                height: 1.12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: action.color,
            size: 14,
          ),
        ],
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .9)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This Month',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 3),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 11,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionLabel({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -.3,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: CustomPaint(
        painter: _LineChartPainter(color: AppColors.primary),
      ),
    );
  }
}

class _HeroGlowPainter extends CustomPainter {
  const _HeroGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .44),
            AppColors.primaryLight.withValues(alpha: .18),
            Colors.white.withValues(alpha: .20),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      Offset(size.width * .28, size.height * .3),
      size.width * .33,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .75),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * .28, size.height * .3),
          radius: size.width * .33,
        )),
    );
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .62),
      size.width * .34,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primaryLight.withValues(alpha: .38),
            AppColors.primaryLight.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * .72, size.height * .62),
          radius: size.width * .34,
        )),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnalyticsPainter extends CustomPainter {
  const _AnalyticsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final points = [
      Offset(2, size.height * .42),
      Offset(size.width * .25, size.height * .25),
      Offset(size.width * .48, size.height * .42),
      Offset(size.width * .72, size.height * .18),
      Offset(size.width - 2, size.height * .28),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
    for (final point in points) {
      canvas.drawCircle(point, 2.2, Paint()..color = AppColors.primary);
    }

    final barWidth = size.width / 8;
    final heights = [size.height * .20, size.height * .34, size.height * .27];
    for (var i = 0; i < heights.length; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .17 + i * barWidth * 1.55,
          size.height - heights[i],
          barWidth,
          heights[i],
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.primaryLight],
          ).createShader(rect.outerRect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.butt;
    paint.color = AppColors.primary.withValues(alpha: .22);
    canvas.drawArc(rect.deflate(5), 0, 6.283, false, paint);
    paint.color = AppColors.primary;
    canvas.drawArc(rect.deflate(5), -1.57, 3.6, false, paint);
    paint.color = const Color(0xFFFFC66E);
    canvas.drawArc(rect.deflate(5), 2.03, 1.2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LineChartPainter extends CustomPainter {
  final Color color;

  const _LineChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * .78),
      Offset(size.width * .25, size.height * .55),
      Offset(size.width * .48, size.height * .63),
      Offset(size.width * .72, size.height * .30),
      Offset(size.width, size.height * .18),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      path.cubicTo(
        previous.dx + (current.dx - previous.dx) / 2,
        previous.dy,
        previous.dx + (current.dx - previous.dx) / 2,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .84)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    for (final point in points.skip(1)) {
      canvas.drawCircle(point, 3, Paint()..color = color);
      canvas.drawCircle(
        point,
        1.2,
        Paint()..color = Colors.white.withValues(alpha: .9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
