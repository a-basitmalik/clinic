import '../../core/constants/api_constants.dart';
import '../../routes/app_routes.dart';
import 'generic_report_screen.dart';

class DoctorRevenueReportScreen extends GenericReportScreen {
  const DoctorRevenueReportScreen({super.key})
      : super(
            title: 'Doctor Revenue Report',
            route: AppRoutes.reportDoctorRevenue,
            endpoint: ApiConstants.reportDoctorRevenue,
            doctorFilter: true);
}
