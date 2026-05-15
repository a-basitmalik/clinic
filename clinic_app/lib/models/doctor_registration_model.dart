class DoctorRegistrationModel {
  String name;
  String email;
  String phone;
  String department;
  String specialization;
  String qualification;
  int    experience;
  String licenseNumber;
  double consultationFee;
  List<String> availableDays;
  String availableStartTime;
  String availableEndTime;

  DoctorRegistrationModel({
    this.name               = '',
    this.email              = '',
    this.phone              = '',
    this.department         = '',
    this.specialization     = '',
    this.qualification      = '',
    this.experience         = 0,
    this.licenseNumber      = '',
    this.consultationFee    = 0.0,
    List<String>? availableDays,
    this.availableStartTime = '09:00',
    this.availableEndTime   = '17:00',
  }) : availableDays = availableDays ?? [];

  Map<String, dynamic> toJson() => {
    'name':                 name,
    'email':                email,
    'phone':                phone,
    'department':           department,
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
