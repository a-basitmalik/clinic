import '../../core/constants/api_constants.dart';
import '../../routes/app_routes.dart';
import 'generic_report_screen.dart';

class AppointmentsReportScreen extends GenericReportScreen {
  const AppointmentsReportScreen({super.key})
      : super(
            title: 'Appointments Report',
            route: AppRoutes.reportAppointments,
            endpoint: ApiConstants.reportAppointments,
            doctorFilter: true,
            statusFilter: true);
}
