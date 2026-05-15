import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExportButton extends StatelessWidget {
  final Map<String, dynamic> data;

  const ExportButton({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.copy_rounded),
      label: const Text('Copy JSON'),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(
            text: const JsonEncoder.withIndent('  ').convert(data)));
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('JSON copied.')));
      },
    );
  }
}
