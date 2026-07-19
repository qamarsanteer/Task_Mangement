class TaskModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final bool isDeleted;
  final DateTime? dueDate;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.isDeleted = false,
    this.dueDate,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      isCompleted: json['is_completed'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'is_deleted': isDeleted,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    bool? isDeleted,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
