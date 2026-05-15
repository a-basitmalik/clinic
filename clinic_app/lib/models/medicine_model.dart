class MedicineModel {
  final int id;
  final String medicineName;
  final String? category;
  final String? batchNumber;
  final String? expiryDate;
  final double purchasePrice;
  final double salePrice;
  final int quantity;
  final String? supplier;
  final String? rackNumber;
  final int lowStockLimit;
  final String status;
  final String? createdAt;

  const MedicineModel({
    required this.id,
    required this.medicineName,
    this.category,
    this.batchNumber,
    this.expiryDate,
    required this.purchasePrice,
    required this.salePrice,
    required this.quantity,
    this.supplier,
    this.rackNumber,
    required this.lowStockLimit,
    required this.status,
    this.createdAt,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> j) => MedicineModel(
        id: _int(j['id']),
        medicineName: (j['medicine_name'] ?? j['name'] ?? '').toString(),
        category: j['category']?.toString(),
        batchNumber: j['batch_number']?.toString(),
        expiryDate: j['expiry_date']?.toString(),
        purchasePrice: _double(j['purchase_price']),
        salePrice: _double(j['sale_price'] ?? j['unit_price']),
        quantity: _int(j['quantity'] ?? j['available_stock']),
        supplier: j['supplier']?.toString(),
        rackNumber: j['rack_number']?.toString(),
        lowStockLimit: _int(j['low_stock_limit'] ?? j['min_stock']),
        status: (j['status'] ?? 'active').toString(),
        createdAt: j['created_at']?.toString(),
      );

  bool get isLowStock => quantity <= lowStockLimit;
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.tryParse(expiryDate!)?.isBefore(DateTime.now()) ?? false;
  }

  Map<String, dynamic> toPayload() => {
        'medicine_name': medicineName,
        'category': category,
        'batch_number': batchNumber,
        'expiry_date': expiryDate,
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'quantity': quantity,
        'supplier': supplier,
        'rack_number': rackNumber,
        'low_stock_limit': lowStockLimit,
        'status': status,
      };

  static int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
  static double _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
}
