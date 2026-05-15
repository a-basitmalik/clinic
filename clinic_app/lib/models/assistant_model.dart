class AssistantModel {
  final int id;
  final int? userId;
  final int? doctorId;
  final String name;
  final String? email;
  final String? phone;
  final String status;
  final Map<String, bool> permissions;
  final String? tempPassword;

  const AssistantModel({
    required this.id,
    this.userId,
    this.doctorId,
    required this.name,
    this.email,
    this.phone,
    required this.status,
    required this.permissions,
    this.tempPassword,
  });

  factory AssistantModel.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    bool flag(String key) => j[key] as bool? ?? false;
    return AssistantModel(
      id: j['id'] as int? ?? user?['id'] as int? ?? 0,
      userId: j['user_id'] as int? ?? user?['id'] as int?,
      doctorId: j['doctor_id'] as int?,
      name: j['name'] as String? ?? user?['name'] as String? ?? '',
      email: j['email'] as String? ?? user?['email'] as String?,
      phone: j['phone'] as String? ?? user?['phone'] as String?,
      status: j['status'] as String? ?? user?['status'] as String? ?? 'active',
      tempPassword: j['temp_password'] as String?,
      permissions: {
        'can_view_appointments': flag('can_view_appointments'),
        'can_add_vitals': flag('can_add_vitals'),
        'can_upload_reports': flag('can_upload_reports'),
        'can_prepare_prescription_draft': flag('can_prepare_prescription_draft'),
        'can_print_prescription': flag('can_print_prescription'),
        'can_view_patient_history': flag('can_view_patient_history'),
      },
    );
  }
}
