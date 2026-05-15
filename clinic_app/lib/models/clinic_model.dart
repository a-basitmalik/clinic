class ClinicModel {
  final int    id;
  final String clinicName;
  final String ownerName;
  final String email;
  final String? phone;
  final String? address;
  final String  city;
  final String  clinicType;   // single_doctor | multi_doctor
  final String  status;       // pending | approved | suspended
  final int?   numberOfDoctors;
  final bool   hasPharmacy;
  final bool   hasReceptionist;
  final String? openingTime;
  final String? closingTime;
  final List<String> workingDays;
  final String? logo;
  final String? approvedAt;
  final String  createdAt;

  const ClinicModel({
    required this.id,
    required this.clinicName,
    required this.ownerName,
    required this.email,
    this.phone,
    this.address,
    required this.city,
    required this.clinicType,
    required this.status,
    this.numberOfDoctors,
    required this.hasPharmacy,
    required this.hasReceptionist,
    this.openingTime,
    this.closingTime,
    required this.workingDays,
    this.logo,
    this.approvedAt,
    required this.createdAt,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> j) {
    List<String> parseDays(dynamic d) {
      if (d == null) return [];
      if (d is List) return d.map((e) => e.toString()).toList();
      return [];
    }

    return ClinicModel(
      id:               j['id'] as int,
      clinicName:       j['clinic_name'] as String? ?? '',
      ownerName:        j['owner_name']  as String? ?? '',
      email:            j['email']       as String? ?? '',
      phone:            j['phone']       as String?,
      address:          j['address']     as String?,
      city:             j['city']        as String? ?? '',
      clinicType:       j['clinic_type'] as String? ?? 'single_doctor',
      status:           j['status']      as String? ?? 'pending',
      numberOfDoctors:  j['number_of_doctors'] as int?,
      hasPharmacy:      j['has_pharmacy']     as bool? ?? false,
      hasReceptionist:  j['has_receptionist'] as bool? ?? false,
      openingTime:      j['opening_time'] as String?,
      closingTime:      j['closing_time'] as String?,
      workingDays:      parseDays(j['working_days']),
      logo:             j['logo']        as String?,
      approvedAt:       j['approved_at'] as String?,
      createdAt:        j['created_at']  as String? ?? '',
    );
  }

  bool get isPending    => status == 'pending';
  bool get isApproved   => status == 'approved';
  bool get isSuspended  => status == 'suspended';
}
