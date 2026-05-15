import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../models/api_response_model.dart';
import '../../models/payment_model.dart';

class PaymentService {
  PaymentService._();

  static Future<List<PaymentModel>> getPayments({
    String? from,
    String? to,
    String? status,
    String? method,
    int perPage = 100,
  }) async {
    final params = <String, String>{'per_page': '$perPage'};
    if (from != null && from.isNotEmpty) params['from'] = from;
    if (to != null && to.isNotEmpty) params['to'] = to;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (method != null && method.isNotEmpty) params['method'] = method;
    final res = await ApiService.get<List<PaymentModel>>(
      ApiConstants.payments,
      queryParams: params,
      fromData: (d) => (d as List)
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<PaymentModel> getPayment(int id) async {
    final res = await ApiService.get<PaymentModel>(
      ApiConstants.paymentDetail(id),
      fromData: (d) {
        final data = d as Map<String, dynamic>;
        return PaymentModel.fromJson(
          (data['payment'] as Map<String, dynamic>?) ?? data,
        );
      },
    );
    return res.data!;
  }

  static Future<List<PaymentModel>> getPatientPayments(int patientId) async {
    final res = await ApiService.get<List<PaymentModel>>(
      ApiConstants.patientPayments(patientId),
      fromData: (d) => (d as List)
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }

  static Future<PaymentModel> createPayment(Map<String, dynamic> body) async {
    final res = await ApiService.post<Map<String, dynamic>>(
      ApiConstants.payments,
      body: body,
      fromData: (d) => d as Map<String, dynamic>,
    );
    if (!res.success) throw ApiException(message: res.message, statusCode: 400);
    final data = res.data ?? {};
    final payJson = data['payment'] as Map<String, dynamic>? ?? data;
    return PaymentModel.fromJson(payJson);
  }

  static Future<Map<String, dynamic>> getRevenueSummary(
      {String? from, String? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final res = await ApiService.get<Map<String, dynamic>>(
      ApiConstants.revenueSummary,
      queryParams: params.isEmpty ? null : params,
      fromData: (d) => d as Map<String, dynamic>,
    );
    return res.data ?? {};
  }
}
