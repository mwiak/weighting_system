import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:weighing_system/utils/debugging_methods.dart';

/// Weight Service for reading from scale devices
///
/// This service automatically discovers and connects to scale devices
/// on COM ports, continuously reads weight data, and provides a simple
/// interface for weight readings with connection status.
class WeightService extends ChangeNotifier {
  // Connection state
  bool _isConnected = false;
  bool _isScanning = false;
  String? _connectedPort;
  int _currentWeight = 0;

  // Timers
  Timer? _connectionTimer;
  Timer? _readTimer;

  // Settings
  String _selectedPort = 'auto';
  int _baudRate = 9600;
  int _stopBits = 1;
  int _dataBits = 8;
  int _parity = 0; // 0=none, 1=odd, 2=even

  // Platform-specific handles
  int? _comHandle;

  // Available ports for auto-discovery
  static const List<String> _availablePorts = [
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'COM10',
    'COM11',
    'COM12',
    'COM13',
    'COM14',
    'COM15',
    'COM16'
  ];

  // Current port being tested during auto-discovery
  int _currentPortIndex = 0;

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

  WeightService() {
    _startConnectionService();
  }

  /// Start the connection service that runs throughout the app lifecycle
  void _startConnectionService() {
    debugPrint('WeightService: Starting connection service');

    // Try to connect every 40ms as specified
    _connectionTimer = Timer.periodic(const Duration(milliseconds: 15), (_) {
      if (!_isConnected && !_isScanning) {
        printd('atempting to connect to port');
        _attemptConnection();
      }
    });

    // Read weight every 100ms when connected
    _readTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (_isConnected) {
        _readWeight();
      }
    });
  }

  /// Attempt to connect to a scale device
  Future<void> _attemptConnection() async {
    if (_isScanning) return;

    _isScanning = true;

    try {
      if (_selectedPort == 'auto') {
        await _autoDiscoverDevice();
      } else {
        await _connectToPort(_selectedPort);
      }
    } finally {
      _isScanning = false;
    }
  }

  /// Auto-discover scale device across all COM ports
  Future<void> _autoDiscoverDevice() async {
    // Try the next port in sequence
    if (_currentPortIndex >= _availablePorts.length) {
      _currentPortIndex = 0;
    }

    final portToTry = _availablePorts[_currentPortIndex];
    _currentPortIndex++;
    printd('port ${portToTry}');

    await _connectToPort(portToTry);
  }

  /// Connect to a specific COM port
  Future<void> _connectToPort(String portName) async {
    if (Platform.isWindows) {
      printd('selection connect');
      await _connectWindows(portName);
    }
  }

  /// Windows-specific COM port connection
  Future<void> _connectWindows(String portName) async {
    try {
      // Load Windows kernel32.dll
      final kernel32 = DynamicLibrary.open('kernel32.dll');

      // Define CreateFile function
      final createFile = kernel32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16>, Int32, Int32, IntPtr, Int32, Int32, IntPtr),
          int Function(
              Pointer<Utf16>, int, int, int, int, int, int)>('CreateFileW');

      // Convert port name to Windows format
      final portPath = '\\\\.\\$portName'.toNativeUtf16();

      // Try to open the port
      final handle = createFile(
        portPath,
        0xC0000000, // GENERIC_READ | GENERIC_WRITE
        0, // No sharing
        0, // No security attributes
        3, // OPEN_EXISTING
        0, // No file attributes
        0, // No template file
      );
      printd(handle.toString());

      // Check if handle is valid (not INVALID_HANDLE_VALUE which is -1)
      if (handle != -1) {
        // Successfully opened port - configure it
        printd('configuring');
        if (await _configurePort(kernel32, handle)) {
          _comHandle = handle;
          _connectedPort = portName;
          _isConnected = true;
          debugPrint('WeightService: Connected to $portName');
          notifyListeners();
        } else {
          // Close handle if configuration failed
          printd('failled');
          final closeHandle = kernel32.lookupFunction<Int32 Function(IntPtr),
              int Function(int)>('CloseHandle');
          closeHandle(handle);
        }
      }

      // Cleanup
      calloc.free(portPath);
    } catch (e) {
      debugPrint('WeightService: Failed to connect to $portName: $e');
    }
  }

  /// Configure COM port settings
  Future<bool> _configurePort(DynamicLibrary kernel32, int handle) async {
    try {
      // Get DCB (Device Control Block) functions
      final getDcb = kernel32.lookupFunction<Int32 Function(IntPtr, Pointer),
          int Function(int, Pointer)>('GetCommState');

      final setDcb = kernel32.lookupFunction<Int32 Function(IntPtr, Pointer),
          int Function(int, Pointer)>('SetCommState');

      // Allocate DCB structure (28 bytes for basic DCB)
      final dcb = calloc<Uint8>(28);

      // Get current DCB
      if (getDcb(handle, dcb) == 0) {
        calloc.free(dcb);
        return false;
      }

      // Set baud rate (offset 4, 4 bytes)
      dcb.cast<Uint32>().elementAt(1).value = _baudRate;

      // Set other parameters in the DCB flags (offset 8, 4 bytes)
      int flags = 0;
      flags |= 0x01; // Binary mode
      flags |= (_dataBits - 5) << 8; // Data bits
      flags |= _parity << 12; // Parity
      flags |= (_stopBits == 2 ? 2 : 0) << 14; // Stop bits

      dcb.cast<Uint32>().elementAt(2).value = flags;

      // Apply configuration
      final success = setDcb(handle, dcb) != 0;

      calloc.free(dcb);
      return success;
    } catch (e) {
      debugPrint('WeightService: Error configuring port: $e');
      return false;
    }
  }

  /// Read weight from the connected scale
  void _readWeight() {
    if (!_isConnected || _comHandle == null) return;

    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final readFile = kernel32.lookupFunction<
          Int32 Function(
              IntPtr, Pointer<Uint8>, Int32, Pointer<Uint32>, IntPtr),
          int Function(
              int, Pointer<Uint8>, int, Pointer<Uint32>, int)>('ReadFile');

      // Buffer for reading data
      final buffer = calloc<Uint8>(64);
      final bytesRead = calloc<Uint32>(1);

      // Read data from COM port
      final result = readFile(_comHandle!, buffer, 64, bytesRead, 0);

      if (result != 0 && bytesRead.value > 0) {
        // Convert bytes to string
        final data = String.fromCharCodes(buffer.asTypedList(bytesRead.value));

        // Parse weight from the data
        final weight = _parseWeightFromData(data.trim());
        if (weight != null) {
          _currentWeight = weight;
          notifyListeners();
        }
      }

      calloc.free(buffer);
      calloc.free(bytesRead);
    } catch (e) {
      debugPrint('WeightService: Error reading weight: $e');
      _handleConnectionLost();
    }
  }

  /// Parse weight from scale data
  /// Expected format: (- or +)(6 digit number)(KG)
  int? _parseWeightFromData(String data) {
    try {
      // Remove any non-relevant characters and find the weight pattern
      final RegExp weightRegex =
          RegExp(r'[+-]?\d{1,6}(?=\s*KG|$)', caseSensitive: false);
      final match = weightRegex.firstMatch(data);

      if (match != null) {
        final weightStr = match.group(0)!;
        final weight = int.tryParse(weightStr);
        if (weight != null && weight >= -999999 && weight <= 999999) {
          return weight;
        }
      }

      return null;
    } catch (e) {
      debugPrint('WeightService: Error parsing weight data "$data": $e');
      return null;
    }
  }

  /// Handle connection lost
  void _handleConnectionLost() {
    if (_isConnected) {
      debugPrint('WeightService: Connection lost to $_connectedPort');
      disconnect();
    }
  }

  /// Manually disconnect from the current port
  void disconnect() {
    if (_comHandle != null && Platform.isWindows) {
      try {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final closeHandle =
            kernel32.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
                'CloseHandle');
        closeHandle(_comHandle!);
      } catch (e) {
        debugPrint('WeightService: Error closing handle: $e');
      }
    }

    _comHandle = null;
    _isConnected = false;
    _connectedPort = null;
    _currentWeight = 0;
    debugPrint('WeightService: Disconnected');
    notifyListeners();
  }

  /// Force reconnection attempt
  void reconnect() {
    disconnect();
    // Connection will be attempted automatically by the timer
  }

  /// Update port settings
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
      _currentPortIndex = 0; // Reset auto-discovery
      needsReconnect = true;
    }

    if (baudRate != null && baudRate != _baudRate) {
      _baudRate = baudRate;
      needsReconnect = true;
    }

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

    if (needsReconnect && _isConnected) {
      disconnect();
    }

    notifyListeners();
  }

  /// Get list of available ports for settings UI
  List<String> getAvailablePorts() {
    return ['auto', ..._availablePorts];
  }

  /// Get available baud rates
  List<int> getAvailableBaudRates() {
    return [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200];
  }

  /// Get available stop bits options
  List<int> getAvailableStopBits() {
    return [1, 2];
  }

  /// Get available data bits options
  List<int> getAvailableDataBits() {
    return [5, 6, 7, 8];
  }

  /// Get available parity options
  Map<int, String> getAvailableParityOptions() {
    return {
      0: 'None',
      1: 'Odd',
      2: 'Even',
    };
  }

  @override
  void dispose() {
    debugPrint('WeightService: Disposing service');
    _connectionTimer?.cancel();
    _readTimer?.cancel();
    disconnect();
    super.dispose();
  }
}
