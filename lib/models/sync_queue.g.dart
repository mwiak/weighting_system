// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncQueue _$SyncQueueFromJson(Map<String, dynamic> json) => SyncQueue(
      id: (json['id'] as num?)?.toInt(),
      tableName: json['tableName'] as String,
      recordId: (json['recordId'] as num).toInt(),
      operation: json['operation'] as String,
      data: json['data'] as Map<String, dynamic>?,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 3,
      lastAttempt: json['lastAttempt'] == null
          ? null
          : DateTime.parse(json['lastAttempt'] as String),
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SyncQueueToJson(SyncQueue instance) => <String, dynamic>{
      'id': instance.id,
      'tableName': instance.tableName,
      'recordId': instance.recordId,
      'operation': instance.operation,
      'data': instance.data,
      'attempts': instance.attempts,
      'maxAttempts': instance.maxAttempts,
      'lastAttempt': instance.lastAttempt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'createdAt': instance.createdAt.toIso8601String(),
    };
