import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WeightReading {
  final double weight;
  final bool isStable;
  final DateTime timestamp;
  final String unit;

  WeightReading({
    required this.weight,
    required this.isStable,
    required this.timestamp,
    this.unit = 'kg',
  });

  @override
  String toString() => 'WeightReading(weight: $weight$unit, stable: $isStable)';
}

enum SerialConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class SerialCommunicationService {
  static const String defaultPortName = 'COM3';
  static const int defaultBaudRate = 9600;
  static const int defaultDataBits = 8;
  static const int defaultStopBits = DCB_STOP_BITS.ONESTOPBIT;
  static const int defaultParity = DCB_PARITY.NOPARITY;

  int _hComm = INVALID_HANDLE_VALUE;
  StreamController<WeightReading>? _weightStreamController;
  StreamController<SerialConnectionStatus>? _statusStreamController;
  Timer? _readTimer;
  bool _isReading = false;

  String _portName = defaultPortName;
  SerialConnectionStatus _connectionStatus =
      SerialConnectionStatus.disconnected;

  // Weight stability tracking
  final List<double> _recentReadings = [];
  static const int _stabilityBufferSize = 5;
  static const double _stabilityThreshold = 0.5; // kg

  // Error handling
  String? _lastError;

  Stream<WeightReading> get weightStream =>
      _weightStreamController?.stream ?? const Stream.empty();
  Stream<SerialConnectionStatus> get statusStream =>
      _statusStreamController?.stream ?? const Stream.empty();

  SerialConnectionStatus get connectionStatus => _connectionStatus;
  String? get lastError => _lastError;
  String get portName => _portName;

  SerialCommunicationService() {
    _weightStreamController = StreamController<WeightReading>.broadcast();
    _statusStreamController =
        StreamController<SerialConnectionStatus>.broadcast();
  }

  Future<bool> connect({String? portName, int? baudRate}) async {
    if (_connectionStatus == SerialConnectionStatus.connected ||
        _connectionStatus == SerialConnectionStatus.connecting) {
      return _connectionStatus == SerialConnectionStatus.connected;
    }

    _setConnectionStatus(SerialConnectionStatus.connecting);
    _lastError = null;

    try {
      _portName = portName ?? defaultPortName;
      String actualPortName = _portName;
      if (_portName.startsWith('COM')) {
        final numStr = _portName.substring(3);
        final num = int.tryParse(numStr);
        if (num != null && num >= 10) {
          actualPortName = r'\\.\' + _portName;
        }
      }
      final portNamePtr = actualPortName.toNativeUtf16();

      // Open the serial port
      _hComm = CreateFile(
        portNamePtr,
        GENERIC_READ | GENERIC_WRITE,
        0, // No sharing
        nullptr, // Default security attributes
        OPEN_EXISTING,
        0, // No flags
        0, // No template - FIX #1
      );

      free(portNamePtr);

      if (_hComm == INVALID_HANDLE_VALUE) {
        final error = GetLastError();
        _lastError = 'Failed to open $_portName. Error code: $error';
        _setConnectionStatus(SerialConnectionStatus.error);
        return false;
      }

      // Configure the serial port
      final dcb = calloc<DCB>();
      dcb.ref.DCBlength = sizeOf<DCB>();

      if (GetCommState(_hComm, dcb) == 0) {
        _lastError = 'Failed to get comm state';
        _cleanup();
        _setConnectionStatus(SerialConnectionStatus.error);
        return false;
      }

      // Set DCB parameters
      dcb.ref.BaudRate = baudRate ?? defaultBaudRate;
      dcb.ref.ByteSize = defaultDataBits;
      dcb.ref.StopBits = defaultStopBits;
      dcb.ref.Parity = defaultParity;

      // Enable DTR and RTS
      // dcb.ref.fDtrControl = DTR_CONTROL_ENABLE;
      // dcb.ref.fRtsControl = RTS_CONTROL_ENABLE;

      if (SetCommState(_hComm, dcb) == 0) {
        free(dcb);
        _lastError = 'Failed to set comm state';
        _cleanup();
        _setConnectionStatus(SerialConnectionStatus.error);
        return false;
      }

      free(dcb);

      // Set timeouts
      final timeouts = calloc<COMMTIMEOUTS>();
      timeouts.ref.ReadIntervalTimeout = 50;
      timeouts.ref.ReadTotalTimeoutMultiplier = 0;
      timeouts.ref.ReadTotalTimeoutConstant = 100;
      timeouts.ref.WriteTotalTimeoutMultiplier = 0;
      timeouts.ref.WriteTotalTimeoutConstant = 1000;

      if (SetCommTimeouts(_hComm, timeouts) == 0) {
        free(timeouts);
        _lastError = 'Failed to set comm timeouts';
        _cleanup();
        _setConnectionStatus(SerialConnectionStatus.error);
        return false;
      }

      free(timeouts);

      _setConnectionStatus(SerialConnectionStatus.connected);
      _startReading();
      return true;
    } catch (e) {
      _lastError = 'Connection failed: $e';
      _cleanup();
      _setConnectionStatus(SerialConnectionStatus.error);
      return false;
    }
  }

  void disconnect() {
    _stopReading();
    _cleanup();
    _setConnectionStatus(SerialConnectionStatus.disconnected);
  }

  void _startReading() {
    if (_isReading) return;

    _isReading = true;
    _readTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_connectionStatus == SerialConnectionStatus.connected) {
        _readWeight();
      }
    });
  }

  void _stopReading() {
    _isReading = false;
    _readTimer?.cancel();
    _readTimer = null;
  }

  void _readWeight() {
    if (_hComm == INVALID_HANDLE_VALUE) return;

    try {
      final buffer = calloc<Uint8>(256);
      final bytesRead = calloc<Uint32>();

      // FIX #2: Removed incorrect cast from Pointer<Uint8> to Pointer<Void>
      final result = ReadFile(_hComm, buffer, 256, bytesRead, nullptr);

      if (result == 0) {
        _lastError = 'ReadFile failed: ${GetLastError()}';
        free(buffer);
        free(bytesRead);
        return;
      }

      if (bytesRead.value > 0) {
        final data = buffer.asTypedList(bytesRead.value);
        final dataString = String.fromCharCodes(data).trim();

        if (dataString.isNotEmpty) {
          final weight = _parseWeightData(dataString);
          if (weight != null) {
            final isStable = _checkStability(weight);
            final reading = WeightReading(
              weight: weight,
              isStable: isStable,
              timestamp: DateTime.now(),
            );
            _weightStreamController?.add(reading);
          }
        }
      }

      free(buffer);
      free(bytesRead);
    } catch (e) {
      _lastError = 'Read error: $e';
      _setConnectionStatus(SerialConnectionStatus.error);
    }
  }

  double? _parseWeightData(String data) {
    try {
      final RegExp weightRegex = RegExp(r'[-+]?\d*\.?\d+');
      final match = weightRegex.firstMatch(data);
      if (match == null) return null;

      final weightStr = match.group(0)!;
      final weight = double.tryParse(weightStr);

      // Validate the weight (reasonable range for truck scales)
      if (weight != null && weight >= 0 && weight <= 100000) {
        return weight;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  bool _checkStability(double weight) {
    _recentReadings.add(weight);

    // Keep only the last N readings
    if (_recentReadings.length > _stabilityBufferSize) {
      _recentReadings.removeAt(0);
    }

    // Need at least a few readings to determine stability
    if (_recentReadings.length < 3) return false;

    // Check if all recent readings are within the stability threshold
    final minWeight = _recentReadings.reduce((a, b) => a < b ? a : b);
    final maxWeight = _recentReadings.reduce((a, b) => a > b ? a : b);

    return (maxWeight - minWeight) <= _stabilityThreshold;
  }

  Future<bool> calibrateZero() async {
    if (_connectionStatus != SerialConnectionStatus.connected) return false;

    try {
      // Send zero calibration command (varies by scale manufacturer)
      final command = 'Z\r\n'; // Common zero command
      final commandPtr = command.toNativeUtf8();
      final bytesWritten = calloc<Uint32>();

      // FIX #3: Removed incorrect cast from Pointer<Utf8> to Pointer<Void>
      final result = WriteFile(_hComm, commandPtr.cast<Uint8>(), command.length,
          bytesWritten, nullptr);

      if (result == 0) {
        _lastError = 'WriteFile failed: ${GetLastError()}';
      }

      free(commandPtr);
      free(bytesWritten);

      return result != 0;
    } catch (e) {
      _lastError = 'Calibration failed: $e';
      return false;
    }
  }

  Future<bool> sendTareCommand() async {
    if (_connectionStatus != SerialConnectionStatus.connected) return false;

    try {
      // Send tare command (varies by scale manufacturer)
      final command = 'T\r\n'; // Common tare command
      final commandPtr = command.toNativeUtf8();
      final bytesWritten = calloc<Uint32>();

      // FIX #4: Removed incorrect cast from Pointer<Utf8> to Pointer<Void>
      final result = WriteFile(_hComm, commandPtr.cast<Uint8>(), command.length,
          bytesWritten, nullptr);

      if (result == 0) {
        _lastError = 'WriteFile failed: ${GetLastError()}';
      }

      free(commandPtr);
      free(bytesWritten);

      return result != 0;
    } catch (e) {
      _lastError = 'Tare command failed: $e';
      return false;
    }
  }

  void _setConnectionStatus(SerialConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      _statusStreamController?.add(status);
    }
  }

  void _cleanup() {
    if (_hComm != INVALID_HANDLE_VALUE) {
      CloseHandle(_hComm);
      _hComm = INVALID_HANDLE_VALUE;
    }
  }

  void dispose() {
    disconnect();
    _weightStreamController?.close();
    _statusStreamController?.close();
    _weightStreamController = null;
    _statusStreamController = null;
  }

  // Static method to list available COM ports
  static Future<List<String>> getAvailablePorts() async {
    final ports = <String>[];

    try {
      // Check COM1 through COM20 for available ports
      for (int i = 1; i <= 20; i++) {
        final portName = 'COM$i';
        String actualPortName = (i >= 10) ? r'\\.\' + portName : portName;
        final portNamePtr = actualPortName.toNativeUtf16();

        final handle = CreateFile(
          portNamePtr,
          GENERIC_READ | GENERIC_WRITE,
          0,
          nullptr,
          OPEN_EXISTING,
          0,
          0, // No template - FIX #5
        );

        free(portNamePtr);

        if (handle != INVALID_HANDLE_VALUE) {
          ports.add(portName);
          CloseHandle(handle);
        }
      }
    } catch (e) {
      // Ignore errors when checking ports
    }

    return ports;
  }
}
