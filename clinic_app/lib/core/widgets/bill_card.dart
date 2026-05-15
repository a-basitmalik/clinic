import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';

class BillCard extends StatelessWidget {
  final BillModel bill;

  const BillCard({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
            backgroundColor: AppColors.accentSurface,
            child: Icon(Icons.receipt_long_rounded, color: AppColors.accent)),
        title: Text(
            '${Helpers.snakeToTitle(bill.type)} • ${Helpers.formatCurrency(bill.amount)}'),
        subtitle: Text(
            '${Helpers.snakeToTitle(bill.method)} • ${Helpers.formatDateTime(bill.createdAt)}'),
        trailing: Text(Helpers.snakeToTitle(bill.status),
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
