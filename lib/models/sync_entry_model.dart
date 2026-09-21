class SyncEntryModel {
  const SyncEntryModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action, // 'insert', 'update', 'delete'
    required this.payload,
    required this.createdAt,
    this.syncAttempts = 0,
    this.lastAttemptAt,
    this.status = 'pending', // 'pending', 'synced', 'failed'
  });

  final int? id; // local sqlite ID
  final String entityType;
  final String entityId; // usually UUID
  final String action;
  final String payload; // JSON string
  final DateTime createdAt;
  final int syncAttempts;
  final DateTime? lastAttemptAt;
  final String status;

  factory SyncEntryModel.fromJson(Map<String, dynamic> json) {
    return SyncEntryModel(
      id: json['id'] as int?,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      action: json['action'] as String,
      payload: json['payload'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      syncAttempts: json['sync_attempts'] as int? ?? 0,
      lastAttemptAt: json['last_attempt_at'] != null 
          ? DateTime.parse(json['last_attempt_at'] as String) 
          : null,
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'sync_attempts': syncAttempts,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt!.toIso8601String(),
      'status': status,
    };
  }

  SyncEntryModel copyWith({
    int? id,
    String? entityType,
    String? entityId,
    String? action,
    String? payload,
    DateTime? createdAt,
    int? syncAttempts,
    DateTime? lastAttemptAt,
    String? status,
  }) {
    return SyncEntryModel(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
    );
  }
}
