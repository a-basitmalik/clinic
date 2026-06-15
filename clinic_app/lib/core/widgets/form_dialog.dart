import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../models/api_response_model.dart';
import 'custom_button.dart';

/// Shows a modal dialog with a Form. Returns true if submitted successfully.
Future<bool> showFormDialog(
  BuildContext context, {
  required String title,
  required GlobalKey<FormState> formKey,
  required Widget fields,
  required Future<void> Function() onSubmit,
  String submitLabel = 'Save',
  String cancelLabel = 'Cancel',
  double maxWidth = 500,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FormDialogWidget(
      title: title,
      formKey: formKey,
      fields: fields,
      onSubmit: onSubmit,
      submitLabel: submitLabel,
      cancelLabel: cancelLabel,
      maxWidth: maxWidth,
    ),
  );
  return result ?? false;
}

class _FormDialogWidget extends StatefulWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final Widget fields;
  final Future<void> Function() onSubmit;
  final String submitLabel;
  final String cancelLabel;
  final double maxWidth;

  const _FormDialogWidget({
    required this.title,
    required this.formKey,
    required this.fields,
    required this.onSubmit,
    required this.submitLabel,
    required this.cancelLabel,
    required this.maxWidth,
  });

  @override
  State<_FormDialogWidget> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialogWidget> {
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!(widget.formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      if (mounted) Navigator.pop(context, true);
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
    return Dialog(
      backgroundColor: AppColors.glass,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed:
                        _loading ? null : () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const Divider(height: 20),
              Form(key: widget.formKey, child: widget.fields),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _loading ? null : () => Navigator.pop(context, false),
                    child: Text(widget.cancelLabel,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    label: widget.submitLabel,
                    loading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
