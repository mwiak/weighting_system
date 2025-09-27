import 'page_dimensions.dart';

/// Windows printer information and capabilities
class WindowsPrinter {
  final String name;
  final String serverName;
  final String portName;
  final String driverName;
  final String location;
  final String comment;
  final PrinterStatus status;
  final PrinterCapabilities capabilities;
  final List<PageSize> supportedPaperSizes;
  final bool isDefault;
  final bool isShared;
  final bool isNetworkPrinter;

  const WindowsPrinter({
    required this.name,
    required this.serverName,
    required this.portName,
    required this.driverName,
    required this.location,
    required this.comment,
    required this.status,
    required this.capabilities,
    required this.supportedPaperSizes,
    this.isDefault = false,
    this.isShared = false,
    this.isNetworkPrinter = false,
  });

  /// Check if printer can handle the given page size
  bool canPrint(PageSize pageSize) {
    return supportedPaperSizes.any((size) => size.matches(pageSize)) ||
           capabilities.supportsCustomSizes;
  }

  /// Get the best matching paper size for given dimensions
  PageSize? getBestPaperSize(PageSize targetSize) {
    // First try exact match
    for (final size in supportedPaperSizes) {
      if (size.matches(targetSize, toleranceMm: 0.5)) {
        return size;
      }
    }

    // Then try sizes that can fit the target
    final fittingSizes = supportedPaperSizes
        .where((size) => targetSize.fitsWithin(size))
        .toList();

    if (fittingSizes.isEmpty) return null;

    // Return the smallest size that fits
    fittingSizes.sort((a, b) =>
        (a.widthMm * a.heightMm).compareTo(b.widthMm * b.heightMm));

    return fittingSizes.first;
  }

  /// Check if printer is ready to print
  bool get isReady {
    return status == PrinterStatus.ready || status == PrinterStatus.idle;
  }

  /// Get current paper size loaded in printer (if detectable)
  PageSize? getCurrentPaperSize() {
    // This would require additional Win32 API calls to get current paper
    // For now, return the first supported size as default
    return supportedPaperSizes.isNotEmpty ? supportedPaperSizes.first : null;
  }

  @override
  String toString() {
    return '$name (${status.name}) - $driverName';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindowsPrinter && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Printer status enumeration
enum PrinterStatus {
  ready,
  idle,
  printing,
  warmingUp,
  offline,
  error,
  paperJam,
  outOfPaper,
  outOfToner,
  doorOpen,
  userIntervention,
  unknown;

  /// Get status from Windows printer status flags
  factory PrinterStatus.fromWin32Flags(int flags) {
    // Define Windows printer status constants
    const int printerStatusPaused = 0x00000001;
    const int printerStatusError = 0x00000002;
    const int printerStatusPendingDeletion = 0x00000004;
    const int printerStatusPaperJam = 0x00000008;
    const int printerStatusPaperOut = 0x00000010;
    const int printerStatusOutputBinFull = 0x00000800;
    const int printerStatusNotAvailable = 0x00001000;
    const int printerStatusBusy = 0x00000200;
    const int printerStatusDoorOpen = 0x00400000;
    const int printerStatusUserIntervention = 0x00100000;
    const int printerStatusOutOfMemory = 0x00200000;
    const int printerStatusTonerLow = 0x00020000;
    const int printerStatusWarmingUp = 0x00010000;

    if (flags & printerStatusPaused != 0) return PrinterStatus.offline;
    if (flags & printerStatusError != 0) return PrinterStatus.error;
    if (flags & printerStatusPendingDeletion != 0) return PrinterStatus.offline;
    if (flags & printerStatusPaperJam != 0) return PrinterStatus.paperJam;
    if (flags & printerStatusPaperOut != 0) return PrinterStatus.outOfPaper;
    if (flags & printerStatusOutputBinFull != 0) return PrinterStatus.userIntervention;
    if (flags & printerStatusNotAvailable != 0) return PrinterStatus.offline;
    if (flags & printerStatusBusy != 0) return PrinterStatus.printing;
    if (flags & printerStatusDoorOpen != 0) return PrinterStatus.doorOpen;
    if (flags & printerStatusUserIntervention != 0) return PrinterStatus.userIntervention;
    if (flags & printerStatusOutOfMemory != 0) return PrinterStatus.error;
    if (flags & printerStatusTonerLow != 0) return PrinterStatus.outOfToner;
    if (flags & printerStatusWarmingUp != 0) return PrinterStatus.warmingUp;

    // If no error flags, assume ready
    return PrinterStatus.ready;
  }

  String get displayName {
    switch (this) {
      case PrinterStatus.ready:
        return 'Ready';
      case PrinterStatus.idle:
        return 'Idle';
      case PrinterStatus.printing:
        return 'Printing';
      case PrinterStatus.warmingUp:
        return 'Warming Up';
      case PrinterStatus.offline:
        return 'Offline';
      case PrinterStatus.error:
        return 'Error';
      case PrinterStatus.paperJam:
        return 'Paper Jam';
      case PrinterStatus.outOfPaper:
        return 'Out of Paper';
      case PrinterStatus.outOfToner:
        return 'Out of Toner';
      case PrinterStatus.doorOpen:
        return 'Door Open';
      case PrinterStatus.userIntervention:
        return 'User Intervention Required';
      case PrinterStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isError {
    return this == PrinterStatus.error ||
           this == PrinterStatus.paperJam ||
           this == PrinterStatus.outOfPaper ||
           this == PrinterStatus.outOfToner ||
           this == PrinterStatus.doorOpen ||
           this == PrinterStatus.userIntervention;
  }
}

/// Printer capabilities and features
class PrinterCapabilities {
  final bool supportsColor;
  final bool supportsDuplex;
  final bool supportsBorderless;
  final bool supportsCustomSizes;
  final List<int> supportedDpi;
  final int maxDpi;
  final int minDpi;
  final PrintMargins minimumMargins;
  final List<String> supportedMediaTypes;

  const PrinterCapabilities({
    required this.supportsColor,
    required this.supportsDuplex,
    required this.supportsBorderless,
    required this.supportsCustomSizes,
    required this.supportedDpi,
    required this.maxDpi,
    required this.minDpi,
    required this.minimumMargins,
    required this.supportedMediaTypes,
  });

  /// Default capabilities for basic printers
  factory PrinterCapabilities.basic() {
    return const PrinterCapabilities(
      supportsColor: false,
      supportsDuplex: false,
      supportsBorderless: false,
      supportsCustomSizes: false,
      supportedDpi: [300, 600],
      maxDpi: 600,
      minDpi: 300,
      minimumMargins: PrintMargins.uniform(6.35), // 0.25 inch margins
      supportedMediaTypes: ['Plain Paper'],
    );
  }

  /// Get optimal DPI for given page size
  int getOptimalDpi(PageSize pageSize) {
    // For templates and forms, higher DPI is better for precision
    if (pageSize.widthMm <= 220 && pageSize.heightMm <= 300) {
      // A4 and smaller - use highest DPI
      return maxDpi;
    }

    // Larger formats - balance quality and speed
    return supportedDpi.where((dpi) => dpi >= 600).isNotEmpty
        ? 600
        : maxDpi;
  }

  @override
  String toString() {
    final features = <String>[];
    if (supportsColor) features.add('Color');
    if (supportsDuplex) features.add('Duplex');
    if (supportsBorderless) features.add('Borderless');
    if (supportsCustomSizes) features.add('Custom Sizes');

    return 'Capabilities: ${features.join(', ')} (DPI: $minDpi-$maxDpi)';
  }
}

/// Print job information
class PrintJob {
  final int id;
  final String documentName;
  final String userName;
  final DateTime submitTime;
  final int totalPages;
  final int pagesPrinted;
  final PrintJobStatus status;
  final int sizeBytes;
  final PageSize? pageSize;

  const PrintJob({
    required this.id,
    required this.documentName,
    required this.userName,
    required this.submitTime,
    required this.totalPages,
    required this.pagesPrinted,
    required this.status,
    required this.sizeBytes,
    this.pageSize,
  });

  double get progress => totalPages > 0 ? pagesPrinted / totalPages : 0.0;

  bool get isActive => status == PrintJobStatus.printing ||
                      status == PrintJobStatus.spooling;

  @override
  String toString() {
    return '$documentName (Job $id) - ${status.name} - $pagesPrinted/$totalPages pages';
  }
}

enum PrintJobStatus {
  spooling,
  printing,
  paused,
  error,
  deleting,
  completed,
  unknown;

  factory PrintJobStatus.fromWin32Flags(int flags) {
    // Define Windows job status constants
    const int jobStatusPrinting = 0x00000010;
    const int jobStatusPaused = 0x00000001;
    const int jobStatusError = 0x00000002;
    const int jobStatusDeleting = 0x00000004;
    const int jobStatusSpooling = 0x00000008;
    const int jobStatusComplete = 0x00001000;

    if (flags & jobStatusPrinting != 0) return PrintJobStatus.printing;
    if (flags & jobStatusPaused != 0) return PrintJobStatus.paused;
    if (flags & jobStatusError != 0) return PrintJobStatus.error;
    if (flags & jobStatusDeleting != 0) return PrintJobStatus.deleting;
    if (flags & jobStatusSpooling != 0) return PrintJobStatus.spooling;
    if (flags & jobStatusComplete != 0) return PrintJobStatus.completed;

    return PrintJobStatus.unknown;
  }
}

/// Print settings for precise control
class PrintSettings {
  final PageSize pageSize;
  final Orientation orientation;
  final int dpi;
  final bool borderless;
  final PrintMargins margins;
  final String mediaType;
  final bool duplex;
  final int copies;
  final bool collate;

  const PrintSettings({
    required this.pageSize,
    required this.orientation,
    required this.dpi,
    this.borderless = false,
    this.margins = const PrintMargins.zero(),
    this.mediaType = 'Plain Paper',
    this.duplex = false,
    this.copies = 1,
    this.collate = false,
  });

  /// Create settings optimized for template printing
  factory PrintSettings.forTemplate(PageSize templateSize, int optimalDpi) {
    return PrintSettings(
      pageSize: templateSize,
      orientation: templateSize.widthMm > templateSize.heightMm
          ? Orientation.landscape
          : Orientation.portrait,
      dpi: optimalDpi,
      borderless: true, // Try borderless for templates
      margins: const PrintMargins.zero(),
      mediaType: 'Plain Paper',
    );
  }

  /// Validate settings against printer capabilities
  bool isCompatibleWith(PrinterCapabilities capabilities) {
    if (!capabilities.supportedDpi.contains(dpi)) return false;
    if (borderless && !capabilities.supportsBorderless) return false;
    if (!capabilities.supportedMediaTypes.contains(mediaType)) return false;

    return true;
  }

  @override
  String toString() {
    return '$pageSize @ ${dpi}dpi (${orientation.name})';
  }
}