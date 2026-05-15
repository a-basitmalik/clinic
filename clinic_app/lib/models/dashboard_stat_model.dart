import 'package:flutter/material.dart';

class DashboardStat {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? trend;
  final bool trendUp;

  const DashboardStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
    this.trendUp = true,
  });
}
