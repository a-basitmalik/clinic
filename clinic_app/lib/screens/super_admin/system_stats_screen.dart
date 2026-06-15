import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/report_service.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/premium_surface.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../routes/app_routes.dart';

class SystemStatsScreen extends StatefulWidget {
  const SystemStatsScreen({super.key});

  @override
  State<SystemStatsScreen> createState() => _SystemStatsScreenState();
}

class _SystemStatsScreenState extends State<SystemStatsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String? _error;

  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _data = await ReportService.getSuperAdminStats();
      if (mounted) {
        setState(() => _loading = false);
        _ctrl.forward(from: 0);
      }
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'System Statistics',
      currentRoute: AppRoutes.systemStats,
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final clinics = _data['clinics'] as Map? ?? {};
    final users = _data['users'] as Map? ?? {};
    final appts = _data['appointments'] as Map? ?? {};
    final patients = _data['patients'] as Map? ?? {};
    final usersByRole = _data['users_by_role'] as Map? ?? {};

    final totalClinics = (clinics['total'] as num?)?.toInt() ?? 0;
    final approved = (clinics['approved'] as num?)?.toInt() ?? 0;
    final pending = (clinics['pending'] as num?)?.toInt() ?? 0;
    final suspended = (clinics['suspended'] as num?)?.toInt() ?? 0;
    final totalUsers = (users['total'] as num?)?.toInt() ?? 0;
    final totalDoctors = (users['doctors'] as num?)?.toInt() ?? 0;
    final totalPatients = (patients['total'] as num?)?.toInt() ?? 0;
    final totalAppts = (appts['total'] as num?)?.toInt() ?? 0;
    final todayAppts = (appts['today'] as num?)?.toInt() ?? 0;

    // Staggered KPI animations
    final kpiAnims = List.generate(4, (i) {
      final start = i * 0.07;
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, start + 0.45, curve: Curves.easeOutBack),
      );
    });

    // Charts animate from 0.30 to 1.0
    final chartAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOutCubic),
    );

    // Build donut data from role map or derived
    final Map<String, double> donutData = {};
    if (usersByRole.isNotEmpty) {
      usersByRole.forEach((k, v) {
        final count = (v as num?)?.toDouble() ?? 0;
        if (count > 0) donutData[_roleLabel(k)] = count;
      });
    } else {
      if (totalDoctors > 0) donutData['Doctors'] = totalDoctors.toDouble();
      if (totalPatients > 0) donutData['Patients'] = totalPatients.toDouble();
      final others = totalUsers - totalDoctors - totalPatients;
      if (others > 0) donutData['Others'] = others.toDouble();
    }

    final linePoints = _buildLineData(totalAppts, todayAppts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Cards row
        LayoutBuilder(builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 560;
          final kpis = [
            (
              label: 'Total Clinics',
              value: totalClinics,
              icon: Icons.local_hospital_rounded,
              colors: [AppColors.glowTeal, const Color(0xFF0D8C86)],
            ),
            (
              label: 'Total Users',
              value: totalUsers,
              icon: Icons.people_alt_rounded,
              colors: [AppColors.glowBlue, const Color(0xFF1A68CC)],
            ),
            (
              label: 'Pending Approvals',
              value: pending,
              icon: Icons.pending_actions_rounded,
              colors: [AppColors.glowGold, const Color(0xFFCC6A10)],
            ),
            (
              label: 'Today Appointments',
              value: todayAppts,
              icon: Icons.today_rounded,
              colors: [AppColors.glowEmerald, const Color(0xFF1A7A43)],
            ),
          ];

          if (isWide) {
            return Row(
              children: kpis.asMap().entries.map((entry) {
                final i = entry.key;
                final kpi = entry.value;
                return Expanded(
                  child: _KpiCard(
                    animation: kpiAnims[i],
                    label: kpi.label,
                    value: kpi.value,
                    icon: kpi.icon,
                    colors: kpi.colors,
                    margin: EdgeInsets.only(right: i < 3 ? 12 : 0),
                  ),
                );
              }).toList(),
            );
          }

          return Column(children: [
            Row(children: [
              Expanded(
                child: _KpiCard(
                  animation: kpiAnims[0],
                  label: kpis[0].label,
                  value: kpis[0].value,
                  icon: kpis[0].icon,
                  colors: kpis[0].colors,
                  margin: const EdgeInsets.only(right: 10),
                ),
              ),
              Expanded(
                child: _KpiCard(
                  animation: kpiAnims[1],
                  label: kpis[1].label,
                  value: kpis[1].value,
                  icon: kpis[1].icon,
                  colors: kpis[1].colors,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _KpiCard(
                  animation: kpiAnims[2],
                  label: kpis[2].label,
                  value: kpis[2].value,
                  icon: kpis[2].icon,
                  colors: kpis[2].colors,
                  margin: const EdgeInsets.only(right: 10),
                ),
              ),
              Expanded(
                child: _KpiCard(
                  animation: kpiAnims[3],
                  label: kpis[3].label,
                  value: kpis[3].value,
                  icon: kpis[3].icon,
                  colors: kpis[3].colors,
                ),
              ),
            ]),
          ]);
        }),

        const SizedBox(height: 20),

        // Charts 2x2 grid
        LayoutBuilder(builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 640;

          final charts = [
            _ChartPanel(
              title: 'Clinic Breakdown',
              subtitle: 'By status',
              icon: Icons.bar_chart_rounded,
              iconColors: [AppColors.glowTeal, const Color(0xFF0D8C86)],
              child: AnimatedBuilder(
                animation: chartAnim,
                builder: (_, __) => CustomPaint(
                  painter: _BarChartPainter(
                    progress: chartAnim.value,
                    bars: [
                      _Bar('Approved', approved.toDouble(),
                          AppColors.glowTeal),
                      _Bar('Pending', pending.toDouble(), AppColors.glowGold),
                      _Bar('Suspended', suspended.toDouble(),
                          AppColors.glowRose),
                    ],
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            _ChartPanel(
              title: 'User Distribution',
              subtitle: 'By role',
              icon: Icons.donut_large_rounded,
              iconColors: [AppColors.glowPurple, const Color(0xFF6B4FB0)],
              child: donutData.isNotEmpty
                  ? AnimatedBuilder(
                      animation: chartAnim,
                      builder: (_, __) => CustomPaint(
                        painter: _DonutPainter(
                          progress: chartAnim.value,
                          data: donutData,
                          colors: const [
                            AppColors.glowTeal,
                            AppColors.glowBlue,
                            AppColors.glowPurple,
                            AppColors.glowGold,
                            AppColors.glowEmerald,
                            AppColors.glowRose,
                          ],
                        ),
                        child: const SizedBox.expand(),
                      ),
                    )
                  : const Center(
                      child: Text('No role data',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
            ),
            _ChartPanel(
              title: 'Appointment Trend',
              subtitle: 'Last 7 days (estimated)',
              icon: Icons.trending_up_rounded,
              iconColors: [AppColors.glowEmerald, const Color(0xFF1A7A43)],
              child: AnimatedBuilder(
                animation: chartAnim,
                builder: (_, __) => CustomPaint(
                  painter: _LineChartPainter(
                    progress: chartAnim.value,
                    points: linePoints,
                    color: AppColors.glowEmerald,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            _ChartPanel(
              title: 'Platform Overview',
              subtitle: 'Key counts',
              icon: Icons.insights_rounded,
              iconColors: [AppColors.glowBlue, const Color(0xFF1A68CC)],
              child: AnimatedBuilder(
                animation: chartAnim,
                builder: (_, __) => CustomPaint(
                  painter: _HBarPainter(
                    progress: chartAnim.value,
                    items: [
                      _HBar('Clinics', totalClinics.toDouble(),
                          AppColors.glowTeal),
                      _HBar(
                          'Users', totalUsers.toDouble(), AppColors.glowBlue),
                      _HBar('Patients', totalPatients.toDouble(),
                          AppColors.glowPurple),
                      _HBar('Doctors', totalDoctors.toDouble(),
                          AppColors.glowEmerald),
                      _HBar(
                          'Appts', totalAppts.toDouble(), AppColors.glowGold),
                    ],
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ];

          if (isWide) {
            return Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: charts[0]),
                const SizedBox(width: 16),
                Expanded(child: charts[1]),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: charts[2]),
                const SizedBox(width: 16),
                Expanded(child: charts[3]),
              ]),
            ]);
          }

          return Column(
            children: charts.asMap().entries.map((e) {
              return Padding(
                padding:
                    EdgeInsets.only(bottom: e.key < charts.length - 1 ? 16 : 0),
                child: e.value,
              );
            }).toList(),
          );
        }),

        // Users by Role table
        if (usersByRole.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionLabel(title: 'Users by Role'),
          const SizedBox(height: 12),
          GlassPanel(
            padding: const EdgeInsets.all(4),
            child: Column(
              children:
                  usersByRole.entries.toList().asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final isLast = i == usersByRole.length - 1;
                final c = AppColors.roleColor(e.key);
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              c.withValues(alpha: .22),
                              c.withValues(alpha: .08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: c.withValues(alpha: .28)),
                        ),
                        child: Icon(Icons.person_rounded, color: c, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _roleLabel(e.key),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                                colors: [c, c.withValues(alpha: .7)])
                            .createShader(b),
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        color: AppColors.divider.withValues(alpha: .5)),
                ]);
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  List<double> _buildLineData(int total, int today) {
    if (total == 0) return List.filled(7, 0.0);
    final avg = total / 30.0;
    final pts = <double>[];
    for (int i = 6; i >= 1; i--) {
      pts.add(avg * (0.65 + 0.35 * ((6 - i) / 5.0)));
    }
    pts.add(today.toDouble());
    return pts;
  }

  String _roleLabel(String role) {
    const map = {
      'super_admin': 'Super Admin',
      'clinic_admin': 'Clinic Admin',
      'doctor': 'Doctor',
      'assistant': 'Assistant',
      'receptionist': 'Receptionist',
      'pharmacy': 'Pharmacy',
      'patient': 'Patient',
    };
    return map[role] ?? role;
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final Animation<double> animation;
  final String label;
  final int value;
  final IconData icon;
  final List<Color> colors;
  final EdgeInsetsGeometry? margin;

  const _KpiCard({
    required this.animation,
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final v = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 22),
            child: Padding(
              padding: margin ?? EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: .92),
                          Colors.white.withValues(alpha: .72),
                          colors[0].withValues(alpha: .10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .90),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withValues(alpha: .14),
                          blurRadius: 22,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: .88),
                          blurRadius: 8,
                          offset: const Offset(-2, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: colors[0].withValues(alpha: .36),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 10),
                        ShaderMask(
                          shaderCallback: (b) =>
                              LinearGradient(colors: colors).createShader(b),
                          child: Text(
                            '${(value * v).toInt()}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Chart Panel ──────────────────────────────────────────────────────────────

class _ChartPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> iconColors;
  final Widget child;

  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: iconColors[0].withValues(alpha: .32),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      )),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          SizedBox(height: 168, child: child),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.glowTeal, AppColors.glowBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          )),
    ]);
  }
}

// ─── Bar Chart Painter (Vertical) ─────────────────────────────────────────────

class _Bar {
  final String label;
  final double value;
  final Color color;
  const _Bar(this.label, this.value, this.color);
}

class _BarChartPainter extends CustomPainter {
  final double progress;
  final List<_Bar> bars;

  const _BarChartPainter({required this.progress, required this.bars});

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final maxVal = bars.map((b) => b.value).reduce(math.max);
    if (maxVal == 0) return;

    const padL = 12.0, padR = 12.0, padT = 8.0, padB = 32.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;
    final slotW = chartW / bars.length;
    final barW = slotW * 0.54;

    final paint = Paint()..style = PaintingStyle.fill;

    // Grid lines
    paint.color = AppColors.border.withValues(alpha: 0.35);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.8;
    for (int g = 1; g <= 4; g++) {
      final gy = padT + chartH * (1 - g / 4);
      canvas.drawLine(Offset(padL, gy), Offset(size.width - padR, gy), paint);
    }
    paint.style = PaintingStyle.fill;

    for (int i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final barH = (bar.value / maxVal) * chartH * progress;
      final x = padL + i * slotW + (slotW - barW) / 2;
      final y = padT + chartH - barH;

      if (barH > 0) {
        paint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bar.color, bar.color.withValues(alpha: .42)],
        ).createShader(Rect.fromLTWH(x, y, barW, barH));

        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, y, barW, barH),
            topLeft: const Radius.circular(7),
            topRight: const Radius.circular(7),
          ),
          paint,
        );
        paint.shader = null;
      }

      // Value on top of bar
      if (barH > 18 && progress > 0.55) {
        _drawText(
          canvas,
          '${bar.value.toInt()}',
          const TextStyle(
              fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w800),
          Offset(x + barW / 2, y + 7),
          anchor: _Anchor.top,
        );
      }

      // X-axis label
      _drawText(
        canvas,
        bar.label,
        const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        Offset(x + barW / 2, size.height - 18),
        anchor: _Anchor.top,
        maxWidth: slotW,
      );
    }

    // Baseline
    paint.color = AppColors.border.withValues(alpha: .5);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    canvas.drawLine(
      Offset(padL, padT + chartH),
      Offset(size.width - padR, padT + chartH),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.progress != progress;
}

// ─── Donut Chart Painter ──────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final double progress;
  final Map<String, double> data;
  final List<Color> colors;

  const _DonutPainter(
      {required this.progress, required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;

    final entries = data.entries.where((e) => e.value > 0).toList();
    final donutR = math.min(size.width * 0.34, size.height / 2) - 8;
    final center = Offset(donutR + 12, size.height / 2);
    final strokeW = donutR * 0.38;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    double start = -math.pi / 2;
    for (int i = 0; i < entries.length; i++) {
      final sweep = (entries[i].value / total) * 2 * math.pi * progress;
      arc.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: donutR - strokeW / 2),
        start,
        math.max(sweep - 0.06, 0),
        false,
        arc,
      );
      start += sweep;
    }

    // Center label
    _drawText(
      canvas,
      '${total.toInt()}',
      const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary),
      Offset(center.dx, center.dy - 8),
      anchor: _Anchor.center,
    );
    _drawText(
      canvas,
      'Total',
      const TextStyle(fontSize: 10, color: AppColors.textMuted),
      Offset(center.dx, center.dy + 9),
      anchor: _Anchor.center,
    );

    // Legend
    final legendX = donutR * 2 + 22;
    final legendH = entries.length * 22.0;
    double ly = (size.height - legendH) / 2;

    for (int i = 0; i < entries.length; i++) {
      canvas.drawCircle(
        Offset(legendX + 5, ly + 7),
        5,
        Paint()..color = colors[i % colors.length],
      );
      final pct = ((entries[i].value / total) * 100).toStringAsFixed(0);
      _drawText(
        canvas,
        '${entries[i].key} $pct%',
        const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        Offset(legendX + 14, ly + 7),
        anchor: _Anchor.centerLeft,
        maxWidth: size.width - legendX - 14,
      );
      ly += 22;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

// ─── Line Chart Painter ───────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final double progress;
  final List<double> points;
  final Color color;

  const _LineChartPainter(
      {required this.progress, required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxVal = points.reduce(math.max);
    if (maxVal == 0) return;

    const padL = 20.0, padR = 12.0, padT = 10.0, padB = 28.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;

    final pts = <Offset>[
      for (int i = 0; i < points.length; i++)
        Offset(
          padL + (i / (points.length - 1)) * chartW,
          padT + chartH - (points[i] / maxVal) * chartH,
        ),
    ];

    // Clip animated width
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, padL + chartW * progress, size.height));

    // Area fill
    final area = Path()..moveTo(pts.first.dx, padT + chartH);
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area.lineTo(pts.last.dx, padT + chartH);
    area.close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .22), color.withValues(alpha: .02)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Bezier line
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cx = (pts[i].dx + pts[i - 1].dx) / 2;
      line.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          colors: [color, color.withValues(alpha: .65)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Dots
    for (final p in pts) {
      canvas.drawCircle(p, 4.5, Paint()..color = color);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }

    canvas.restore();

    // Grid lines (outside clip so always visible)
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.28)
      ..strokeWidth = 0.7;
    for (int g = 1; g <= 3; g++) {
      final gy = padT + chartH * (1 - g / 3);
      canvas.drawLine(
          Offset(padL, gy), Offset(size.width - padR, gy), gridPaint);
    }

    // X labels
    final labels = ['D-6', 'D-5', 'D-4', 'D-3', 'D-2', 'D-1', 'Today'];
    for (int i = 0; i < pts.length; i++) {
      _drawText(
        canvas,
        i < labels.length ? labels[i] : '',
        const TextStyle(fontSize: 9, color: AppColors.textMuted),
        Offset(pts[i].dx, size.height - 16),
        anchor: _Anchor.top,
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.progress != progress;
}

// ─── Horizontal Bar Painter ───────────────────────────────────────────────────

class _HBar {
  final String label;
  final double value;
  final Color color;
  const _HBar(this.label, this.value, this.color);
}

class _HBarPainter extends CustomPainter {
  final double progress;
  final List<_HBar> items;

  const _HBarPainter({required this.progress, required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;
    final maxVal = items.map((i) => i.value).reduce(math.max);
    if (maxVal == 0) return;

    const labelW = 58.0;
    const padR = 8.0, padT = 6.0, padB = 6.0;
    final chartW = size.width - labelW - padR;
    final slotH = (size.height - padT - padB) / items.length;
    final barH = slotH * 0.44;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final bw = (item.value / maxVal) * chartW * progress;
      final x = labelW;
      final y = padT + i * slotH + (slotH - barH) / 2;

      // Label
      _drawText(
        canvas,
        item.label,
        const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500),
        Offset(labelW - 6, y + barH / 2),
        anchor: _Anchor.centerRight,
        maxWidth: labelW - 4,
      );

      // Track
      paint.color = item.color.withValues(alpha: .10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, chartW, barH), const Radius.circular(4)),
        paint,
      );

      // Fill
      if (bw > 0) {
        paint.shader = LinearGradient(
          colors: [item.color, item.color.withValues(alpha: .58)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(x, y, chartW, barH));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, bw, barH), const Radius.circular(4)),
          paint,
        );
        paint.shader = null;
      }

      // Value
      if (progress > 0.3 && item.value > 0) {
        _drawText(
          canvas,
          '${item.value.toInt()}',
          TextStyle(
              fontSize: 9.5,
              color: item.color,
              fontWeight: FontWeight.w700),
          Offset(x + bw + 5, y + barH / 2),
          anchor: _Anchor.centerLeft,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HBarPainter old) => old.progress != progress;
}

// ─── Canvas text helper ────────────────────────────────────────────────────────

enum _Anchor { top, center, centerLeft, centerRight }

void _drawText(
  Canvas canvas,
  String text,
  TextStyle style,
  Offset pos, {
  _Anchor anchor = _Anchor.top,
  double? maxWidth,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth ?? double.infinity);

  final Offset draw;
  switch (anchor) {
    case _Anchor.center:
      draw = Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2);
      break;
    case _Anchor.centerLeft:
      draw = Offset(pos.dx, pos.dy - tp.height / 2);
      break;
    case _Anchor.centerRight:
      draw = Offset(pos.dx - tp.width, pos.dy - tp.height / 2);
      break;
    case _Anchor.top:
      draw = Offset(pos.dx - tp.width / 2, pos.dy);
      break;
  }
  tp.paint(canvas, draw);
}
