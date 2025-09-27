/// Order model - represents a completed weighing transaction
/// Note: Orders don't sync directly to Odoo. They create sale.order or purchase.order entries instead
class Order {
  final int id;
  final String orderNumber;
  final String operationType; // 'loading' or 'unloading'

  // Related IDs
  final int? clientId;
  final int? supplierId;
  final int? materialId;

  // Vehicle and driver info
  final String truckPlate;
  final String driverName;
  final String? driverLicense;

  // Weight measurements
  final double grossWeight;
  final double tareWeight;
  final double netWeight;

  // Financial data
  final double? unitPrice;
  final double? totalAmount;

  // Status and timestamps
  final String status; // 'draft', 'active', 'completed', 'cancelled'
  final String? weighInTime;
  final String? weighOutTime;
  final String? notes;
  final String createDate;
  final String writeDate;

  // Sync status for Odoo
  final int syncStatus; // 0=pending, 1=synced, 2=error
  final int? saleOrderId; // Reference to created sale.order in Odoo
  final int? purchaseOrderId; // Reference to created purchase.order in Odoo

  Order({
    required this.id,
    required this.orderNumber,
    required this.operationType,
    this.clientId,
    this.supplierId,
    this.materialId,
    required this.truckPlate,
    required this.driverName,
    this.driverLicense,
    required this.grossWeight,
    required this.tareWeight,
    required this.netWeight,
    this.unitPrice,
    this.totalAmount,
    required this.status,
    this.weighInTime,
    this.weighOutTime,
    this.notes,
    required this.createDate,
    required this.writeDate,
    this.syncStatus = 0,
    this.saleOrderId,
    this.purchaseOrderId,
  });

  /// Create Order from Map (for database/API compatibility)
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int,
      orderNumber: map['order_number'] as String,
      operationType: map['operation_type'] as String,
      clientId: map['client_id'] as int?,
      supplierId: map['supplier_id'] as int?,
      materialId: map['material_id'] as int?,
      truckPlate: map['truck_plate'] as String,
      driverName: map['driver_name'] as String,
      driverLicense: map['driver_license'] as String?,
      grossWeight: (map['gross_weight'] as num).toDouble(),
      tareWeight: (map['tare_weight'] as num).toDouble(),
      netWeight: (map['net_weight'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num?)?.toDouble(),
      totalAmount: (map['total_amount'] as num?)?.toDouble(),
      status: map['status'] as String,
      weighInTime: map['weigh_in_time'] as String?,
      weighOutTime: map['weigh_out_time'] as String?,
      notes: map['notes'] as String?,
      createDate: map['create_date'] as String,
      writeDate: map['write_date'] as String,
      syncStatus: map['sync_status'] as int? ?? 0,
      saleOrderId: map['sale_order_id'] as int?,
      purchaseOrderId: map['purchase_order_id'] as int?,
    );
  }

  /// Convert Order to Map (for database/API compatibility)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_number': orderNumber,
      'operation_type': operationType,
      'client_id': clientId,
      'supplier_id': supplierId,
      'material_id': materialId,
      'truck_plate': truckPlate,
      'driver_name': driverName,
      'driver_license': driverLicense,
      'gross_weight': grossWeight,
      'tare_weight': tareWeight,
      'net_weight': netWeight,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'status': status,
      'weigh_in_time': weighInTime,
      'weigh_out_time': weighOutTime,
      'notes': notes,
      'create_date': createDate,
      'write_date': writeDate,
      'sync_status': syncStatus,
      'sale_order_id': saleOrderId,
      'purchase_order_id': purchaseOrderId,
    };
  }

  @override
  String toString() {
    return 'Order{id: $id, orderNumber: $orderNumber, operationType: $operationType, netWeight: ${netWeight}kg}';
  }
}