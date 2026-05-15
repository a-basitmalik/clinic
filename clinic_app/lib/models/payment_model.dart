class PaymentModel {
  final int     id;
  final String  receiptNumber;
  final int?    appointmentId;
  final int?    patientId;
  final String  patientName;
  final String? doctorName;
  final double  amount;
  final double  paidAmount;
  final String  paymentMethod;  // cash | card | easypaisa | jazzcash | bank
  final String  paymentType;    // consultation | pharmacy | lab | other
  final String  status;         // paid | partial | refunded
  final String? notes;
  final String  createdAt;

  const PaymentModel({
    required this.id,
    required this.receiptNumber,
    this.appointmentId,
    this.patientId,
    required this.patientName,
    this.doctorName,
    required this.amount,
    required this.paidAmount,
    required this.paymentMethod,
    required this.paymentType,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> j) {
    return PaymentModel(
      id:             j['id']              as int,
      receiptNumber:  j['receipt_number']  as String? ?? '',
      appointmentId:  j['appointment_id']  as int?,
      patientId:      j['patient_id']      as int?,
      patientName:    j['patient_name']    as String? ?? '',
      doctorName:     j['doctor_name']     as String?,
      amount:         (j['amount']         as num?)?.toDouble() ?? 0,
      paidAmount:     (j['paid_amount']    as num?)?.toDouble() ?? 0,
      paymentMethod:  j['payment_method']  as String? ?? 'cash',
      paymentType:    j['payment_type']    as String? ?? 'consultation',
      status:         j['status']          as String? ?? 'paid',
      notes:          j['notes']           as String?,
      createdAt:      j['created_at']      as String? ?? '',
    );
  }

  bool get isPaid    => status == 'paid';
  bool get isPartial => status == 'partial';
  double get balance => amount - paidAmount;
}
