import 'package:json_annotation/json_annotation.dart';

part 'print_job.g.dart';

@JsonSerializable()
class PrintJob {
  final String id;
  final String printerName;
  final String documentName;
  final PrintJobType type;
  final PrintJobStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int totalPages;
  final int printedPages;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const PrintJob({
    required this.id,
    required this.printerName,
    required this.documentName,
    required this.type,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    required this.totalPages,
    required this.printedPages,
    this.errorMessage,
    this.metadata,
  });

  factory PrintJob.fromJson(Map<String, dynamic> json) =>
      _$PrintJobFromJson(json);

  Map<String, dynamic> toJson() => _$PrintJobToJson(this);

  /// Create a new print job
  factory PrintJob.create({
    required String id,
    required String printerName,
    required String documentName,
    required PrintJobType type,
    required int totalPages,
    Map<String, dynamic>? metadata,
  }) {
    return PrintJob(
      id: id,
      printerName: printerName,
      documentName: documentName,
      type: type,
      status: PrintJobStatus.queued,
      createdAt: DateTime.now(),
      totalPages: totalPages,
      printedPages: 0,
      metadata: metadata,
    );
  }

  /// Copy with new status
  PrintJob copyWith({
    PrintJobStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    int? printedPages,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return PrintJob(
      id: id,
      printerName: printerName,
      documentName: documentName,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalPages: totalPages,
      printedPages: printedPages ?? this.printedPages,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Mark job as started
  PrintJob markStarted() {
    return copyWith(
      status: PrintJobStatus.printing,
      startedAt: DateTime.now(),
    );
  }

  /// Mark job as completed
  PrintJob markCompleted() {
    return copyWith(
      status: PrintJobStatus.completed,
      completedAt: DateTime.now(),
      printedPages: totalPages,
    );
  }

  /// Mark job as failed
  PrintJob markFailed(String error) {
    return copyWith(
      status: PrintJobStatus.failed,
      completedAt: DateTime.now(),
      errorMessage: error,
    );
  }

  /// Mark job as cancelled
  PrintJob markCancelled() {
    return copyWith(
      status: PrintJobStatus.cancelled,
      completedAt: DateTime.now(),
    );
  }

  /// Get print progress as percentage
  double get progress {
    if (totalPages == 0) return 0.0;
    return (printedPages / totalPages).clamp(0.0, 1.0);
  }

  /// Get duration of the print job
  Duration? get duration {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }

  /// Check if job is in progress
  bool get isInProgress =>
      status == PrintJobStatus.printing || status == PrintJobStatus.queued;

  /// Check if job is completed (successfully or failed)
  bool get isFinished =>
      status == PrintJobStatus.completed ||
      status == PrintJobStatus.failed ||
      status == PrintJobStatus.cancelled;

  @override
  String toString() {
    return 'PrintJob(id: $id, printer: $printerName, status: $status, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrintJob && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum PrintJobStatus {
  @JsonValue('queued')
  queued,
  @JsonValue('printing')
  printing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
}

enum PrintJobType {
  @JsonValue('weighingTicket')
  weighingTicket,
  @JsonValue('invoice')
  invoice,
  @JsonValue('template')
  template,
  @JsonValue('report')
  report,
  @JsonValue('document')
  document,
  @JsonValue('test')
  test,
}

@JsonSerializable()
class PrintJobStatistics {
  final int totalJobs;
  final int completedJobs;
  final int failedJobs;
  final int cancelledJobs;
  final Duration totalPrintTime;
  final Map<String, int> jobsByPrinter;
  final Map<PrintJobType, int> jobsByType;
  final DateTime periodStart;
  final DateTime periodEnd;

  const PrintJobStatistics({
    required this.totalJobs,
    required this.completedJobs,
    required this.failedJobs,
    required this.cancelledJobs,
    required this.totalPrintTime,
    required this.jobsByPrinter,
    required this.jobsByType,
    required this.periodStart,
    required this.periodEnd,
  });

  factory PrintJobStatistics.fromJson(Map<String, dynamic> json) =>
      _$PrintJobStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$PrintJobStatisticsToJson(this);

  /// Calculate success rate as percentage
  double get successRate {
    if (totalJobs == 0) return 0.0;
    return (completedJobs / totalJobs * 100).clamp(0.0, 100.0);
  }

  /// Calculate average print time
  Duration get averagePrintTime {
    if (completedJobs == 0) return Duration.zero;
    return Duration(
      milliseconds: totalPrintTime.inMilliseconds ~/ completedJobs,
    );
  }

  /// Get most used printer
  String? get mostUsedPrinter {
    if (jobsByPrinter.isEmpty) return null;
    return jobsByPrinter.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Create empty statistics
  factory PrintJobStatistics.empty() {
    final now = DateTime.now();
    return PrintJobStatistics(
      totalJobs: 0,
      completedJobs: 0,
      failedJobs: 0,
      cancelledJobs: 0,
      totalPrintTime: Duration.zero,
      jobsByPrinter: {},
      jobsByType: {},
      periodStart: now,
      periodEnd: now,
    );
  }
}