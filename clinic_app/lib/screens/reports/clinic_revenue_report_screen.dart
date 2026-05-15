import '../../core/constants/api_constants.dart';
import '../../routes/app_routes.dart';
import 'generic_report_screen.dart';

class ClinicRevenueReportScreen extends GenericReportScreen {
  const ClinicRevenueReportScreen({super.key})
      : super(
            title: 'Clinic Revenue Report',
            route: AppRoutes.reportClinicRevenue,
            endpoint: ApiConstants.reportClinicRevenue,
            doctorFilter: true,
            paymentTypeFilter: true);
}
