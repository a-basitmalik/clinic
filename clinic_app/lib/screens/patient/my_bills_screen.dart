import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/bill_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../routes/app_routes.dart';
import 'patient_portal_base.dart';

class MyBillsScreen extends StatefulWidget {
  const MyBillsScreen({super.key});

  @override
  State<MyBillsScreen> createState() => _MyBillsScreenState();
}

class _MyBillsScreenState extends State<MyBillsScreen>
    with PatientPortalLoader {
  @override
  void initState() {
    super.initState();
    loadPortal();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        title: 'My Bills',
        currentRoute: AppRoutes.myBills,
        body: portalState((p) {
          if (p.bills.isEmpty)
            return const Text('No bills found.',
                style: TextStyle(color: AppColors.textSecondary));
          return Column(
              children: p.bills.map((b) => BillCard(bill: b)).toList());
        }),
      );
}
