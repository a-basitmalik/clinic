import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DateFilterBar extends StatelessWidget {
  final String? selectedDate;
  final void Function(String? date) onDateChanged;
  final bool showTodayButton;

  const DateFilterBar({
    super.key,
    this.selectedDate,
    required this.onDateChanged,
    this.showTodayButton = true,
  });

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _tomorrow() {
    final tom = DateTime.now().add(const Duration(days: 1));
    return '${tom.year}-${tom.month.toString().padLeft(2, '0')}-${tom.day.toString().padLeft(2, '0')}';
  }

  String _fmt(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${parts[2]} ${m > 0 && m <= 12 ? months[m] : parts[1]}';
  }

  bool _isToday(String? d)    => d != null && d == _today();
  bool _isTomorrow(String? d) => d != null && d == _tomorrow();
  bool _isCustom(String? d)   => d != null && !_isToday(d) && !_isTomorrow(d);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (showTodayButton) ...[
        _Chip(
          label: 'Today',
          active: _isToday(selectedDate),
          onTap: () => onDateChanged(_isToday(selectedDate) ? null : _today()),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'Tomorrow',
          active: _isTomorrow(selectedDate),
          onTap: () => onDateChanged(_isTomorrow(selectedDate) ? null : _tomorrow()),
        ),
        const SizedBox(width: 8),
      ],
      _Chip(
        label: _isCustom(selectedDate) ? _fmt(selectedDate!) : 'Pick Date',
        active: _isCustom(selectedDate),
        icon: Icons.calendar_today_rounded,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            final s = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            onDateChanged(s);
          }
        },
      ),
      if (selectedDate != null) ...[
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onDateChanged(null),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
          ),
        ),
      ],
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  const _Chip({required this.label, required this.active, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: active ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ]),
      ),
    );
  }
}
