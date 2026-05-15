class DepartmentModel {
  final int    id;
  final int    clinicId;
  final String name;
  final int?   doctorCount;
  final String? createdAt;

  const DepartmentModel({
    required this.id,
    required this.clinicId,
    required this.name,
    this.doctorCount,
    this.createdAt,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> j) {
    return DepartmentModel(
      id:          j['id']           as int,
      clinicId:    j['clinic_id']    as int? ?? 0,
      name:        j['name']         as String? ?? '',
      doctorCount: j['doctor_count'] as int?,
      createdAt:   j['created_at']   as String?,
    );
  }
}
