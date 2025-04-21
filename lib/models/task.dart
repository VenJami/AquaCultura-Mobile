import 'package:flutter/foundation.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final String priority;
  final String assignee;
  final String assigneeName;
  final bool isCompleted;
  final DateTime? completedAt;
  final String createdBy;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.assignee,
    required this.assigneeName,
    required this.isCompleted,
    this.completedAt,
    required this.createdBy,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    print('Raw task JSON: $json');

    // Check if the assignee is an object with _id field (MongoDB populated reference)
    var assigneeId = '';
    if (json['assignee'] is Map) {
      assigneeId = json['assignee']['_id'] ?? '';
      print('Extracted assignee ID from object: $assigneeId');
    } else {
      assigneeId = json['assignee'] ?? '';
      print('Using direct assignee value: $assigneeId');
    }

    return Task(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Untitled Task',
      description: json['description'] ?? '',
      dueDate:
          DateTime.parse(json['dueDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'Pending',
      priority: json['priority'] ?? 'Medium',
      assignee: assigneeId,
      assigneeName: json['assigneeName'] ?? '',
      isCompleted: json['status'] == 'Completed',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      createdBy: json['createdBy'] is Map
          ? (json['createdBy']['_id'] ?? '')
          : (json['createdBy'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'priority': priority,
      'assignee': assignee,
      'assigneeName': assigneeName,
      'completedAt': completedAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    String? priority,
    String? assignee,
    String? assigneeName,
    bool? isCompleted,
    DateTime? completedAt,
    String? createdBy,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignee: assignee ?? this.assignee,
      assigneeName: assigneeName ?? this.assigneeName,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
