import 'package:flutter/material.dart';
import '../../core/services/pharmacy_service.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/invoice_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/api_response_model.dart';
import '../../models/invoice_model.dart';

class InvoiceScreen extends StatefulWidget {
  final int saleId;

  const InvoiceScreen({super.key, required this.saleId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  InvoiceModel? _invoice;
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
      _invoice = await PharmacyService.invoice(widget.saleId);
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Invoice #${widget.saleId}')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const LoadingWidget()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : SingleChildScrollView(
                      child: InvoiceView(invoice: _invoice!)),
        ),
      );
}
