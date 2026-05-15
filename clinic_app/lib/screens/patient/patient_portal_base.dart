import 'package:flutter/material.dart';
import '../../core/services/patient_portal_service.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/patient_portal_model.dart';

mixin PatientPortalLoader<T extends StatefulWidget> on State<T> {
  PatientPortalModel? portal;
  bool loading = true;
  String? error;

  Future<void> loadPortal() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      portal = await PatientPortalService.loadPortal();
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted)
        setState(() {
          error = e.toString();
          loading = false;
        });
    }
  }

  Widget portalState(Widget Function(PatientPortalModel p) builder) {
    if (loading) return const LoadingWidget();
    if (error != null) return ErrorView(message: error!, onRetry: loadPortal);
    return builder(
        portal ?? const PatientPortalModel(prescriptions: [], bills: []));
  }
}
