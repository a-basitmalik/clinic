class PatientModel {
  final int     id;
  final String  patientCode;
  final String  name;
  final int?    age;
  final String? gender;
  final String? phone;
  final String? cnic;
  final String? address;
  final String? bloodGroup;
  final String? emergencyContact;
  final String  createdAt;

  const PatientModel({
    required this.id,
    required this.patientCode,
    required this.name,
    this.age,
    this.gender,
    this.phone,
    this.cnic,
    this.address,
    this.bloodGroup,
    this.emergencyContact,
    required this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> j) {
    return PatientModel(
      id:               j['id']                as int,
      patientCode:      j['patient_code']      as String? ?? '',
      name:             j['name']              as String? ?? '',
      age:              j['age']               as int?,
      gender:           j['gender']            as String?,
      phone:            j['phone']             as String?,
      cnic:             j['cnic']              as String?,
      address:          j['address']           as String?,
      bloodGroup:       j['blood_group']       as String?,
      emergencyContact: j['emergency_contact'] as String?,
      createdAt:        j['created_at']        as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name':              name,
    'age':               age,
    'gender':            gender,
    'phone':             phone,
    'cnic':              cnic,
    'address':           address,
    'blood_group':       bloodGroup,
    'emergency_contact': emergencyContact,
  };
}
