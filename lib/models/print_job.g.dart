// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'print_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrintJob _$PrintJobFromJson(Map<String, dynamic> json) => PrintJob(
      id: json['id'] as String,
      printerName: json['printerName'] as String,
      documentName: json['documentName'] as String,
      type: $enumDecode(_$PrintJobTypeEnumMap, json['type']),
      status: $enumDecode(_$PrintJobStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      totalPages: (json['totalPages'] as num).toInt(),
      printedPages: (json['printedPages'] as num).toInt(),
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PrintJobToJson(PrintJob instance) => <String, dynamic>{
      'id': instance.id,
      'printerName': instance.printerName,
      'documentName': instance.documentName,
      'type': _$PrintJobTypeEnumMap[instance.type]!,
      'status': _$PrintJobStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'totalPages': instance.totalPages,
      'printedPages': instance.printedPages,
      'errorMessage': instance.errorMessage,
      'metadata': instance.metadata,
    };

const _$PrintJobTypeEnumMap = {
  PrintJobType.weighingTicket: 'weighingTicket',
  PrintJobType.invoice: 'invoice',
  PrintJobType.template: 'template',
  PrintJobType.report: 'report',
  PrintJobType.document: 'document',
  PrintJobType.test: 'test',
};

const _$PrintJobStatusEnumMap = {
  PrintJobStatus.queued: 'queued',
  PrintJobStatus.printing: 'printing',
  PrintJobStatus.completed: 'completed',
  PrintJobStatus.failed: 'failed',
  PrintJobStatus.cancelled: 'cancelled',
};

PrintJobStatistics _$PrintJobStatisticsFromJson(Map<String, dynamic> json) =>
    PrintJobStatistics(
      totalJobs: (json['totalJobs'] as num).toInt(),
      completedJobs: (json['completedJobs'] as num).toInt(),
      failedJobs: (json['failedJobs'] as num).toInt(),
      cancelledJobs: (json['cancelledJobs'] as num).toInt(),
      totalPrintTime:
          Duration(microseconds: (json['totalPrintTime'] as num).toInt()),
      jobsByPrinter: Map<String, int>.from(json['jobsByPrinter'] as Map),
      jobsByType: (json['jobsByType'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry($enumDecode(_$PrintJobTypeEnumMap, k), (e as num).toInt()),
      ),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
    );

Map<String, dynamic> _$PrintJobStatisticsToJson(PrintJobStatistics instance) =>
    <String, dynamic>{
      'totalJobs': instance.totalJobs,
      'completedJobs': instance.completedJobs,
      'failedJobs': instance.failedJobs,
      'cancelledJobs': instance.cancelledJobs,
      'totalPrintTime': instance.totalPrintTime.inMicroseconds,
      'jobsByPrinter': instance.jobsByPrinter,
      'jobsByType': instance.jobsByType
          .map((k, e) => MapEntry(_$PrintJobTypeEnumMap[k]!, e)),
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
    };
