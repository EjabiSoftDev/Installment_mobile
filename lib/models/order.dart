class Order {
  final int id;
  final int customerId;
  final int productId;
  final int statusId;
  final int statusLanguageId;
  final DateTime createdDate;
  final double totalAmount;
  final int numberOfMonths;
  final double installmentAmount;
  final String? notes;
  final DateTime? approvedDate;
  final String productSerial;
  final String statusName;
  final String productName;

  const Order({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.statusId,
    required this.statusLanguageId,
    required this.createdDate,
    required this.totalAmount,
    required this.numberOfMonths,
    required this.installmentAmount,
    this.notes,
    this.approvedDate,
    required this.productSerial,
    required this.statusName,
    required this.productName,
  });

  /// ---- Parsing helpers
  static double _toD(dynamic v) =>
      v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0);

  static int _toI(dynamic v) =>
      v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

  static DateTime? _toDt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  /// Factory: matches your JSON exactly
  factory Order.fromJson(Map<String, dynamic> j) {
    return Order(
      id: _toI(j['ID']),
      customerId: _toI(j['CustomerID']),
      productId: _toI(j['ProductID']),
      statusId: _toI(j['StatusID']),
      statusLanguageId: _toI(j['StatusLanguageID']),
      createdDate:
          DateTime.tryParse(j['CreatedDate']?.toString() ?? '') ?? DateTime.now(),
      totalAmount: _toD(j['TotalAmount']),
      numberOfMonths: _toI(j['NumberOfMonths']),
      installmentAmount: _toD(j['InstallmentAmount']),
      notes: j['Notes']?.toString(),
      approvedDate: _toDt(j['ApprovedDate']),
      productSerial: (j['ProductSerial'] ?? '').toString(),
      statusName: (j['StatusName'] ?? '').toString(),
      productName: (j['ProductName'] ?? '').toString(),
    );
  }

  /// Handy list parser for: { "orders": [ ... ] }
  static List<Order> listFromEnvelope(Map<String, dynamic> json) {
    final raw = json['orders'];
    if (raw is List) {
      return raw.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }

  /// copyWith for immutability ergonomics
  Order copyWith({
    int? id,
    int? customerId,
    int? productId,
    int? statusId,
    int? statusLanguageId,
    DateTime? createdDate,
    double? totalAmount,
    int? numberOfMonths,
    double? installmentAmount,
    String? notes,
    DateTime? approvedDate,
    String? productSerial,
    String? statusName,
    String? productName,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      statusId: statusId ?? this.statusId,
      statusLanguageId: statusLanguageId ?? this.statusLanguageId,
      createdDate: createdDate ?? this.createdDate,
      totalAmount: totalAmount ?? this.totalAmount,
      numberOfMonths: numberOfMonths ?? this.numberOfMonths,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      notes: notes ?? this.notes,
      approvedDate: approvedDate ?? this.approvedDate,
      productSerial: productSerial ?? this.productSerial,
      statusName: statusName ?? this.statusName,
      productName: productName ?? this.productName,
    );
  }

  @override
  String toString() =>
      'Order(id: $id, product: $productName, status: $statusName, total: $totalAmount)';
}
