import 'package:flutter/material.dart';
import '../../core/widgets/prescription_preview.dart';
import '../../models/prescription_model.dart';

class PatientPrescriptionDetailsScreen extends StatelessWidget {
  final PrescriptionModel prescription;

  const PatientPrescriptionDetailsScreen(
      {super.key, required this.prescription});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Prescription #${prescription.id}')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: PrescriptionPreview(prescription: prescription),
        ),
      );
}
