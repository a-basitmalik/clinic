import 'payment_model.dart';

class BillModel {
  final int id;
  final String receiptNumber;
  final String type;
  final String status;
  final String method;
  final double amount;
  final double paidAmount;
  final String createdAt;

  const BillModel({
    required this.id,
    required this.receiptNumber,
    required this.type,
    required this.status,
    required this.method,
    required this.amount,
    required this.paidAmount,
    required this.createdAt,
  });

  factory BillModel.fromPayment(PaymentModel payment) => BillModel(
        id: payment.id,
        receiptNumber: payment.receiptNumber,
        type: payment.paymentType,
        status: payment.status,
        method: payment.paymentMethod,
        amount: payment.amount,
        paidAmount: payment.paidAmount,
        createdAt: payment.createdAt,
      );
}
