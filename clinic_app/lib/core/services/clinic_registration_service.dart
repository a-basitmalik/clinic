import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/clinic_registration_model.dart';
import '../../models/api_response_model.dart';

class ClinicRegistrationService {
  ClinicRegistrationService._();

  static Future<ApiResponse<Map<String, dynamic>>> register(
    ClinicRegistrationModel data,
  ) {
    return ApiService.post<Map<String, dynamic>>(
      ApiConstants.registerClinic,
      body: data.toJson(),
      fromData: (d) => d as Map<String, dynamic>,
      auth: false,
    );
  }
}
