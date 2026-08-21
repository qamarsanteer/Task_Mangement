import 'package:equatable/equatable.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../domain/entities/project_option.dart';
import '../../domain/entities/task_with_context.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();
  @override
  List<Object?> get props => [];
}

class CalendarTasksLoadRequested extends CalendarEvent {
  final String inboxLabel;
  const CalendarTasksLoadRequested({required this.inboxLabel});
  @override
  List<Object?> get props => [inboxLabel];
}

class CalendarTaskCreateRequested extends CalendarEvent {
  final ProjectOption project;
  final String title;
  final String? description;
  final bool isImportant;
  final bool isUrgent;
  final DateTime? dueDate;
  final String? labelId;
  final RepeatFrequency repeatFrequency;
  final List<String> attachmentPaths;
  final String inboxLabel;

  const CalendarTaskCreateRequested({
    required this.project,
    required this.title,
    this.description,
    required this.isImportant,
    required this.isUrgent,
    this.dueDate,
    this.labelId,
    required this.repeatFrequency,
    this.attachmentPaths = const [],
    required this.inboxLabel,
  });

  @override
  List<Object?> get props => [
        project,
        title,
        description,
        isImportant,
        isUrgent,
        dueDate,
        labelId,
        repeatFrequency,
        attachmentPaths,
        inboxLabel,
      ];
}

class CalendarTaskDeleteRequested extends CalendarEvent {
  final TaskWithContext entry;
  const CalendarTaskDeleteRequested(this.entry);
  @override
  List<Object?> get props => [entry];
}