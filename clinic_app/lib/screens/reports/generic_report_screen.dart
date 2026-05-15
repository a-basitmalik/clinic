import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/report_service.dart';
import '../../core/widgets/app_table.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/export_button.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/report_filter_bar.dart';
import '../../core/widgets/report_summary_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/simple_chart_placeholder.dart';
import '../../models/api_response_model.dart';
import '../../models/report_model.dart';

class GenericReportScreen extends StatefulWidget {
  final String title;
  final String route;
  final String endpoint;
  final bool doctorFilter;
  final bool paymentTypeFilter;
  final bool statusFilter;

  const GenericReportScreen({
    super.key,
    required this.title,
    required this.route,
    required this.endpoint,
    this.doctorFilter = false,
    this.paymentTypeFilter = false,
    this.statusFilter = false,
  });

  @override
  State<GenericReportScreen> createState() => _GenericReportScreenState();
}

class _GenericReportScreenState extends State<GenericReportScreen> {
  ReportModel? _report;
  DateTimeRange? _range;
  String? _doctorId;
  String? _paymentType;
  String? _status;
  String _groupBy = 'day';
  bool _loading = true;
  bool _export = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _report = await ReportService.getReport(
        name: widget.title,
        endpoint: widget.endpoint,
        startDate: _range?.start.toIso8601String().split('T').first,
        endDate: _range?.end.toIso8601String().split('T').first,
        doctorId: _doctorId,
        paymentType: _paymentType,
        status: _status,
        groupBy: _groupBy,
        export: _export,
      );
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: widget.title,
      currentRoute: widget.route,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ReportFilterBar(
          range: _range,
          doctorId: _doctorId,
          paymentType: _paymentType,
          status: _status,
          groupBy: _groupBy,
          onRangeChanged: (v) {
            setState(() => _range = v);
            _load();
          },
          onDoctorChanged: widget.doctorFilter
              ? (v) {
                  _doctorId = v;
                  _load();
                }
              : null,
          onPaymentTypeChanged: widget.paymentTypeFilter
              ? (v) {
                  _paymentType = v;
                  _load();
                }
              : null,
          onStatusChanged: widget.statusFilter
              ? (v) {
                  _status = v;
                  _load();
                }
              : null,
          onGroupByChanged: (v) {
            _groupBy = v;
            _load();
          },
          onRefresh: _load,
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          FilterChip(
              label: const Text('Export JSON'),
              selected: _export,
              onSelected: (v) {
                setState(() => _export = v);
                _load();
              }),
          if (_report != null) ExportButton(data: _report!.raw),
        ]),
        const SizedBox(height: 16),
        if (_loading)
          const LoadingWidget()
        else if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else
          _body(_report!),
      ]),
    );
  }

  Widget _body(ReportModel report) {
    final summaryEntries = report.summary.entries.take(8).toList();
    final chartEntries = report.charts.entries.take(3).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisExtent: 110,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12),
        itemCount: summaryEntries.length,
        itemBuilder: (_, i) => ReportSummaryCard(
            label: _title(summaryEntries[i].key),
            value: summaryEntries[i].value,
            icon: Icons.analytics_rounded),
      ),
      const SizedBox(height: 20),
      if (chartEntries.isNotEmpty)
        Wrap(
            spacing: 12,
            runSpacing: 12,
            children: chartEntries
                .map((e) => SizedBox(
                    width: 360,
                    child: SimpleChartPlaceholder(
                        title: _title(e.key),
                        rows: e.value is List ? e.value as List : const [])))
                .toList()),
      const SizedBox(height: 20),
      if (report.rows.isNotEmpty)
        _rows(report.rows)
      else
        const Text('No detailed rows for this report.',
            style: TextStyle(color: AppColors.textSecondary)),
    ]);
  }

  Widget _rows(List<Map<String, dynamic>> rows) {
    final keys = rows.expand((r) => r.keys).toSet().take(6).toList();
    return AppTable<Map<String, dynamic>>(
      rows: rows,
      emptyMessage: 'No rows found.',
      mobileCard: (r) => Card(
          child: ListTile(
              title: Text('${r[keys.first] ?? 'Row'}'),
              subtitle: Text(r.entries
                  .take(4)
                  .map((e) => '${_title(e.key)}: ${e.value}')
                  .join('\n')))),
      columns: keys
          .map((k) => AppTableColumn<Map<String, dynamic>>(
              header: _title(k), cell: (r) => Text('${r[k] ?? '-'}')))
          .toList(),
    );
  }

  String _title(String key) => key
      .split('_')
      .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}
