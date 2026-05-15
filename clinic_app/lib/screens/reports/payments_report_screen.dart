import '../../core/constants/api_constants.dart';
import '../../routes/app_routes.dart';
import 'generic_report_screen.dart';

class PaymentsReportScreen extends GenericReportScreen {
  const PaymentsReportScreen({super.key})
      : super(
            title: 'Payments Report',
            route: AppRoutes.reportPayments,
            endpoint: ApiConstants.reportPayments,
            paymentTypeFilter: true,
            statusFilter: true);
}
