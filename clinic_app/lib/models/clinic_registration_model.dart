import 'doctor_registration_model.dart';

class StaffMemberModel {
  String name;
  String email;
  String phone;

  StaffMemberModel({this.name = '', this.email = '', this.phone = ''});

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'phone': phone};
}

class ClinicRegistrationModel {
  // Step 1
  String       clinicName;
  String       ownerName;
  String       email;
  String       phone;
  String       address;
  String       city;
  String       openingTime;
  String       closingTime;
  List<String> workingDays;

  // Step 2
  String clinicType;       // single_doctor | multi_doctor
  int    numberOfDoctors;
  bool   hasPharmacy;
  bool   hasReceptionist;

  // Step 3
  List<DoctorRegistrationModel> doctors;

  // Step 4
  StaffMemberModel? receptionist;
  StaffMemberModel? pharmacy;

  ClinicRegistrationModel({
    this.clinicName      = '',
    this.ownerName       = '',
    this.email           = '',
    this.phone           = '',
    this.address         = '',
    this.city            = '',
    this.openingTime     = '09:00',
    this.closingTime     = '17:00',
    List<String>? workingDays,
    this.clinicType      = 'single_doctor',
    this.numberOfDoctors = 1,
    this.hasPharmacy     = false,
    this.hasReceptionist = false,
    List<DoctorRegistrationModel>? doctors,
    this.receptionist,
    this.pharmacy,
  })  : workingDays = workingDays ?? [],
        doctors     = doctors ?? [DoctorRegistrationModel()];

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'clinic_name':      clinicName,
      'owner_name':       ownerName,
      'email':            email,
      'phone':            phone,
      'address':          address,
      'city':             city,
      'opening_time':     openingTime,
      'closing_time':     closingTime,
      'working_days':     workingDays,
      'clinic_type':      clinicType,
      'number_of_doctors': numberOfDoctors,
      'has_pharmacy':     hasPharmacy,
      'has_receptionist': hasReceptionist,
      'doctors':          doctors.map((d) => d.toJson()).toList(),
    };
    if (hasReceptionist && receptionist != null) {
      map['receptionist'] = receptionist!.toJson();
    }
    if (hasPharmacy && pharmacy != null) {
      map['pharmacy'] = pharmacy!.toJson();
    }
    return map;
  }
}
