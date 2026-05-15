import '../../core/constants/api_constants.dart';
import '../../routes/app_routes.dart';
import 'generic_report_screen.dart';

class PatientVisitsReportScreen extends GenericReportScreen {
  const PatientVisitsReportScreen({super.key})
      : super(
            title: 'Patient Visits Report',
            route: AppRoutes.reportPatientVisits,
            endpoint: ApiConstants.reportPatientVisits,
            doctorFilter: true);
}
