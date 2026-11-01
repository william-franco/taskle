enum TaskSyncState {
  synced,
  created,
  updated,
  deleted;

  static TaskSyncState fromName(String? name) {
    return TaskSyncState.values.firstWhere(
      (e) => e.name == name,
      orElse: () => TaskSyncState.synced,
    );
  }
}

class TaskModel {
  final int id;

  final int? remoteId;
  final String title;
  final String content;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TaskSyncState syncState;

  const TaskModel({
    required this.id,
    this.remoteId,
    required this.title,
    required this.content,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.syncState = TaskSyncState.synced,
  });

  bool get isPendingSync => syncState != TaskSyncState.synced;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    return TaskModel(
      id: id,
      remoteId: id,
      title: json['title'] as String,
      content: json['content'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  TaskModel copyWith({
    int? id,
    int? remoteId,
    String? title,
    String? content,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    TaskSyncState? syncState,
  }) {
    return TaskModel(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      title: title ?? this.title,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
    );
  }
}
