import 'dart:async';
import 'dart:convert'; // For utf8.decode
import 'package:flutter/foundation.dart';
import 'package:weighing_system/utils/debugging_methods.dart'; // Assuming this is custom
import 'package:flutter_libserialport/flutter_libserialport.dart';

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

class WeightServiceNew extends ChangeNotifier {
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

  // Settings
  String _selectedPort = 'auto';
  int _baudRate = 9600;
  int _stopBits = 1;
  int _dataBits = 8;
  int _parity = 0; // 0=none, 1=odd, 2=even

  // Serial port handles
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _subscription;

  // Available ports for auto-discovery
  static List<String> _availablePorts = [];

  // Buffer for data accumulation
  String _dataBuffer = '';

  // Errors
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

  WeightServiceNew() {
    // debugStatus();
    _startConnectionService();
  }

  void debugStatus() {
    Timer.periodic(const Duration(milliseconds: 100), (_) {
      printd(status.toString());
    });
  }

  void _startConnectionService() {
    printd('attempting to connect to port');
    if (status == ConnectionStatus.initial) {
      _connectionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (status == ConnectionStatus.initial ||
            status == ConnectionStatus.reconnecting) {
          printd('attempting to connect to port');
          _attemptConnection();
        }
      });
    }
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
          await _connectToPort1(port);
        }
      }
    } else {
      printd('no port found');
      updateStatus(ConnectionStatus.notFound);
    }
  }

  Future<void> _connectToPort(String portName) async {
    try {
      disconnect();
      updateStatus(ConnectionStatus.connecting);
      final port = SerialPort(portName);

      final config = SerialPortConfig()
        ..baudRate = _baudRate
        ..bits = _dataBits
        ..stopBits = _stopBits
        ..parity = SerialPortParity.none;
      port.config = config;
      final isOpen = port.openReadWrite();
      if (!isOpen) {
        // Use openRead() since no writing is needed
        lastError = SerialPort.lastError.toString();
        updateStatus(ConnectionStatus.hasError);
        printd('Failed to open port $portName: ${SerialPort.lastError}');
        return;
      }
      port.config = config;
      _port = port;
      _reader = SerialPortReader(_port!);
      _subscription = _reader!.stream.listen(
        _processData,
        onError: (error) {
          debugPrint('Stream error: $error');
          _handleConnectionLost();
        },
        onDone: () {
          debugPrint('Stream done');
          _handleConnectionLost();
        },
      );

      _connectedPort = portName;
      _isConnected = true;
      updateStatus(ConnectionStatus.connected);
      printd('WeightService: Connected to $portName');
      notifyListeners();
    } catch (e) {
      lastError = e.toString();
      updateStatus(ConnectionStatus.hasError);
      debugPrint('WeightService: Failed to connect to $portName: $e');
    }
  }

  Future<void> _connectToPort1(String portName) async {
    try {
      // ensure previous connection is fully closed
      disconnect(); // <--- IMPORTANT: await the cleanup
      updateStatus(ConnectionStatus.connecting);

      // quick diagnostics
      debugPrint('Available ports: ${SerialPort.availablePorts}');
      final port = SerialPort(portName);

      // open read+write (some devices/Windows drivers require write access even if you only read)
      final opened =
          port.openReadWrite(); // try readWrite instead of openRead()
      if (!opened) {
        lastError = SerialPort.lastError?.toString() ??
            'openReadWrite() returned false';
        updateStatus(ConnectionStatus.hasError);
        debugPrint('Failed to open port $portName: lastError=$lastError');
        try {
          port.dispose();
        } catch (_) {}
        return;
      }

      // double-check isOpen
      debugPrint('port.isOpen after openReadWrite(): ${port.isOpen}');
      if (port.isOpen != true) {
        lastError = 'Port not open after openReadWrite()';
        updateStatus(ConnectionStatus.hasError);
        debugPrint('Failed: $lastError');
        try {
          port.close();
          port.dispose();
        } catch (_) {}
        return;
      }

      // Get the current config, modify it, and re-apply (docs: port must be opened before changing settings).
      final cfg = port.config; // getter from opened port
      cfg.baudRate = _baudRate;
      cfg.bits = _dataBits;
      cfg.stopBits = _stopBits;
      cfg.parity = SerialPortParity.none;
      // optionally set flow control preset:
      cfg.setFlowControl(SerialPortFlowControl.none);
      port.config = cfg; // apply

      // set up reader stream
      _port = port;
      _reader = SerialPortReader(_port!);
      _subscription = _reader!.stream.listen(
        _processData,
        onError: (error) {
          debugPrint('Stream error: $error');
          _handleConnectionLost();
        },
        onDone: () {
          debugPrint('Stream done');
          _handleConnectionLost();
        },
      );

      _connectedPort = portName;
      _isConnected = true;
      updateStatus(ConnectionStatus.connected);
      debugPrint(
          'WeightService: Connected to $portName (readWrite + SerialPortReader)');
      notifyListeners();
    } on SerialPortError catch (e) {
      // libserialport surface error
      lastError = SerialPort.lastError?.toString() ?? e.toString();
      updateStatus(ConnectionStatus.hasError);
      debugPrint('SerialPortError while connecting to $portName: $lastError');
    } catch (e, st) {
      lastError = e.toString();
      updateStatus(ConnectionStatus.hasError);
      debugPrint('WeightService: Failed to connect to $portName: $e\n$st');
    }
  }

  void _processData(Uint8List bytes) {
    final data = utf8.decode(bytes, allowMalformed: true);
    printd("raw data string: $data");
    _dataBuffer += data;

    while (true) {
      final eolIndex = _dataBuffer.indexOf('\n');
      if (eolIndex == -1) break;
      String line =
          _dataBuffer.substring(0, eolIndex).trim(); // Handle \r or whitespace
      _dataBuffer = _dataBuffer.substring(eolIndex + 1);
      printd("line is: $line");
      printd("line length is: ${line.length}");
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
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }
    if (_reader != null) {
      _reader!.close();
      _reader = null;
    }
    if (_port != null) {
      _port!.close();
      _port = null;
    }

    _isConnected = false;
    _connectedPort = null;
    _currentWeight = 0;
    _dataBuffer = '';
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
