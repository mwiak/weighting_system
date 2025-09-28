import 'package:flutter/foundation.dart';
import 'package:weighing_system/services/weight_service_isolate.dart';

import 'package:weighing_system/utils/debugging_methods.dart';

class WeightProvider extends ChangeNotifier {
  final WeightServiceIsolate _weightService = WeightServiceIsolate();

  // Current weight data
  String? _connectedPort;
  String? _lastError;

  // Calibration and tare values
  int _tareWeight = 0;
  int _zeroCalibration = 0;

  // Getters
  int get currentWeight => _weightService.currentWeight;
  int get displayWeight =>
      _weightService.currentWeight - _tareWeight - _zeroCalibration;
  bool get isConnected => _weightService.isConnected;
  bool get isScanning => _weightService.isScanning;
  String? get connectedPort => _weightService.connectedPort;
  String? get lastError => _weightService.lastError;
  int get tareWeight => _tareWeight;
  int get zeroCalibration => _zeroCalibration;
  ConnectionStatus get status => _weightService.status;

  // Settings getters
  String get selectedPort => _weightService.selectedPort;
  int get baudRate => _weightService.baudRate;
  int get stopBits => _weightService.stopBits;
  int get dataBits => _weightService.dataBits;
  int get parity => _weightService.parity;

  WeightProvider() {
    _initializeService();
  }

  void _initializeService() {
    // Listen to weight service changes
    _weightService.addListener(_onWeightServiceChanged);
  }

  void _onWeightServiceChanged() {
    print('service is changed now');
    print(status);
    notifyListeners();
  }

  /// Reconnect to scale
  void reconnect() {
    _weightService.reconnect();
  }

  /// Manually disconnect
  void disconnect() {
    _weightService.disconnect();
  }

  /// Update scale connection settings
  void updateSettings({
    String? port,
    int? baudRate,
    int? stopBits,
    int? dataBits,
    int? parity,
  }) {
    _weightService.updateSettings(
      port: port,
      baudRate: baudRate,
      stopBits: stopBits,
      dataBits: dataBits,
      parity: parity,
    );
  }

  /// Get available ports for settings
  List<String> getAvailablePorts() {
    return _weightService.getAvailablePorts();
  }

  /// Get available baud rates
  List<int> getAvailableBaudRates() {
    return _weightService.getAvailableBaudRates();
  }

  /// Get available stop bits options
  List<int> getAvailableStopBits() {
    return _weightService.getAvailableStopBits();
  }

  /// Get available data bits options
  List<int> getAvailableDataBits() {
    return _weightService.getAvailableDataBits();
  }

  /// Get available parity options
  Map<int, String> getAvailableParityOptions() {
    return _weightService.getAvailableParityOptions();
  }

  /// Clear any error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    printd('on dispose called');
    _weightService.removeListener(_onWeightServiceChanged);
    disconnect();
    _weightService.dispose();
    super.dispose();
  }
}
