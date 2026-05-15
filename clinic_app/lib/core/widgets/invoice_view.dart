import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';

class InvoiceView extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceView({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final sale = invoice.sale;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  (invoice.clinic['clinic_name'] ??
                          invoice.clinic['name'] ??
                          'Clinic')
                      .toString(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
              Text((invoice.clinic['address'] ?? '').toString(),
                  style: const TextStyle(color: AppColors.textSecondary)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Invoice #${sale.id}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(Helpers.formatDateTime(sale.createdAt),
                style: const TextStyle(color: AppColors.textSecondary)),
          ]),
        ]),
        const Divider(height: 32),
        Wrap(spacing: 28, runSpacing: 8, children: [
          _meta(
              'Patient',
              sale.patientName ??
                  invoice.patient?['name']?.toString() ??
                  'Walk-in'),
          _meta('Prescription',
              sale.prescriptionId == null ? '-' : '#${sale.prescriptionId}'),
          _meta('Sold By', sale.soldByName ?? '-'),
          _meta('Payment',
              '${Helpers.snakeToTitle(sale.paymentMethod)} • ${Helpers.snakeToTitle(sale.paymentStatus)}'),
        ]),
        const SizedBox(height: 20),
        DataTable(
          columns: const [
            DataColumn(label: Text('Medicine')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Unit')),
            DataColumn(label: Text('Total')),
          ],
          rows: sale.items
              .map((i) => DataRow(cells: [
                    DataCell(Text(i.medicineName)),
                    DataCell(Text('${i.quantity}')),
                    DataCell(Text(Helpers.formatCurrency(i.unitPrice))),
                    DataCell(Text(Helpers.formatCurrency(i.totalPrice))),
                  ]))
              .toList(),
        ),
        const Divider(height: 32),
        Align(
          alignment: Alignment.centerRight,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Subtotal: ${Helpers.formatCurrency(invoice.subtotal)}'),
            const SizedBox(height: 6),
            Text('Total: ${Helpers.formatCurrency(invoice.total)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ]),
        ),
      ]),
    );
  }

  Widget _meta(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]);
}
