import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Task {
  final String? id;
  final String titleTask;
  final List<String> subtasks;
  final DateTime taskTime;
  final DateTime taskDay;
  final DateTime taskReminderTime;
  bool isCompleted = false;
  final DateTime completedDay;
  final List<String> taskCategories;
  final String? userId;


  Task({
    this.id,
    required this.titleTask,
    required this.subtasks,
    required this.taskTime,
    required this.taskDay,
    required this.taskReminderTime,
    required this.isCompleted,
    required this.completedDay,
    required this.taskCategories,
    required this.userId
  });

  Task copyWith({
    String? id,
    String? titleTask,
    List<String>? subtasks,
    DateTime? taskTime,
    DateTime? taskDay,
    DateTime? taskReminderTime,
    bool? isCompleted,
    DateTime? completedDay,
    List<String>? taskCategories,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      titleTask: titleTask ?? this.titleTask,
      subtasks: subtasks ?? this.subtasks,
      taskTime: taskTime ?? this.taskTime,
      taskDay: taskDay ?? this.taskDay,
      taskReminderTime: taskReminderTime ?? this.taskReminderTime,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDay: completedDay ?? this.completedDay,
      taskCategories: taskCategories ?? this.taskCategories,
      userId: userId ?? this.userId,
    );
  }


  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return Task(
      id: snapshot.id.toString(),
      titleTask: data['titleTask'] as String,
      subtasks: (data['subtasks'] as List<dynamic>).map((item) => item as String).toList(),
      taskTime: (data['taskTime'] as Timestamp).toDate(),
      taskDay: (data['taskDay'] as Timestamp).toDate(),
      taskReminderTime: (data['taskReminderTime'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] as bool,
      completedDay: (data['completedDay'] as Timestamp).toDate(),
      taskCategories: (data['taskCategories'] as List<dynamic>).map((item) => item as String).toList(),
      userId: data['userId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titleTask': titleTask,
      'subtasks': subtasks,
      'taskTime': Timestamp.fromDate(taskTime),
      'taskDay': Timestamp.fromDate(taskDay),
      'taskReminderTime': Timestamp.fromDate(taskReminderTime),
      'taskCategories': taskCategories,
      'isCompleted': isCompleted,
      'completedDay': Timestamp.fromDate(completedDay),
      'userId': userId,
    };
  }
}