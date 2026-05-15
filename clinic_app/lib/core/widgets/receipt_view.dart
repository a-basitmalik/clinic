import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';
import '../../models/payment_model.dart';

class ReceiptView extends StatelessWidget {
  final PaymentModel payment;

  const ReceiptView({super.key, required this.payment});

  static Future<void> show(BuildContext context, PaymentModel payment) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ReceiptView(payment: payment),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = payment;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 36),
            const SizedBox(height: 8),
            const Text('Payment Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(p.receiptNumber, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 16),

        // Divider with scissors icon
        Row(children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.content_cut_rounded, size: 16, color: Colors.grey.shade400),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ]),
        const SizedBox(height: 12),

        // Details
        _Row('Patient',    p.patientName),
        if (p.doctorName != null) _Row('Doctor', p.doctorName!),
        _Row('Date',       Helpers.formatDateTime(p.createdAt)),
        _Row('Type',       _typeLabel(p.paymentType)),
        _Row('Method',     _methodLabel(p.paymentMethod)),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        _Row('Total Fee', Helpers.formatCurrency(p.amount), bold: true),
        _Row('Paid',      Helpers.formatCurrency(p.paidAmount), valueColor: AppColors.success, bold: true),
        if (p.isPartial)
          _Row('Balance', Helpers.formatCurrency(p.balance), valueColor: AppColors.danger, bold: true),

        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: p.isPaid ? AppColors.successSurface : AppColors.warningSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              p.isPaid ? 'PAID' : 'PARTIAL PAYMENT',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: p.isPaid ? AppColors.success : AppColors.warning,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        if (p.notes != null && p.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Note: ${p.notes}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],

        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ]),
    );
  }

  String _typeLabel(String s) {
    const map = {'consultation': 'Consultation', 'pharmacy': 'Pharmacy', 'lab': 'Lab', 'other': 'Other'};
    return map[s] ?? s;
  }

  String _methodLabel(String s) {
    const map = {'cash': 'Cash', 'card': 'Card', 'easypaisa': 'EasyPaisa', 'jazzcash': 'JazzCash', 'bank': 'Bank Transfer'};
    return map[s] ?? s;
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _Row(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ]),
    );
  }
}
