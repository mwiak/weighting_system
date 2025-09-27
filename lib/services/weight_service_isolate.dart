import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:nativewrappers/_internal/vm/lib/isolate_patch.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:weighing_system/utils/debugging_methods.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'dart:isolate' as iso;

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
  external int Flags; // bitfields, treat as uint32 for simplicity

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

class WeightServiceTry extends ChangeNotifier {
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
  static List<String> _availablePorts = [];

  int _currentPortIndex = 0;
  late iso.ReceivePort _receivePort;
  iso.Isolate? isolate;
  //errors
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

  WeightServiceT() {
    // debugStatus();
    _startConnectionService();
  }

  Future<void> startIsolate() async {
    _receivePort = iso.ReceivePort();
    isolate = await iso.Isolate.spawn((v) {}, _receivePort.sendPort);

    _receivePort.listen((value) {});
  }

  void debugStatus() {
    Timer.periodic(const Duration(milliseconds: 100), (_) {
      printd(status.toString());
    });
  }

  void _startConnectionService() {
    debugPrint('WeightService: Starting connection service');
    if (status == ConnectionStatus.initial) {
      _connectionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (status == ConnectionStatus.initial ||
            status == ConnectionStatus.reconnecting) {
          printd('attempting to connect to port');
          _attemptConnection();
        }
      });
    }

    _readTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (status == ConnectionStatus.connected) {
        _readWeight();
      }
    });
  }

  Future<void> _attemptConnection() async {
    if (status == ConnectionStatus.connected) return;
    printd('attempting now');
    updateStatus(ConnectionStatus.scanning);

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

  Future<void> _autoDiscoverDevice() async {
    _availablePorts = SerialPort.availablePorts;
    if (_availablePorts.isNotEmpty) {
      for (String port in _availablePorts) {
        if (status != ConnectionStatus.connected) {
          printd('trying port $port');
          await _connectToPort(port);
        }
      }
    } else {
      printd('no port found');
      updateStatus(ConnectionStatus.notFound);
    }
  }

  Future<void> _connectToPort(String portName) async {
    if (Platform.isWindows) {
      printd('selection connect');
      await _connectWindows(portName);
    }
  }

  Future<void> _connectWindows(String portName) async {
    try {
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
        0,
        0,
        3, // OPEN_EXISTING
        0,
        0,
      );
      printd('handle: $handle');

      if (handle != -1) {
        printd('configuring...');
        if (await _configurePort(kernel32, handle)) {
          _comHandle = handle;
          _connectedPort = portName;
          _isConnected = true;
          updateStatus(ConnectionStatus.connected);
          printd('WeightService: Connected to $portName');
          notifyListeners();
        } else {
          lastError = 'config_error';
          updateStatus(ConnectionStatus.notFound);

          printd('failed configuring');
          final closeHandle = kernel32.lookupFunction<Int32 Function(IntPtr),
              int Function(int)>('CloseHandle');
          closeHandle(handle);
        }
      }

      calloc.free(portPath);
    } catch (e) {
      lastError = 'unknown_error';
      status = ConnectionStatus.hasError;
      debugPrint('WeightService: Failed to connect to $portName: $e');
    }
  }

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
      printd(
          "DCBlength = ${dcb.ref.DCBlength}, sizeOf<DCB>() = ${sizeOf<DCB>()}");
      // Fill in defaults
      if (getDcb(handle, dcb) == 0) {
        final err = getLastError();
        status = ConnectionStatus.replugError;
        printd('GetCommState failed: $err');
        lastError = err.toString();
        calloc.free(dcb);
        return false;
      }

      // Configure values
      dcb.ref.BaudRate = _baudRate; // e.g. 9600
      dcb.ref.ByteSize = _dataBits; // usually 8
      dcb.ref.Parity = _parity; // 0 = none
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

  void _readWeight() {
    if (status != ConnectionStatus.connected || _comHandle == null) return;

    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final readFile = kernel32.lookupFunction<
          Int32 Function(
              IntPtr, Pointer<Uint8>, Int32, Pointer<Uint32>, IntPtr),
          int Function(
              int, Pointer<Uint8>, int, Pointer<Uint32>, int)>('ReadFile');

      final buffer = calloc<Uint8>(64);
      final bytesRead = calloc<Uint32>(1);

      final result = readFile(_comHandle!, buffer, 64, bytesRead, 0);

      if (result != 0 && bytesRead.value > 0) {
        final data = String.fromCharCodes(buffer.asTypedList(bytesRead.value));
        printd("raw data string" + data);
        List lines = data.split('\n').toList();
        for (String line in lines) {
          printd("line is:" + line);
          printd("line lenght is:" + line.length.toString());
          if (line.length == 17) {
            final weight = _parseWeightFromData(line);
            if (weight != null) {
              printd('weight have been updated =================');
              _currentWeight = weight;
              notifyListeners();
            }
          }
        }
      }

      calloc.free(buffer);
      calloc.free(bytesRead);
    } catch (e) {
      debugPrint('WeightService: Error reading weight: $e');
      updateStatus(ConnectionStatus.hasError);

      _handleConnectionLost();
    }
  }

  void _readIsolateWeight() {
    if (status != ConnectionStatus.connected || _comHandle == null) return;

    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final readFile = kernel32.lookupFunction<
          Int32 Function(
              IntPtr, Pointer<Uint8>, Int32, Pointer<Uint32>, IntPtr),
          int Function(
              int, Pointer<Uint8>, int, Pointer<Uint32>, int)>('ReadFile');

      final buffer = calloc<Uint8>(64);
      final bytesRead = calloc<Uint32>(1);

      final result = readFile(_comHandle!, buffer, 64, bytesRead, 0);

      if (result != 0 && bytesRead.value > 0) {
        final data = String.fromCharCodes(buffer.asTypedList(bytesRead.value));
        printd("raw data string" + data);
        List lines = data.split('\n').toList();
        for (String line in lines) {
          printd("line is:" + line);
          printd("line lenght is:" + line.length.toString());
          if (line.length == 17) {
            final weight = _parseWeightFromData(line);
            if (weight != null) {
              printd('weight have been updated =================');
            }
          }
        }
      }

      calloc.free(buffer);
      calloc.free(bytesRead);
    } catch (e) {
      debugPrint('WeightService: Error reading weight: $e');
    }
  }

  int? _parseWeightFromData(String data) {
    try {
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

  void _handleConnectionLost() {
    if (_isConnected) {
      debugPrint('WeightService: Connection lost to $_connectedPort');
      lastError = 'disconnected';
      updateStatus(ConnectionStatus.disconnected);
      disconnect();
    }
  }

  void disconnect() {
    if (_comHandle != null && Platform.isWindows) {
      try {
        final kernel32 = DynamicLibrary.open('kernel32.dll');
        final closeHandle =
            kernel32.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
                'CloseHandle');
        closeHandle(_comHandle!);
        status = ConnectionStatus.disconnected;
      } catch (e) {
        debugPrint('WeightService: Error closing handle: $e');
        status = ConnectionStatus.hasError;
      }
    }

    _comHandle = null;
    _isConnected = false;
    _connectedPort = null;
    _currentWeight = 0;
    debugPrint('WeightService: Disconnected');
    notifyListeners();
  }

  void reconnect() async {
    disconnect();
    if (status == ConnectionStatus.reconnecting) return;
    updateStatus(ConnectionStatus.reconnecting);
  }

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
    _readTimer?.cancel();
    disconnect();
    super.dispose();
  }
}
