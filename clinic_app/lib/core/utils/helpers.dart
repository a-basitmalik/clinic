import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  static String formatDate(String? iso, {String pattern = 'dd MMM yyyy'}) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat(pattern).format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String formatDateTime(String? iso) =>
      formatDate(iso, pattern: 'dd MMM yyyy, hh:mm a');

  static String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '—';
    try {
      final parts = timeStr.split(':');
      final dt = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  static String formatCurrency(num? amount, {String symbol = 'PKR'}) {
    if (amount == null) return '$symbol 0';
    return '$symbol ${NumberFormat('#,##0.00').format(amount)}';
  }

  static String formatNumber(num? value) {
    if (value == null) return '0';
    return NumberFormat('#,##0').format(value);
  }

  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String snakeToTitle(String s) =>
      s.split('_').map(capitalize).join(' ');

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inSeconds < 60) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return formatDate(iso);
    } catch (_) {
      return '';
    }
  }
}
