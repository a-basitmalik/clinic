class DoctorModel {
  final int    id;
  final int?   userId;
  final int?   clinicId;
  final int?   departmentId;
  final String name;
  final String email;
  final String? phone;
  final String? departmentName;
  final String? specialization;
  final String? qualification;
  final int?   experience;
  final String? licenseNumber;
  final double? consultationFee;
  final List<String> availableDays;
  final String? availableStartTime;
  final String? availableEndTime;
  final String  status;      // active | inactive
  final String? tempPassword;

  const DoctorModel({
    required this.id,
    this.userId,
    this.clinicId,
    this.departmentId,
    required this.name,
    required this.email,
    this.phone,
    this.departmentName,
    this.specialization,
    this.qualification,
    this.experience,
    this.licenseNumber,
    this.consultationFee,
    required this.availableDays,
    this.availableStartTime,
    this.availableEndTime,
    required this.status,
    this.tempPassword,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> j) {
    List<String> parseDays(dynamic d) {
      if (d == null) return [];
      if (d is List) return d.map((e) => e.toString()).toList();
      return [];
    }

    return DoctorModel(
      id:                 j['id']                   as int,
      userId:             j['user_id']               as int?,
      clinicId:           j['clinic_id']             as int?,
      departmentId:       j['department_id']         as int?,
      name:               j['name']                  as String? ?? '',
      email:              j['email']                 as String? ?? '',
      phone:              j['phone']                 as String?,
      departmentName:     j['department_name']       as String?,
      specialization:     j['specialization']        as String?,
      qualification:      j['qualification']         as String?,
      experience:         j['experience']            as int?,
      licenseNumber:      j['license_number']        as String?,
      consultationFee:    (j['consultation_fee'] as num?)?.toDouble(),
      availableDays:      parseDays(j['available_days']),
      availableStartTime: j['available_start_time']  as String?,
      availableEndTime:   j['available_end_time']    as String?,
      status:             j['status']                as String? ?? 'active',
      tempPassword:       j['temp_password']         as String?,
    );
  }

  bool get isActive => status == 'active';

  Map<String, dynamic> toFormJson({int? departmentId}) => {
    'name':                 name,
    'email':                email,
    'phone':                phone,
    'department_id':        departmentId ?? this.departmentId,
    'specialization':       specialization,
    'qualification':        qualification,
    'experience':           experience,
    'license_number':       licenseNumber,
    'consultation_fee':     consultationFee,
    'available_days':       availableDays,
    'available_start_time': availableStartTime,
    'available_end_time':   availableEndTime,
  };
}
