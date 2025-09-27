import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Serial Communication FFI Bindings
///
/// This file contains all the low-level FFI bindings and Win32 API definitions
/// required for serial communication on Windows. It provides a clean interface
/// for the higher-level serial communication service.
///
/// Key Features:
/// - Windows COM port access via Win32 API
/// - Memory management with proper allocation/deallocation
/// - Error handling for Win32 API calls
/// - Type-safe FFI operations
/// - Constants and structures for serial communication
class SerialFFIBindings {
  /// Serial port configuration constants
  static const String defaultPortName = 'COM3';
  static const int defaultBaudRate = 9600;
  static const int defaultDataBits = 8;
  static const int defaultStopBits = DCB_STOP_BITS.ONESTOPBIT;
  static const int defaultParity = DCB_PARITY.NOPARITY;

  /// Buffer and timeout constants
  static const int readBufferSize = 256;
  static const int readIntervalTimeout = 50;
  static const int readTotalTimeoutConstant = 100;
  static const int writeTotalTimeoutConstant = 1000;

  /// Opens a serial port with the specified parameters
  ///
  /// Returns the handle to the opened COM port, or INVALID_HANDLE_VALUE if failed.
  /// The caller is responsible for closing the handle using [closePort].
  ///
  /// Parameters:
  /// - [portName]: COM port name (e.g., 'COM4')
  /// - [baudRate]: Communication speed in bits per second
  /// - [dataBits]: Number of data bits (typically 8)
  /// - [stopBits]: Stop bit configuration
  /// - [parity]: Parity checking mode
  ///
  /// Returns:
  /// - Handle to the opened port, or INVALID_HANDLE_VALUE on error
  static int openPort({
    required String portName,
    int baudRate = defaultBaudRate,
    int dataBits = defaultDataBits,
    int stopBits = defaultStopBits,
    int parity = defaultParity,
  }) {
    try {
      // Format port name for high-numbered COM ports (>= COM10)
      String actualPortName = portName;
      if (portName.startsWith('COM')) {
        final numStr = portName.substring(3);
        final num = int.tryParse(numStr);
        if (num != null && num >= 10) {
          actualPortName = r'\\.\' + portName;
        }
      }

      final portNamePtr = actualPortName.toNativeUtf16();

      // Open the serial port using CreateFile Win32 API
      final handle = CreateFile(
        portNamePtr,
        GENERIC_READ | GENERIC_WRITE,
        0, // No sharing
        nullptr, // Default security attributes
        OPEN_EXISTING, // Must exist
        0, // No additional flags
        0, // No template file
      );

      free(portNamePtr);

      if (handle == INVALID_HANDLE_VALUE) {
        return INVALID_HANDLE_VALUE;
      }

      // Configure the port with specified parameters
      if (_configurePort(handle, baudRate, dataBits, stopBits, parity)) {
        return handle;
      } else {
        CloseHandle(handle);
        return INVALID_HANDLE_VALUE;
      }
    } catch (e) {
      return INVALID_HANDLE_VALUE;
    }
  }

  /// Configures the serial port with the specified communication parameters
  ///
  /// Parameters:
  /// - [handle]: Handle to the opened COM port
  /// - [baudRate]: Communication speed in bits per second
  /// - [dataBits]: Number of data bits
  /// - [stopBits]: Stop bit configuration
  /// - [parity]: Parity checking mode
  ///
  /// Returns:
  /// - true if configuration successful, false otherwise
  static bool _configurePort(
    int handle,
    int baudRate,
    int dataBits,
    int stopBits,
    int parity,
  ) {
    try {
      // Get current DCB structure
      final dcb = calloc<DCB>();
      dcb.ref.DCBlength = sizeOf<DCB>();

      if (GetCommState(handle, dcb) == 0) {
        free(dcb);
        return false;
      }

      // Configure DCB parameters
      dcb.ref.BaudRate = baudRate;
      dcb.ref.ByteSize = dataBits;
      dcb.ref.StopBits = stopBits;
      dcb.ref.Parity = parity;

      // Set the new configuration
      final success = SetCommState(handle, dcb) != 0;
      free(dcb);

      if (!success) {
        return false;
      }

      // Configure timeouts for non-blocking reads
      return _configureTimeouts(handle);
    } catch (e) {
      return false;
    }
  }

  /// Configures read/write timeouts for the serial port
  ///
  /// Sets up timeouts to prevent blocking operations and enable
  /// responsive communication with the scale hardware.
  ///
  /// Parameters:
  /// - [handle]: Handle to the opened COM port
  ///
  /// Returns:
  /// - true if timeout configuration successful, false otherwise
  static bool _configureTimeouts(int handle) {
    try {
      final timeouts = calloc<COMMTIMEOUTS>();

      // Configure for non-blocking reads with reasonable timeouts
      timeouts.ref.ReadIntervalTimeout = readIntervalTimeout;
      timeouts.ref.ReadTotalTimeoutMultiplier = 0;
      timeouts.ref.ReadTotalTimeoutConstant = readTotalTimeoutConstant;
      timeouts.ref.WriteTotalTimeoutMultiplier = 0;
      timeouts.ref.WriteTotalTimeoutConstant = writeTotalTimeoutConstant;

      final success = SetCommTimeouts(handle, timeouts) != 0;
      free(timeouts);

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Reads data from the serial port
  ///
  /// Performs a non-blocking read operation from the specified COM port.
  /// Returns the number of bytes actually read and the data buffer.
  ///
  /// Parameters:
  /// - [handle]: Handle to the opened COM port
  /// - [bufferSize]: Size of the read buffer (default: 256 bytes)
  ///
  /// Returns:
  /// - SerialReadResult containing the read data and byte count
  static SerialReadResult readData(int handle,
      [int bufferSize = readBufferSize]) {
    if (handle == INVALID_HANDLE_VALUE) {
      return SerialReadResult(data: Uint8List(0), bytesRead: 0, success: false);
    }

    try {
      final buffer = calloc<Uint8>(bufferSize);
      final bytesRead = calloc<Uint32>();

      // Perform the read operation
      final result = ReadFile(handle, buffer, bufferSize, bytesRead, nullptr);

      if (result == 0) {
        free(buffer);
        free(bytesRead);
        return SerialReadResult(
            data: Uint8List(0), bytesRead: 0, success: false);
      }

      // Copy data to Dart memory
      final dataList = buffer.asTypedList(bytesRead.value);
      final data = Uint8List.fromList(dataList);
      final readCount = bytesRead.value;

      free(buffer);
      free(bytesRead);

      return SerialReadResult(data: data, bytesRead: readCount, success: true);
    } catch (e) {
      return SerialReadResult(data: Uint8List(0), bytesRead: 0, success: false);
    }
  }

  /// Writes data to the serial port
  ///
  /// Sends the specified command or data to the serial port.
  /// Commonly used for scale calibration and tare commands.
  ///
  /// Parameters:
  /// - [handle]: Handle to the opened COM port
  /// - [data]: String data to send
  ///
  /// Returns:
  /// - SerialWriteResult containing success status and bytes written
  static SerialWriteResult writeData(int handle, String data) {
    if (handle == INVALID_HANDLE_VALUE) {
      return SerialWriteResult(success: false, bytesWritten: 0);
    }

    try {
      final commandPtr = data.toNativeUtf8();
      final bytesWritten = calloc<Uint32>();

      // Perform the write operation
      final result = WriteFile(
        handle,
        commandPtr.cast<Uint8>(),
        data.length,
        bytesWritten,
        nullptr,
      );

      final success = result != 0;
      final written = bytesWritten.value;

      free(commandPtr);
      free(bytesWritten);

      return SerialWriteResult(success: success, bytesWritten: written);
    } catch (e) {
      return SerialWriteResult(success: false, bytesWritten: 0);
    }
  }

  /// Closes the serial port handle
  ///
  /// Properly closes the COM port handle and releases system resources.
  /// Should be called for every successful [openPort] call.
  ///
  /// Parameters:
  /// - [handle]: Handle to the opened COM port
  ///
  /// Returns:
  /// - true if successfully closed, false otherwise
  static bool closePort(int handle) {
    if (handle == INVALID_HANDLE_VALUE) {
      return true; // Already closed/invalid
    }

    try {
      return CloseHandle(handle) != 0;
    } catch (e) {
      return false;
    }
  }

  /// Gets the last Win32 error code
  ///
  /// Retrieves the last error code from the Win32 API, useful for
  /// debugging COM port connection and communication issues.
  ///
  /// Returns:
  /// - Win32 error code as integer
  static int getLastError() {
    return GetLastError();
  }

  /// Discovers available COM ports on the system
  ///
  /// Attempts to open each COM port from COM1 to COM20 to determine
  /// which ports are available for use. This is useful for automatic
  /// port detection and user selection interfaces.
  ///
  /// Returns:
  /// - List of available COM port names
  static List<String> getAvailablePorts() {
    final ports = <String>[];

    try {
      // Check COM1 through COM20 for availability
      for (int i = 1; i <= 20; i++) {
        final portName = 'COM$i';

        // Format port name for high-numbered ports
        String actualPortName = (i >= 10) ? r'\\.\' + portName : portName;
        final portNamePtr = actualPortName.toNativeUtf16();

        // Try to open the port
        final handle = CreateFile(
          portNamePtr,
          GENERIC_READ | GENERIC_WRITE,
          0,
          nullptr,
          OPEN_EXISTING,
          0,
          0,
        );

        free(portNamePtr);

        // If successful, add to available ports list
        if (handle != INVALID_HANDLE_VALUE) {
          ports.add(portName);
          CloseHandle(handle);
        }
      }
    } catch (e) {
      // Ignore errors during port discovery
    }

    return ports;
  }
}

/// Result structure for serial port read operations
///
/// Contains the data read from the port, the number of bytes read,
/// and the operation success status.
class SerialReadResult {
  /// The data buffer containing bytes read from the port
  final Uint8List data;

  /// The actual number of bytes read
  final int bytesRead;

  /// Whether the read operation was successful
  final bool success;

  const SerialReadResult({
    required this.data,
    required this.bytesRead,
    required this.success,
  });

  /// Converts the read data to a string
  ///
  /// Returns:
  /// - String representation of the data, or empty string if no data
  String get dataAsString {
    if (bytesRead == 0) return '';
    try {
      return String.fromCharCodes(data.take(bytesRead)).trim();
    } catch (e) {
      return '';
    }
  }

  /// Checks if data was successfully read
  ///
  /// Returns:
  /// - true if data was read successfully, false otherwise
  bool get hasData => success && bytesRead > 0;

  @override
  String toString() =>
      'SerialReadResult(bytesRead: $bytesRead, success: $success, data: "${dataAsString}")';
}

/// Result structure for serial port write operations
///
/// Contains the success status and the number of bytes written to the port.
class SerialWriteResult {
  /// Whether the write operation was successful
  final bool success;

  /// The actual number of bytes written
  final int bytesWritten;

  const SerialWriteResult({
    required this.success,
    required this.bytesWritten,
  });

  @override
  String toString() =>
      'SerialWriteResult(success: $success, bytesWritten: $bytesWritten)';
}
