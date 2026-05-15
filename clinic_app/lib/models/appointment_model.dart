class AppointmentModel {
  final int     id;
  final int?    patientId;
  final String  patientName;
  final String? patientCode;
  final String? patientPhone;
  final int?    doctorId;
  final String  doctorName;
  final String? departmentName;
  final String  appointmentDate;
  final String  appointmentTime;
  final int     tokenNumber;
  final String  consultationType;  // new | followup | emergency
  final String  status;            // waiting | sent_to_assistant | in_consultation | completed | cancelled
  final double? fee;
  final String  paymentStatus;     // unpaid | paid | partial
  final double? paidAmount;
  final String? paymentMethod;     // cash | card | easypaisa | jazzcash | bank
  final String? notes;

  const AppointmentModel({
    required this.id,
    this.patientId,
    required this.patientName,
    this.patientCode,
    this.patientPhone,
    this.doctorId,
    required this.doctorName,
    this.departmentName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.tokenNumber,
    required this.consultationType,
    required this.status,
    this.fee,
    required this.paymentStatus,
    this.paidAmount,
    this.paymentMethod,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> j) {
    return AppointmentModel(
      id:               j['id']                as int,
      patientId:        j['patient_id']        as int?,
      patientName:      j['patient_name']      as String? ?? '',
      patientCode:      j['patient_code']      as String?,
      patientPhone:     j['patient_phone']     as String?,
      doctorId:         j['doctor_id']         as int?,
      doctorName:       j['doctor_name']       as String? ?? '',
      departmentName:   j['department_name']   as String?,
      appointmentDate:  j['appointment_date']  as String? ?? '',
      appointmentTime:  j['appointment_time']  as String? ?? '',
      tokenNumber:      j['token_number']      as int? ?? 0,
      consultationType: j['consultation_type'] as String? ?? 'new',
      status:           j['status']            as String? ?? 'waiting',
      fee:              (j['fee']              as num?)?.toDouble(),
      paymentStatus:    j['payment_status']    as String? ?? 'unpaid',
      paidAmount:       (j['paid_amount']      as num?)?.toDouble(),
      paymentMethod:    j['payment_method']    as String?,
      notes:            j['notes']             as String?,
    );
  }

  bool get isActive    => status == 'waiting' || status == 'sent_to_assistant' || status == 'in_consultation';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isPaid      => paymentStatus == 'paid';
}
