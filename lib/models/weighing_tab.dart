import 'package:flutter/foundation.dart';

extension PriceSum on List<WeighingTab> {
  num get totalPrice => fold(0.0, (sum, tab) => sum + tab.total_price);
}

extension NetWeightSum on List<WeighingTab> {
  int get totalWeight => fold(0, (sum, tab) => sum + tab.netWeight);
}

extension SortWeightDesc on List<WeighingTab> {
  void sortWeightList() {
    sort((a, b) => b.grossWeight - a.grossWeight);
  }
}

extension SortMapWeightDesc on Map<String, List<WeighingTab>> {
  Map<String, List<WeighingTab>> sortWeightMap() {
    Map<String, List<WeighingTab>> result = {};
    List<Map<String, int>> sotred = [];
    if (isEmpty) {
      return {};
    }
    for (String key in keys) {
      sotred.add({key: this[key]!.totalWeight});
    }
    sotred.sort((a, b) => b.values.first - a.values.first);
    for (Map<String, int> x in sotred) {
      result[x.keys.first] = this[x.keys.first]!;
    }
    return result;
  }
}

//Map<String, List<WeighingTab>>

class WeighingTab {
  int? id; // Database ID (null until persisted)

  WeighingTab(); // Default constructor

  // Weight fields
  int emptyWeight = 0;
  int grossWeight = 0;

  DateTime? scaleEmptyWeightAt;
  DateTime? scaleGrossWeightAt;

  // Vehicle and driver
  String truckPlate = '';
  String driverName = '';

  // Business data
  // 'loading' or 'unloading'
  String supplier = '';
  String client = '';

  String material = '';

  num kilo_price = 0.0;
  num total_price = 0.0;

  String notes = '';

  bool isPaid = false;
  bool showPriceOnPrint = false;

  // Internal state
  bool hasUnsavedChanges = false;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  String status = 'in-progress'; // 'in-progress', 'completed', 'cancelled'

  // locking mechanism
  bool isLocked = false;

  void setIsLocked(bool v) {
    isLocked = v;
  }

  bool get canLock {
    bool hasAnyWeight =
        scaleGrossWeightAt != null || scaleEmptyWeightAt != null;
    bool hasDestination = supplier.isNotEmpty || client.isNotEmpty;
    return hasAnyWeight && hasDestination;
  }

  // Computed properties
  int get netWeight => (grossWeight != 0 && emptyWeight != 0)
      ? (grossWeight - emptyWeight).abs()
      : 0;

  String get tabTitle {
    if (supplier.isNotEmpty) {
      return supplier;
    }
    if (client.isNotEmpty) {
      return client;
    }
    if (driverName.isNotEmpty) {
      return driverName;
    } else if (truckPlate.isNotEmpty) {
      return truckPlate;
    }
    return 'عملية ${id ?? 'جديد'}';
  }

  bool get isComplete {
    return emptyWeight > 0 &&
        grossWeight > 0 &&
        truckPlate.isNotEmpty &&
        driverName.isNotEmpty &&
        (supplier.isNotEmpty ^
            client.isNotEmpty) && // XOR: exactly one must be filled
        material.isNotEmpty;
  }

  bool get isInProgress {
    return status == 'in-progress';
  }

  bool get isCompleted {
    return status == 'completed';
  }

  bool get isCancelled {
    return status == 'cancelled';
  }

  bool get hasData {
    return emptyWeight > 0 ||
        grossWeight > 0 ||
        truckPlate.isNotEmpty ||
        driverName.isNotEmpty ||
        supplier.isNotEmpty ||
        client.isNotEmpty ||
        material.isNotEmpty;
  }

  void updateStatus() {
    // Don't auto-update if already completed or cancelled
    if (status == 'completed' || status == 'cancelled') {
      return;
    }

    // Always keep as in-progress until explicitly completed or cancelled
    if (status != 'in-progress') {
      status = 'in-progress';
      updatedAt = DateTime.now();
      hasUnsavedChanges = true;
    }
  }

  void completeTab() {
    // Only allow completion if tab is in-progress and meets completion criteria
    if (status == 'in-progress' && isComplete) {
      status = 'completed';
      updatedAt = DateTime.now();
      hasUnsavedChanges = true;
    } else if (status != 'in-progress') {
      debugPrint('WeighingTab: Cannot complete tab - invalid status: $status');
    } else {
      debugPrint('WeighingTab: Cannot complete tab - missing required fields');
    }
  }

  void cancelTab() {
    // Only allow cancellation if tab is not already completed
    if (status != 'completed') {
      status = 'cancelled';
      updatedAt = DateTime.now();
      hasUnsavedChanges = true;
    } else {
      debugPrint('WeighingTab: Cannot cancel completed tab');
    }
  }

  /// Validate status transition
  bool canTransitionTo(String newStatus) {
    switch (status) {
      case 'in-progress':
        // In-progress can transition to completed or cancelled
        return newStatus == 'completed' || newStatus == 'cancelled';
      case 'completed':
        // Completed tabs cannot transition to any other state
        return false;
      case 'cancelled':
        // Cancelled tabs can only be reopened to in-progress
        return newStatus == 'in-progress';
      default:
        // Unknown status, allow transition to in-progress
        return newStatus == 'in-progress';
    }
  }

  /// Reset a cancelled tab back to in-progress (for reuse)
  void reopenTab() {
    if (status == 'cancelled') {
      status = 'in-progress';
      updatedAt = DateTime.now();
      hasUnsavedChanges = true;
    } else {
      debugPrint('WeighingTab: Can only reopen cancelled tabs');
    }
  }

  void markAsSaved() {
    hasUnsavedChanges = false;
  }

  void markAsChanged() {
    hasUnsavedChanges = true;
    updatedAt = DateTime.now();
  }

  // Helper methods for mutual exclusivity
  void setClient(String clientName) {
    client = clientName;
    if (clientName.isNotEmpty) {
      supplier = ''; // Clear supplier when client is set
    }
    markAsChanged();
  }

  void setSupplier(String supplierName) {
    supplier = supplierName;
    if (supplierName.isNotEmpty) {
      client = ''; // Clear client when supplier is set
    }
    markAsChanged();
  }

  void reset() {
    emptyWeight = 0;
    grossWeight = 0;
    truckPlate = '';
    driverName = '';

    supplier = '';
    client = '';
    material = '';
    kilo_price = 0.0;
    total_price = 0.0;
    isPaid = false;
    showPriceOnPrint = true;
    hasUnsavedChanges = false;
    status = 'in-progress';
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Only include for updates, null for inserts
      'empty_weight': emptyWeight,
      'scale_empty_weight': scaleEmptyWeightAt?.toIso8601String() ?? '',
      'gross_weight': grossWeight,
      'scale_gross_weight': scaleGrossWeightAt?.toIso8601String() ?? '',
      'net_weight': netWeight,
      'truck_plate': truckPlate,
      'driver_name': driverName,
      'supplier': supplier,
      'client': client,
      'material': material,
      'kilo_price': kilo_price,
      'total_price': total_price,
      'notes': notes,
      'is_paid': isPaid ? 1 : 0,
      'show_price_on_print': showPriceOnPrint ? 1 : 0,
      'has_unsaved_changes': hasUnsavedChanges ? 1 : 0,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WeighingTab.fromMap(Map<String, dynamic> map) {
    final tab = WeighingTab();
    tab.id = map['id'] as int?;
    tab.emptyWeight = (map['empty_weight'] as num?)?.toInt() ?? 0;
    tab.scaleEmptyWeightAt = map['scale_empty_weight'] != null &&
            (map['scale_empty_weight'] as String).isNotEmpty
        ? DateTime.parse(map['scale_empty_weight'] as String)
        : null;
    tab.grossWeight = (map['gross_weight'] as num?)?.toInt() ?? 0;
    tab.scaleGrossWeightAt = map['scale_gross_weight'] != null &&
            (map['scale_gross_weight'] as String).isNotEmpty
        ? DateTime.parse(map['scale_gross_weight'] as String)
        : null;
    tab.truckPlate = map['truck_plate'] as String? ?? '';
    tab.driverName = map['driver_name'] as String? ?? '';

    tab.supplier = map['supplier'] as String? ?? '';
    tab.client = map['client'] as String? ?? '';
    tab.material = map['material'] as String? ?? '';
    tab.notes = map['notes'] as String? ?? '';
    tab.kilo_price = map['kilo_price'] as num? ?? 0.0;
    tab.total_price = map['total_price'] as num? ?? 0.0;
    tab.isPaid = (map['is_paid'] as int?) == 1;
    tab.showPriceOnPrint = (map['show_price_on_print'] as int?) == 1;
    tab.hasUnsavedChanges = false; // Always start as saved when loaded from DB
    tab.status = map['status'] as String? ?? 'in-progress';

    if (map['created_at'] != null) {
      tab.createdAt = DateTime.parse(map['created_at'] as String);
    }
    if (map['updated_at'] != null) {
      tab.updatedAt = DateTime.parse(map['updated_at'] as String);
    }

    return tab;
  }

  @override
  String toString() {
    return 'WeighingTab{id: $id, truckPlate: $truckPlate, status: $status, netWeight: ${netWeight}kg}';
  }
}
