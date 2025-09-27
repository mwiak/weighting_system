import 'dart:async';
import 'package:flutter/foundation.dart';
import 'serial_ffi_bindings.dart';

/// Weight reading data structure
/// 
/// Represents a single weight measurement from the scale, including
/// the weight value, stability status, timestamp, and unit of measurement.
class WeightReading {
  /// The measured weight value
  final double weight;
  
  /// Whether the reading is stable (not fluctuating)
  final bool isStable;
  
  /// When this reading was taken
  final DateTime timestamp;
  
  /// Unit of measurement (default: kg)
  final String unit;

  const WeightReading({
    required this.weight,
    required this.isStable,
    required this.timestamp,
    this.unit = 'kg',
  });

  @override
  String toString() => 'WeightReading(weight: $weight$unit, stable: $isStable, time: $timestamp)';
  
  /// Creates a copy of this reading with updated stability status
  WeightReading withStability(bool stable) {
    return WeightReading(
      weight: weight,
      isStable: stable,
      timestamp: timestamp,
      unit: unit,
    );
  }
  
  /// Checks if this reading represents zero weight
  bool get isZero => weight.abs() < 0.1;
  
  /// Formats the weight for display with appropriate precision
  String get formattedWeight {
    if (weight < 10) {
      return weight.toStringAsFixed(2);
    } else if (weight < 100) {
      return weight.toStringAsFixed(1);
    } else {
      return weight.toStringAsFixed(0);
    }
  }
}

/// Serial connection status enumeration
/// 
/// Represents the current state of the serial port connection.
enum SerialConnectionStatus {
  /// Port is disconnected
  disconnected,
  
  /// Currently attempting to connect
  connecting,
  
  /// Successfully connected and reading data
  connected,
  
  /// Connection or communication error occurred
  error,
}

/// Serial Reader Service
/// 
/// High-level service for reading weight data from serial scales.
/// Handles connection management, data parsing, stability detection,
/// and provides clean streams for weight readings and connection status.
/// 
/// Key Features:
/// - Automatic weight parsing from various scale formats
/// - Weight stability detection using moving average
/// - Robust error handling and reconnection
/// - Scale calibration and tare commands
/// - Configurable COM port and communication parameters
class SerialReaderService {
  // Connection management
  int _portHandle = -1; // Using -1 instead of INVALID_HANDLE_VALUE for clarity
  String _portName = SerialFFIBindings.defaultPortName;
  SerialConnectionStatus _connectionStatus = SerialConnectionStatus.disconnected;
  
  // Data streaming
  StreamController<WeightReading>? _weightStreamController;
  StreamController<SerialConnectionStatus>? _statusStreamController;
  
  // Reading management
  Timer? _readTimer;
  bool _isReading = false;
  static const Duration _readInterval = Duration(milliseconds: 100);
  
  // Weight stability tracking
  final List<double> _recentReadings = [];
  static const int _stabilityBufferSize = 5;
  static const double _stabilityThreshold = 0.5; // kg
  
  // Error handling
  String? _lastError;
  int _errorCount = 0;
  static const int _maxConsecutiveErrors = 5;
  
  // Configuration
  int _baudRate = SerialFFIBindings.defaultBaudRate;
  
  /// Stream of weight readings from the scale
  Stream<WeightReading> get weightStream =>
      _weightStreamController?.stream ?? const Stream.empty();
      
  /// Stream of connection status changes
  Stream<SerialConnectionStatus> get statusStream =>
      _statusStreamController?.stream ?? const Stream.empty();

  /// Current connection status
  SerialConnectionStatus get connectionStatus => _connectionStatus;
  
  /// Last error message, if any
  String? get lastError => _lastError;
  
  /// Currently configured COM port name
  String get portName => _portName;
  
  /// Whether the service is currently connected
  bool get isConnected => _connectionStatus == SerialConnectionStatus.connected;
  
  /// Constructor
  /// 
  /// Initializes the service with broadcast stream controllers for
  /// weight readings and connection status updates.
  SerialReaderService() {
    _initializeStreams();
  }
  
  /// Initializes the broadcast stream controllers
  void _initializeStreams() {
    _weightStreamController = StreamController<WeightReading>.broadcast();
    _statusStreamController = StreamController<SerialConnectionStatus>.broadcast();
  }
  
  /// Connects to the specified COM port
  /// 
  /// Attempts to establish a connection to the scale hardware using
  /// the specified communication parameters. If successful, starts
  /// reading weight data at regular intervals.
  /// 
  /// Parameters:
  /// - [portName]: COM port name (e.g., 'COM4'). Optional, uses current port if not specified.
  /// - [baudRate]: Communication speed. Optional, uses current baud rate if not specified.
  /// 
  /// Returns:
  /// - Future<bool> indicating whether the connection was successful
  Future<bool> connect({String? portName, int? baudRate}) async {
    // Prevent duplicate connection attempts
    if (_connectionStatus == SerialConnectionStatus.connected ||
        _connectionStatus == SerialConnectionStatus.connecting) {
      return _connectionStatus == SerialConnectionStatus.connected;
    }

    _setConnectionStatus(SerialConnectionStatus.connecting);
    _clearError();
    
    try {
      // Update configuration if provided
      if (portName != null) _portName = portName;
      if (baudRate != null) _baudRate = baudRate;
      
      debugPrint('SerialReaderService: Attempting to connect to $_portName at $_baudRate baud');
      
      // Open the port using FFI bindings
      _portHandle = SerialFFIBindings.openPort(
        portName: _portName,
        baudRate: _baudRate,
      );
      
      if (_portHandle == -1) { // INVALID_HANDLE_VALUE equivalent
        final errorCode = SerialFFIBindings.getLastError();
        _setError('Failed to open $_portName. Error code: $errorCode');
        _setConnectionStatus(SerialConnectionStatus.error);
        return false;
      }
      
      debugPrint('SerialReaderService: Successfully opened $_portName');
      
      // Start reading data
      _setConnectionStatus(SerialConnectionStatus.connected);
      _startReading();
      
      return true;
    } catch (e) {
      _setError('Connection failed: $e');
      _cleanup();
      _setConnectionStatus(SerialConnectionStatus.error);
      return false;
    }
  }
  
  /// Disconnects from the COM port
  /// 
  /// Stops reading data, closes the port handle, and updates the
  /// connection status to disconnected.
  void disconnect() {
    debugPrint('SerialReaderService: Disconnecting from $_portName');
    
    _stopReading();
    _cleanup();
    _setConnectionStatus(SerialConnectionStatus.disconnected);
    _clearError();
  }
  
  /// Starts the periodic weight reading timer
  void _startReading() {
    if (_isReading) return;
    
    debugPrint('SerialReaderService: Starting weight reading timer');
    _isReading = true;
    _errorCount = 0;
    
    _readTimer = Timer.periodic(_readInterval, (_) {
      if (_connectionStatus == SerialConnectionStatus.connected) {
        _readWeight();
      }
    });
  }
  
  /// Stops the weight reading timer
  void _stopReading() {
    if (!_isReading) return;
    
    debugPrint('SerialReaderService: Stopping weight reading timer');
    _isReading = false;
    _readTimer?.cancel();
    _readTimer = null;
  }
  
  /// Reads weight data from the serial port
  /// 
  /// Performs a single read operation, parses the received data,
  /// checks for weight stability, and emits a WeightReading event
  /// if valid data is received.
  void _readWeight() {
    if (_portHandle == -1) return;
    
    try {
      // Read data using FFI bindings
      final result = SerialFFIBindings.readData(_portHandle);
      
      if (!result.success) {
        _handleReadError('Read operation failed');
        return;
      }
      
      // Process received data
      if (result.hasData) {
        final dataString = result.dataAsString;
        if (dataString.isNotEmpty) {
          final weight = _parseWeightData(dataString);
          if (weight != null) {
            _processWeightReading(weight);
            _errorCount = 0; // Reset error count on successful read
          }
        }
      }
    } catch (e) {
      _handleReadError('Read error: $e');
    }
  }
  
  /// Processes a parsed weight value
  /// 
  /// Checks weight stability and creates a WeightReading object
  /// to emit on the weight stream.
  /// 
  /// Parameters:
  /// - [weight]: The parsed weight value in kg
  void _processWeightReading(double weight) {
    final isStable = _checkStability(weight);
    final reading = WeightReading(
      weight: weight,
      isStable: isStable,
      timestamp: DateTime.now(),
    );
    
    _weightStreamController?.add(reading);
  }
  
  /// Handles read operation errors
  /// 
  /// Tracks consecutive errors and disconnects if too many occur.
  /// 
  /// Parameters:
  /// - [errorMessage]: Description of the error that occurred
  void _handleReadError(String errorMessage) {
    _errorCount++;
    
    if (_errorCount >= _maxConsecutiveErrors) {
      debugPrint('SerialReaderService: Too many consecutive errors, disconnecting');
      _setError('$errorMessage (consecutive errors: $_errorCount)');
      disconnect();
    } else {
      debugPrint('SerialReaderService: $errorMessage (error count: $_errorCount)');
    }
  }
  
  /// Parses weight data from the received string
  /// 
  /// Extracts numeric weight values from various scale data formats.
  /// Supports both positive and negative weights and validates
  /// the range for typical truck scale applications.
  /// 
  /// Parameters:
  /// - [data]: Raw string data received from the scale
  /// 
  /// Returns:
  /// - Parsed weight value in kg, or null if parsing failed
  double? _parseWeightData(String data) {
    try {
      // Regular expression to match weight values
      // Supports: 1234.56, +1234.56, -1234.56, 1234, etc.
      final RegExp weightRegex = RegExp(r'[+-]?\d*\.?\d+');
      final match = weightRegex.firstMatch(data);
      
      if (match == null) return null;
      
      final weightStr = match.group(0)!;
      final weight = double.tryParse(weightStr);
      
      // Validate weight range (reasonable for truck scales: 0-100 tons)
      if (weight != null && weight >= -1000 && weight <= 100000) {
        return weight;
      }
      
      debugPrint('SerialReaderService: Weight out of range: $weight');
      return null;
    } catch (e) {
      debugPrint('SerialReaderService: Weight parsing error: $e');
      return null;
    }
  }
  
  /// Checks if the current weight reading is stable
  /// 
  /// Uses a moving average approach to determine if recent weight
  /// readings are consistent within the stability threshold.
  /// 
  /// Parameters:
  /// - [weight]: The current weight reading
  /// 
  /// Returns:
  /// - true if the weight is stable, false otherwise
  bool _checkStability(double weight) {
    _recentReadings.add(weight);
    
    // Maintain buffer size
    if (_recentReadings.length > _stabilityBufferSize) {
      _recentReadings.removeAt(0);
    }
    
    // Need at least 3 readings to determine stability
    if (_recentReadings.length < 3) return false;
    
    // Calculate range of recent readings
    final minWeight = _recentReadings.reduce((a, b) => a < b ? a : b);
    final maxWeight = _recentReadings.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    
    return range <= _stabilityThreshold;
  }
  
  /// Sends a zero calibration command to the scale
  /// 
  /// Transmits the zero/tare command to set the current weight as
  /// the zero reference point. The exact command format may vary
  /// depending on the scale manufacturer.
  /// 
  /// Returns:
  /// - Future<bool> indicating whether the command was sent successfully
  Future<bool> sendZeroCommand() async {
    return _sendCommand('Z\r\n', 'Zero calibration');
  }
  
  /// Sends a tare command to the scale
  /// 
  /// Transmits the tare command to subtract the current weight
  /// from future readings (useful for container/truck weight).
  /// 
  /// Returns:
  /// - Future<bool> indicating whether the command was sent successfully
  Future<bool> sendTareCommand() async {
    return _sendCommand('T\r\n', 'Tare');
  }
  
  /// Sends a generic command to the scale
  /// 
  /// Low-level method for sending arbitrary commands to the scale hardware.
  /// 
  /// Parameters:
  /// - [command]: The command string to send
  /// - [description]: Human-readable description for logging
  /// 
  /// Returns:
  /// - Future<bool> indicating whether the command was sent successfully
  Future<bool> _sendCommand(String command, String description) async {
    if (!isConnected) {
      debugPrint('SerialReaderService: Cannot send $description command - not connected');
      return false;
    }
    
    try {
      debugPrint('SerialReaderService: Sending $description command: ${command.trim()}');
      
      final result = SerialFFIBindings.writeData(_portHandle, command);
      
      if (result.success) {
        debugPrint('SerialReaderService: $description command sent successfully (${result.bytesWritten} bytes)');
        return true;
      } else {
        final errorCode = SerialFFIBindings.getLastError();
        debugPrint('SerialReaderService: Failed to send $description command. Error code: $errorCode');
        return false;
      }
    } catch (e) {
      debugPrint('SerialReaderService: $description command error: $e');
      return false;
    }
  }
  
  /// Updates the connection status
  /// 
  /// Sets the new status and notifies listeners via the status stream.
  /// 
  /// Parameters:
  /// - [status]: The new connection status
  void _setConnectionStatus(SerialConnectionStatus status) {
    if (_connectionStatus != status) {
      final oldStatus = _connectionStatus;
      _connectionStatus = status;
      
      debugPrint('SerialReaderService: Connection status changed: $oldStatus -> $status');
      _statusStreamController?.add(status);
    }
  }
  
  /// Sets an error message and updates the connection status
  /// 
  /// Parameters:
  /// - [message]: The error message to set
  void _setError(String message) {
    _lastError = message;
    debugPrint('SerialReaderService: Error - $message');
  }
  
  /// Clears the current error message
  void _clearError() {
    _lastError = null;
    _errorCount = 0;
  }
  
  /// Cleans up port handle and resources
  void _cleanup() {
    if (_portHandle != -1) {
      debugPrint('SerialReaderService: Closing port handle $_portHandle');
      SerialFFIBindings.closePort(_portHandle);
      _portHandle = -1;
    }
    
    // Clear weight history
    _recentReadings.clear();
  }
  
  /// Gets a list of available COM ports
  /// 
  /// Uses the FFI bindings to discover which COM ports are available
  /// on the system for scale connection.
  /// 
  /// Returns:
  /// - Future<List<String>> of available port names
  static Future<List<String>> getAvailablePorts() async {
    try {
      return SerialFFIBindings.getAvailablePorts();
    } catch (e) {
      debugPrint('SerialReaderService: Error getting available ports: $e');
      return [];
    }
  }
  
  /// Disposes of the service and releases all resources
  /// 
  /// Should be called when the service is no longer needed.
  /// Closes streams and disconnects from the port.
  void dispose() {
    debugPrint('SerialReaderService: Disposing service');
    
    disconnect();
    
    _weightStreamController?.close();
    _statusStreamController?.close();
    _weightStreamController = null;
    _statusStreamController = null;
  }
}