import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'responsive_layout.dart';

class AppTableColumn<T> {
  final String header;
  final Widget Function(T row) cell;
  final double? width;

  const AppTableColumn({
    required this.header,
    required this.cell,
    this.width,
  });
}

class AppTable<T> extends StatelessWidget {
  final List<AppTableColumn<T>> columns;
  final List<T> rows;
  final String? emptyMessage;
  final Widget Function(T row)? mobileCard;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage,
    this.mobileCard,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage ?? 'No data available.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (mobileCard != null && ResponsiveLayout.isMobile(context)) {
      return Column(children: rows.map(mobileCard!).toList());
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.background),
            dataRowMinHeight: 52,
            dataRowMaxHeight: 72,
            headingTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
            columnSpacing: 16,
            horizontalMargin: 20,
            columns: columns
                .map((c) => DataColumn(
                      label: c.width != null
                          ? SizedBox(
                              width: c.width,
                              child: Text(c.header.toUpperCase()))
                          : Text(c.header.toUpperCase()),
                    ))
                .toList(),
            rows: rows
                .map((row) => DataRow(
                      cells: columns.map((c) => DataCell(c.cell(row))).toList(),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
