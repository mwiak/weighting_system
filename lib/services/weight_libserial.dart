import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import '../utils/debugging_methods.dart';

class WeightServiceLibserial extends ChangeNotifier {
  // Connection state
  bool _isConnected = false;
  bool _isScanning = false;
  String? _connectedPort;
  int _currentWeight = 0;
  bool _isDisposed = false; // FIX: Flag to stop async operations on dispose

  // Serial port and stream subscription
  SerialPort? _serialPort;
  StreamSubscription<Uint8List>? _dataSubscription;

  // Settings - with default values
  String _selectedPort = 'auto';
  int _baudRate = 9600;
  int _stopBits = 1;
  int _dataBits = 8;
  int _parity = SerialPortParity.none; // Use the library's enum indices

  /// Getters
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  String? get connectedPort => _connectedPort;
  int get currentWeight => _currentWeight;
  String get selectedPort => _selectedPort;
  int get baudRate => _baudRate;
  int get stopBits => _stopBits;
  int get dataBits => _dataBits;
  int get parity => _parity;

  WeightServiceLib() {
    // Start the connection process once, it will manage itself.
    _connectionLoop();
  }

  /// FIX: Replaced the Timer with a more robust, self-managing connection loop
  /// This prevents race conditions where multiple connection attempts could run simultaneously.
  Future<void> _connectionLoop() async {
    while (!_isConnected && !_isDisposed) {
      await _attemptConnection();

      // If connection fails, wait before retrying to avoid spamming connection attempts.
      if (!_isConnected && !_isDisposed) {
        await Future.delayed(const Duration(milliseconds: 5000));
      }
    }
  }

  /// Attempts to connect either to a specific port or by auto-discovering.
  Future<void> _attemptConnection() async {
    List<String> portsToTry;

    if (_selectedPort == 'auto') {
      // FIX: Use the library to get REAL available ports instead of a hardcoded list.
      // This is more reliable and works on all platforms.
      portsToTry = SerialPort.availablePorts;
      if (portsToTry.isEmpty) {
        debugPrint('WeightService: No serial ports found.');
        return;
      }
    } else {
      portsToTry = [_selectedPort];
    }

    for (final portName in portsToTry) {
      if (_isConnected || _isDisposed) {
        break;
      } // Stop if we've connected or disposed

      await _connectToPort(portName);
    }
  }

  /// Connects to a single, specific port.
  Future<void> _connectToPort(String portName) async {
    // Ensure any previous connection is fully closed before opening a new one.
    await _disconnectInternal();

    debugPrint('WeightService: Attempting to connect to $portName...');
    try {
      printd(_baudRate.toString());
      _serialPort = SerialPort(portName);
      final config = SerialPortConfig()
        ..baudRate = _baudRate
        ..bits = _dataBits
        ..stopBits = _stopBits
        ..parity = _parity;

      if (_serialPort!.open(mode: 1)) {
        _serialPort!.config = config;
        _isConnected = true;
        _isScanning = false;
        _connectedPort = portName;
        debugPrint('WeightService: Successfully connected to $portName');
        notifyListeners(); // FIX: Notify UI about the successful connection

        // FIX: Handle disconnection events properly using onDone and onError
        final reader = SerialPortReader(_serialPort!);
        _dataSubscription = reader.stream.listen((data) {
          // Use utf8.decode with allowMalformed: true to prevent errors with partial data
          final receivedString = utf8.decode(data, allowMalformed: true).trim();
          _parseAndUpdateWeight(receivedString);
        }, onDone: () {
          debugPrint('WeightService: Disconnected (onDone) from $portName');
          _handleDisconnection();
        }, onError: (error) {
          debugPrint('WeightService: Error on port $portName: $error');
          _handleDisconnection();
        });
      } else {
        // This is a cleaner way to handle open failures.
        debugPrint(
            'WeightService: Failed to open port $portName. Code:, Message: ${SerialPort.lastError?.message}');
        _serialPort?.dispose();
        _serialPort = null;
      }
    } catch (e) {
      debugPrint('WeightService: Exception while connecting to $portName: $e');
      _serialPort?.dispose();
      _serialPort = null;
    }
  }

  /// Parses the incoming string data and updates the weight.
  void _parseAndUpdateWeight(String data) {
    // This regex looks for a sequence of digits (possibly with a sign)
    // that is followed by "KG" or is at the end of the data.
    final RegExp weightRegex =
        RegExp(r'[+-]?\d{1,6}(?=\s*KG|$)', caseSensitive: false);
    final match = weightRegex.firstMatch(data);

    if (match != null) {
      final weightStr = match.group(0)!;
      final weight = int.tryParse(weightStr);
      if (weight != null) {
        _currentWeight = weight;
        notifyListeners();
      }
    }
  }

  /// FIX: Centralized disconnection handler to be called from multiple places.
  void _handleDisconnection() {
    if (!_isConnected) return; // Avoid redundant calls
    _disconnectInternal();
    _connectionLoop(); // Restart the connection loop to auto-reconnect
  }

  /// Updates settings and triggers a reconnection.
  void updateSettings({
    String? port,
    int? baudRate,
    int? stopBits,
    int? dataBits,
    int? parity,
  }) {
    bool needsReconnect = false;

    if (port != null && port != _selectedPort) {
      _selectedPort = port;
      needsReconnect = true;
    }
    if (baudRate != null && baudRate != _baudRate) {
      _baudRate = baudRate;
      needsReconnect = true;
    }
    // ... other settings checks
    if (stopBits != null && stopBits != _stopBits) {
      _stopBits = stopBits;
      needsReconnect = true;
    }
    if (dataBits != null && dataBits != _dataBits) {
      _dataBits = dataBits;
      needsReconnect = true;
    }
    if (parity != null && parity != _parity) {
      _parity = parity;
      needsReconnect = true;
    }

    if (needsReconnect) {
      // Disconnect and let the connection loop restart with the new settings.
      _handleDisconnection();
    }
    notifyListeners();
  }

  /// Public method to disconnect.
  Future<void> disconnect() async {
    if (_isDisposed) return;
    _isDisposed = true; // Signal to stop the connection loop
    await _disconnectInternal();
  }

  /// FIX: Internal method for cleanup to avoid code duplication.
  Future<void> _disconnectInternal() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    try {
      _serialPort?.close();
    } catch (e) {
      debugPrint('WeightService: Error closing port: $e');
    }
    _serialPort?.dispose();
    _serialPort = null;

    if (_isConnected) {
      _isConnected = false;
      _connectedPort = null;
      _currentWeight = 0;
      notifyListeners();
    }
  }

  /// Helper functions for settings UI
  List<String> getAvailablePorts() => ['auto', ...SerialPort.availablePorts];
  List<int> getAvailableBaudRates() =>
      [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200];
  List<int> getAvailableStopBits() => [1, 2];
  List<int> getAvailableDataBits() => [5, 6, 7, 8];
  Map<int, String> getAvailableParityOptions() => {
        SerialPortParity.none: 'None',
        SerialPortParity.odd: 'Odd',
        SerialPortParity.even: 'Even',
      };

  @override
  void dispose() {
    _isDisposed = true;
    _disconnectInternal();
    super.dispose();
  }
}
