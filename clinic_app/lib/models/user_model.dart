class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final int? clinicId;
  final int? doctorId;
  final int? patientId;
  final bool mustChangePassword;
  final String status;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.clinicId,
    this.doctorId,
    this.patientId,
    required this.mustChangePassword,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'patient',
      clinicId: json['clinic_id'] as int?,
      doctorId: json['doctor_id'] as int?,
      patientId: json['patient_id'] as int?,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'clinic_id': clinicId,
        'doctor_id': doctorId,
        'patient_id': patientId,
        'must_change_password': mustChangePassword,
        'status': status,
      };

  bool get isActive => status == 'active';

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    int? clinicId,
    int? doctorId,
    int? patientId,
    bool? mustChangePassword,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      clinicId: clinicId ?? this.clinicId,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      status: status ?? this.status,
    );
  }
}
