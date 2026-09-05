import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../services/export_service.dart';

class ExportButton extends StatelessWidget {
  final Map<String, dynamic> data;
  final String filename;

  const ExportButton(
      {super.key, required this.data, this.filename = 'clinic-report'});

  List<Map<String, dynamic>> get _rows {
    final raw = data['rows'] ??
        data['sales_detail'] ??
        data['recent_payments'] ??
        data['appointments'] ??
        data['payments'];
    return raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [data];
  }

  String _csv() {
    final rows = _rows;
    final keys = rows.expand((r) => r.keys).toSet().toList();
    String cell(dynamic value) => '"${'$value'.replaceAll('"', '""')}"';
    return [
      keys.map(cell).join(','),
      ...rows.map((r) => keys.map((k) => cell(r[k] ?? '')).join(','))
    ].join('\n');
  }

  Future<Uint8List> _pdf() async {
    final doc = pw.Document();
    final rows = _rows;
    final keys = rows.expand((r) => r.keys).toSet().take(8).toList();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (_) => [
        pw.Text(filename.replaceAll('-', ' '),
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: keys,
          data: rows
              .map((r) => keys.map((k) => '${r[k] ?? ''}').toList())
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 7),
        ),
      ],
    ));
    return doc.save();
  }

  Future<void> _export(BuildContext context, String type) async {
    try {
      if (type == 'json') {
        await downloadBytes(
            '$filename.json',
            Uint8List.fromList(
                utf8.encode(const JsonEncoder.withIndent('  ').convert(data))),
            'application/json');
      } else if (type == 'csv') {
        await downloadBytes('$filename.csv',
            Uint8List.fromList(utf8.encode(_csv())), 'text/csv');
      } else {
        await downloadBytes('$filename.pdf', await _pdf(), 'application/pdf');
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) => _export(context, v),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'pdf', child: Text('Download PDF')),
        PopupMenuItem(value: 'csv', child: Text('Download CSV')),
        PopupMenuItem(value: 'json', child: Text('Download JSON')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.download_rounded, size: 18),
          SizedBox(width: 8),
          Text('Export'),
        ]),
      ),
    );
  }
}
