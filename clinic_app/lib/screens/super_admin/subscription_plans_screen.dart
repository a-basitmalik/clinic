import 'package:flutter/material.dart';

import '../../core/services/super_admin_service.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../routes/app_routes.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;
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
      _plans = await SuperAdminService.getSubscriptionPlans();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? plan]) async {
    final name = TextEditingController(text: plan?['name']?.toString() ?? '');
    final price =
        TextEditingController(text: plan?['price']?.toString() ?? '0');
    final days =
        TextEditingController(text: plan?['duration_days']?.toString() ?? '30');
    final doctors =
        TextEditingController(text: plan?['max_doctors']?.toString() ?? '1');
    bool pharmacy = plan?['has_pharmacy'] as bool? ?? false;
    bool reports = plan?['has_reports'] as bool? ?? true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        return AlertDialog(
          title: Text(plan == null
              ? 'New Subscription Plan'
              : 'Edit Subscription Plan'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price')),
                TextField(
                    controller: days,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Duration Days')),
                TextField(
                    controller: doctors,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Maximum Doctors')),
                SwitchListTile(
                    value: pharmacy,
                    onChanged: (v) => setLocal(() => pharmacy = v),
                    title: const Text('Pharmacy Included')),
                SwitchListTile(
                    value: reports,
                    onChanged: (v) => setLocal(() => reports = v),
                    title: const Text('Reports Included')),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await SuperAdminService.saveSubscriptionPlan({
                    'name': name.text.trim(),
                    'price': double.tryParse(price.text) ?? 0,
                    'duration_days': int.tryParse(days.text) ?? 30,
                    'max_doctors': int.tryParse(doctors.text) ?? 1,
                    'has_pharmacy': pharmacy,
                    'has_reports': reports,
                    'status': plan?['status'] ?? 'active',
                  }, id: plan?['id'] as int?);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } on ApiException catch (e) {
                  if (ctx.mounted)
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
    name.dispose();
    price.dispose();
    days.dispose();
    doctors.dispose();
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Subscription Plans',
      currentRoute: AppRoutes.subscriptions,
      body: _loading
          ? const LoadingWidget()
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                FilledButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('New Plan')),
                const SizedBox(width: 12),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              ]),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: _plans
                    .map((plan) => SizedBox(
                          width: 300,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${plan['name']}',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800)),
                                    Text(
                                        'PKR ${plan['price']} / ${plan['duration_days']} days'),
                                    Text(
                                        'Up to ${plan['max_doctors']} doctors'),
                                    Text(
                                        'Pharmacy: ${plan['has_pharmacy'] == true ? 'Yes' : 'No'}'),
                                    Text(
                                        'Reports: ${plan['has_reports'] == true ? 'Yes' : 'No'}'),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                        onPressed: () => _edit(plan),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit')),
                                  ]),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ]),
    );
  }
}
