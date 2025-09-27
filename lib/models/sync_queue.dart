import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'sync_queue.g.dart';

@JsonSerializable()
class SyncQueue {
  final int? id;
  final String tableName;
  final int recordId;
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic>? data;
  final int attempts;
  final int maxAttempts;
  final DateTime? lastAttempt;
  final String? errorMessage;
  final DateTime createdAt;

  SyncQueue({
    this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    this.data,
    this.attempts = 0,
    this.maxAttempts = 3,
    this.lastAttempt,
    this.errorMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SyncQueue.fromJson(Map<String, dynamic> json) => _$SyncQueueFromJson(json);
  Map<String, dynamic> toJson() => _$SyncQueueToJson(this);

  factory SyncQueue.fromDatabase(Map<String, dynamic> map) {
    return SyncQueue(
      id: map['id'],
      tableName: map['table_name'],
      recordId: map['record_id'],
      operation: map['operation'],
      data: map['data'] != null 
          ? json.decode(map['data']) as Map<String, dynamic>
          : null,
      attempts: map['attempts'] ?? 0,
      maxAttempts: map['max_attempts'] ?? 3,
      lastAttempt: map['last_attempt'] != null 
          ? DateTime.parse(map['last_attempt']) 
          : null,
      errorMessage: map['error_message'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': data != null ? json.encode(data) : null,
      'attempts': attempts,
      'max_attempts': maxAttempts,
      'last_attempt': lastAttempt?.toIso8601String(),
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SyncQueue copyWith({
    int? id,
    String? tableName,
    int? recordId,
    String? operation,
    Map<String, dynamic>? data,
    int? attempts,
    int? maxAttempts,
    DateTime? lastAttempt,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return SyncQueue(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      recordId: recordId ?? this.recordId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasReachedMaxAttempts => attempts >= maxAttempts;
  bool get hasFailed => errorMessage?.isNotEmpty == true;
  bool get canRetry => !hasReachedMaxAttempts && !hasFailed;

  String get operationDisplay {
    switch (operation) {
      case 'create':
        return 'Create';
      case 'update':
        return 'Update';
      case 'delete':
        return 'Delete';
      default:
        return operation;
    }
  }

  String get statusDisplay {
    if (hasReachedMaxAttempts) {
      return 'Failed (Max attempts reached)';
    }
    if (hasFailed) {
      return 'Failed';
    }
    if (attempts > 0) {
      return 'Retrying ($attempts/$maxAttempts)';
    }
    return 'Pending';
  }

  Duration? get timeSinceLastAttempt {
    if (lastAttempt != null) {
      return DateTime.now().difference(lastAttempt!);
    }
    return null;
  }

  Duration get timeSinceCreation {
    return DateTime.now().difference(createdAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncQueue && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SyncQueue(id: $id, tableName: $tableName, recordId: $recordId, operation: $operation, attempts: $attempts)';
  }
}