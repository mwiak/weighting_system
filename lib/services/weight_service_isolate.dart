import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate'; // Required for Isolate communication
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:weighing_system/utils/debugging_methods.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

// -----------------------------------------------------------------
// TOP-LEVEL ISOLATE FUNCTION
// -----------------------------------------------------------------

/// This function runs in a separate Isolate.
/// It's a top-level function, not a method of the class.
/// It continuously reads from the serial port and sends parsed data back to the main app.
void _readLoop(Map<String, dynamic> args) {
  final SendPort sendPort = args['sendPort'];
  final int comHandle = args['comHandle'];

  final kernel32 = DynamicLibrary.open('kernel32.dll');
  final readFile = kernel32.lookupFunction<
      Int32 Function(IntPtr, Pointer<Uint8>, Int32, Pointer<Uint32>, IntPtr),
      int Function(int, Pointer<Uint8>, int, Pointer<Uint32>, int)>('ReadFile');

  final buffer = calloc<Uint8>(64);
  final bytesRead = calloc<Uint32>(1);

  while (true) {
    // This is a BLOCKING call. The Isolate will sleep here until data arrives.
    final result = readFile(comHandle, buffer, 64, bytesRead, 0);

    if (result != 0 && bytesRead.value > 0) {
      final data = String.fromCharCodes(buffer.asTypedList(bytesRead.value));

      try {
        final lines = data.trim().split('\n');
        if (lines.isEmpty) continue;

        for (final line in lines.reversed) {
          if (line.length == 17) {
            // Your specific check for a valid data line
            // Your original parsing logic
            final RegExp weightRegex =
                RegExp(r'[+-]?\d{1,6}(?=\s*KG|$)', caseSensitive: false);
            final match = weightRegex.firstMatch(line);
            if (match != null) {
              final weightStr = match.group(0)!;
              final weight = int.tryParse(weightStr);
              if (weight != null && weight >= -999999 && weight <= 999999) {
                // Send the valid weight back to the main thread
                sendPort.send(weight);
                break; // Found the last valid weight in this batch
              }
            }
          }
        }
      } catch (e) {
        // sendPort.send({'error': e.toString()});
      }
    } else {
      // ReadFile failed, connection might be lost.
      sendPort.send({'error': 'Connection lost during read'});
      break;
    }
  }

  calloc.free(buffer);
  calloc.free(bytesRead);
}

// -----------------------------------------------------------------
// ENUMS AND STRUCT DEFINITIONS (Unchanged)
// -----------------------------------------------------------------
enum WeightServiceError {
  portNotFound,
  configurationFailed,
  connectionLost,
  parseError,
  accessDenied,
  // etc.
}

enum ConnectionStatus {
  initial,
  notFound,
  hasError,
  replugError,
  disconnected,
  scanning,
  connecting,
  configuring,
  connected,
  reconnecting,
  error
}

/// Define the DCB struct from WinAPI
final class DCB extends Struct {
  @Uint32()
  external int DCBlength;
  @Uint32()
  external int BaudRate;
  @Uint32()
  external int Flags;
  @Uint16()
  external int wReserved;
  @Uint16()
  external int XonLim;
  @Uint16()
  external int XoffLim;
  @Uint8()
  external int ByteSize;
  @Uint8()
  external int Parity;
  @Uint8()
  external int StopBits;
  @Int8()
  external int XonChar;
  @Int8()
  external int XoffChar;
  @Int8()
  external int ErrorChar;
  @Int8()
  external int EofChar;
  @Int8()
  external int EvtChar;
  @Uint16()
  external int wReserved1;
}

// -----------------------------------------------------------------
// WEIGHT SERVICE CLASS
// -----------------------------------------------------------------

class WeightServiceIsolate extends ChangeNotifier {
  // Connection state
  ConnectionStatus status = ConnectionStatus.initial;
  void updateStatus(ConnectionStatus newState) {
    status = newState;
    notifyListeners();
  }

  bool _isConnected = false;
  bool _isScanning = false;
  String? _connectedPort;
  int _currentWeight = 0;

  // Timers
  Timer? _connectionTimer;
  // Timer? _readTimer; // REMOVED

  // Isolate communication
  Isolate? _readIsolate;
  ReceivePort? _receivePort;

  // Settings (These are the defaults you had)
  String _selectedPort = 'auto';
  int _baudRate = 9600;
  int _stopBits = 1;
  int _dataBits = 8;
  int _parity = 0; // 0=none

  // Platform-specific handles
  int? _comHandle;

  // Available ports
  static List<String> _availablePorts = [];
  int _currentPortIndex = 0;
  String? lastError;

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

  WeightServiceIsolate() {
    _startConnectionService();
  }

  void _startConnectionService() {
    debugPrint('WeightService: Starting connection service');
    if (status == ConnectionStatus.initial) {
      _connectionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (status == ConnectionStatus.initial ||
            status == ConnectionStatus.reconnecting) {
          _attemptConnection();
        }
      });
    }
  }

  Future<void> _attemptConnection() async {
    if (status == ConnectionStatus.connected) return;
    updateStatus(ConnectionStatus.scanning);
    try {
      if (_selectedPort == 'auto') {
        printd('auto discovery on!');
        await _autoDiscoverDevice();
      } else {
        await _connectToPort(_selectedPort);
      }
    } finally {
      _isScanning = false;
    }
  }

  Future<void> _autoDiscoverDevice() async {
    _availablePorts = SerialPort.availablePorts;
    if (_availablePorts.isNotEmpty) {
      for (String port in _availablePorts) {
        if (status != ConnectionStatus.connected) {
          printd('found a port!');
          await _connectToPort(port);
        }
      }
    } else {
      updateStatus(ConnectionStatus.notFound);
    }
  }

  Future<void> _connectToPort(String portName) async {
    if (Platform.isWindows) {
      await _connectWindows(portName);
    }
  }

  Future<void> _connectWindows(String portName) async {
    try {
      printd('trying to connect');
      final kernel32 = DynamicLibrary.open('kernel32.dll');

      final createFile = kernel32.lookupFunction<
          IntPtr Function(
              Pointer<Utf16>, Int32, Int32, IntPtr, Int32, Int32, IntPtr),
          int Function(
              Pointer<Utf16>, int, int, int, int, int, int)>('CreateFileW');

      final portPath = '\\\\.\\$portName'.toNativeUtf16();

      final handle = createFile(
        portPath,
        0xC0000000, // GENERIC_READ | GENERIC_WRITE
        0, 0, 3, // OPEN_EXISTING
        0, 0,
      );

      if (handle != -1) {
        printd('handle created');
        // ** HERE ** We call your original, correct _configurePort method
        if (await _configurePort(kernel32, handle)) {
          _comHandle = handle;
          _connectedPort = portName;
          _isConnected = true;
          updateStatus(ConnectionStatus.connected);
          printd('WeightService: Connected to $portName');

          _startReadIsolate(); // Start the isolate

          notifyListeners();
        } else {
          lastError = 'config_error';
          updateStatus(ConnectionStatus.hasError);
          final closeHandle = kernel32.lookupFunction<Int32 Function(IntPtr),
              int Function(int)>('CloseHandle');
          closeHandle(handle);
        }
      } else {
        updateStatus(ConnectionStatus.hasError);
        printd('could not open handle');
      }
      calloc.free(portPath);
    } catch (e) {
      lastError = 'unknown_error';
      status = ConnectionStatus.hasError;
      debugPrint('WeightService: Failed to connect to $portName: $e');
    }
  }

  // ** THIS IS YOUR ORIGINAL, CORRECT METHOD, FULLY RESTORED **
  Future<bool> _configurePort(DynamicLibrary kernel32, int handle) async {
    try {
      final getDcb = kernel32.lookupFunction<
          Int32 Function(IntPtr, Pointer<DCB>),
          int Function(int, Pointer<DCB>)>('GetCommState');

      final setDcb = kernel32.lookupFunction<
          Int32 Function(IntPtr, Pointer<DCB>),
          int Function(int, Pointer<DCB>)>('SetCommState');

      final getLastError = kernel32
          .lookupFunction<Uint32 Function(), int Function()>('GetLastError');

      final dcb = calloc<DCB>();
      dcb.ref.DCBlength = sizeOf<DCB>(); // ✅ must set before GetCommState

      // Fill in defaults
      if (getDcb(handle, dcb) == 0) {
        final err = getLastError();
        status = ConnectionStatus.replugError;
        printd('GetCommState failed: $err');
        lastError = err.toString();
        calloc.free(dcb);
        return false;
      }

      // Configure values from our service state
      dcb.ref.BaudRate = _baudRate;
      dcb.ref.ByteSize = _dataBits;
      dcb.ref.Parity = _parity;
      dcb.ref.StopBits = (_stopBits == 2 ? 2 : 0); // 0=1 stop, 2=2 stops

      // Enable binary mode
      dcb.ref.Flags |= 1; // fBinary

      // Apply
      final success = setDcb(handle, dcb) != 0;
      if (!success) {
        final err = getLastError();
        updateStatus(ConnectionStatus.replugError);
        printd('SetCommState failed: $err');
      }

      calloc.free(dcb);
      return success;
    } catch (e) {
      debugPrint('WeightService: Error configuring port: $e');
      return false;
    }
  }
  // ** END OF RESTORED METHOD **

  void _startReadIsolate() {
    if (_readIsolate != null) return;

    _receivePort = ReceivePort();
    _receivePort!.listen((message) {
      if (message is int) {
        // We received a valid weight
        if (_currentWeight != message) {
          _currentWeight = message;
          notifyListeners();
        }
      } else if (message is Map && message.containsKey('error')) {
        // We received an error from the isolate
        debugPrint(
            'WeightService: Error from read isolate: ${message['error']}');
        _handleConnectionLost();
      }
    });

    Isolate.spawn(
      _readLoop,
      {
        'sendPort': _receivePort!.sendPort,
        'comHandle': _comHandle!,
      },
    ).then((isolate) {
      _readIsolate = isolate;
      printd('WeightService: Read isolate started.');
    });
  }

  void _stopReadIsolate() {
    if (_readIsolate != null) {
      _readIsolate!.kill(priority: Isolate.immediate);
      _readIsolate = null;
      printd('WeightService: Read isolate stopped.');
    }
    _receivePort?.close();
    _receivePort = null;
  }

  void _handleConnectionLost() {
    if (_isConnected) {
      debugPrint('WeightService: Connection lost to $_connectedPort');
      lastError = 'disconnected';
      updateStatus(ConnectionStatus.disconnected);
      disconnect();
    }
  }

  void disconnect() {
    _stopReadIsolate(); // Stop the isolate first

    if (_comHandle != null && Platform.isWindows) {
      try {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final closeHandle =
            kernel32.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
                'CloseHandle');
        closeHandle(_comHandle!);
      } catch (e) {
        debugPrint('WeightService: Error closing handle: $e');
        status = ConnectionStatus.hasError;
      }
    }

    _comHandle = null;
    _isConnected = false;
    _connectedPort = null;
    _currentWeight = 0;
    if (status != ConnectionStatus.disconnected) {
      updateStatus(ConnectionStatus.disconnected);
    }
    debugPrint('WeightService: Disconnected');
    notifyListeners();
  }

  void reconnect() async {
    disconnect();
    if (status == ConnectionStatus.reconnecting) return;
    updateStatus(ConnectionStatus.reconnecting);
  }

  // --- Other methods (unchanged) ---

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
      _currentPortIndex = 0;
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

  List<String> getAvailablePorts() => ['auto', ..._availablePorts];
  List<int> getAvailableBaudRates() =>
      [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200];
  List<int> getAvailableStopBits() => [1, 2];
  List<int> getAvailableDataBits() => [5, 6, 7, 8];
  Map<int, String> getAvailableParityOptions() =>
      {0: 'None', 1: 'Odd', 2: 'Even'};

  @override
  void dispose() {
    debugPrint('WeightService: Disposing service');
    _connectionTimer?.cancel();
    disconnect();
    super.dispose();
  }
}
