class DoctorEarningsModel {
  final double today;
  final double monthly;
  final double total;
  final int appointments;
  final int completed;

  const DoctorEarningsModel({
    required this.today,
    required this.monthly,
    required this.total,
    required this.appointments,
    required this.completed,
  });

  factory DoctorEarningsModel.fromJson(Map<String, dynamic> j) => DoctorEarningsModel(
    today: (j['today_earning'] as num?)?.toDouble() ?? 0,
    monthly: (j['monthly_earning'] as num?)?.toDouble() ?? 0,
    total: (j['total_earning'] as num?)?.toDouble() ?? 0,
    appointments: j['appointment_count'] as int? ?? 0,
    completed: j['completed_consultations'] as int? ?? 0,
  );
}
