class ReportUploadModel {
  final int? id;
  final int patientId;
  final int? appointmentId;
  final String reportTitle;
  final String reportType;
  final String? fileUrl;
  final String? notes;

  const ReportUploadModel({
    this.id,
    required this.patientId,
    this.appointmentId,
    required this.reportTitle,
    required this.reportType,
    this.fileUrl,
    this.notes,
  });

  factory ReportUploadModel.fromJson(Map<String, dynamic> j) => ReportUploadModel(
    id: j['id'] as int?,
    patientId: j['patient_id'] as int? ?? 0,
    appointmentId: j['appointment_id'] as int?,
    reportTitle: j['report_title'] as String? ?? '',
    reportType: j['report_type'] as String? ?? '',
    fileUrl: j['file_url'] as String?,
    notes: j['notes'] as String?,
  );
}
