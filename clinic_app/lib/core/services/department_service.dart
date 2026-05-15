import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/department_model.dart';
import '../../models/api_response_model.dart';

class DepartmentService {
  DepartmentService._();

  static Future<List<DepartmentModel>> getDepartments() async {
    final res = await ApiService.get<List<DepartmentModel>>(
      ApiConstants.departments,
      fromData: (d) => (d as List)
          .map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<DepartmentModel> createDepartment(String name) async {
    final res = await ApiService.post<DepartmentModel>(
      ApiConstants.departments,
      body: {'name': name},
      fromData: (d) {
        final data = d as Map<String, dynamic>;
        return DepartmentModel.fromJson(
          (data['department'] as Map<String, dynamic>?) ?? data,
        );
      },
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    return res.data!;
  }

  static Future<DepartmentModel> updateDepartment(int id, String name) async {
    final res = await ApiService.put<DepartmentModel>(
      '${ApiConstants.departments}/$id',
      body: {'name': name},
      fromData: (d) {
        final data = d as Map<String, dynamic>;
        return DepartmentModel.fromJson(
          (data['department'] as Map<String, dynamic>?) ?? data,
        );
      },
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    return res.data!;
  }

  static Future<void> deleteDepartment(int id) async {
    final res =
        await ApiService.delete<void>('${ApiConstants.departments}/$id');
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
  }
}
