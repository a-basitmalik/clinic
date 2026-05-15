import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/staff_user_model.dart';
import '../../models/api_response_model.dart';

class StaffService {
  StaffService._();

  // ── Receptionists ──────────────────────────────────────────────────────────

  static Future<List<StaffUserModel>> getReceptionists({String? search}) async {
    final params = <String, String>{'per_page': '100'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get<List<StaffUserModel>>(
      ApiConstants.receptionists,
      queryParams: params,
      fromData: (d) =>
          (d as List).map((e) => StaffUserModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return res.data ?? [];
  }

  static Future<StaffUserModel> createReceptionist(Map<String, dynamic> body) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.receptionists,
      body: body,
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    final user = StaffUserModel.fromJson(userJson);
    final tempPass = data['temp_password'] as String? ?? userJson['temp_password'] as String?;
    return StaffUserModel(
      id: user.id, name: user.name, email: user.email,
      phone: user.phone, role: user.role, status: user.status,
      tempPassword: tempPass,
    );
  }

  static Future<void> deactivateReceptionist(int id) async {
    final res = await ApiService.put<void>('${ApiConstants.receptionists}/$id/deactivate');
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }

  // ── Pharmacy Users ─────────────────────────────────────────────────────────

  static Future<List<StaffUserModel>> getPharmacyUsers({String? search}) async {
    final params = <String, String>{'per_page': '100'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiService.get<List<StaffUserModel>>(
      ApiConstants.clinicAdminPharmacyUsers,
      queryParams: params,
      fromData: (d) =>
          (d as List).map((e) => StaffUserModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
    return res.data ?? [];
  }

  static Future<StaffUserModel> createPharmacyUser(Map<String, dynamic> body) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.clinicAdminPharmacyUsers,
      body: body,
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    final user = StaffUserModel.fromJson(userJson);
    final tempPass = data['temp_password'] as String? ?? userJson['temp_password'] as String?;
    return StaffUserModel(
      id: user.id, name: user.name, email: user.email,
      phone: user.phone, role: user.role, status: user.status,
      tempPassword: tempPass,
    );
  }

  static Future<void> deactivatePharmacyUser(int id) async {
    final res = await ApiService.put<void>('${ApiConstants.clinicAdminPharmacyUsers}/$id/deactivate');
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }
}
