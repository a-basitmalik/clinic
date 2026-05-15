import '../constants/api_constants.dart';
import 'api_service.dart';

class ReceptionistService {
  ReceptionistService._();

  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.receptionistDashboard,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }
}
