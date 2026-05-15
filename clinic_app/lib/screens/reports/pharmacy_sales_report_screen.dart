import '../../core/constants/api_constants.dart';
import '../../routes/app_routes.dart';
import 'generic_report_screen.dart';

class PharmacySalesReportScreen extends GenericReportScreen {
  const PharmacySalesReportScreen({super.key})
      : super(
            title: 'Pharmacy Sales Report',
            route: AppRoutes.reportPharmacySales,
            endpoint: ApiConstants.reportPharmacySales);
}
