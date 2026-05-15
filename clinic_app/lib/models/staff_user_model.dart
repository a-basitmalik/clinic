class StaffUserModel {
  final int    id;
  final String name;
  final String email;
  final String? phone;
  final String  role;
  final String  status;
  final String? tempPassword; // present only on creation response

  const StaffUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.tempPassword,
  });

  factory StaffUserModel.fromJson(Map<String, dynamic> j) {
    return StaffUserModel(
      id:           j['id']            as int,
      name:         j['name']          as String? ?? '',
      email:        j['email']         as String? ?? '',
      phone:        j['phone']         as String?,
      role:         j['role']          as String? ?? '',
      status:       j['status']        as String? ?? 'active',
      tempPassword: j['temp_password'] as String?,
    );
  }

  bool get isActive => status == 'active';
}
