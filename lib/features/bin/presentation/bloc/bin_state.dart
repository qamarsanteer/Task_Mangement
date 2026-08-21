import 'package:equatable/equatable.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';
import '../../domain/entities/deleted_project_entry.dart';

abstract class BinState extends Equatable {
  const BinState();
  @override
  List<Object?> get props => [];
}

class BinInitial extends BinState {}
class BinLoading extends BinState {}

class BinLoaded extends BinState {
  final List<DeletedTaskEntry> taskEntries;
  final List<DeletedProjectEntry> projectEntries;
  final bool isMutating;
  final int selectedTab; // 0 = Tasks, 1 = Projects

  const BinLoaded({
    this.taskEntries = const [],
    this.projectEntries = const [],
    this.isMutating = false,
    this.selectedTab = 0,
  });

  @override
  List<Object?> get props => [taskEntries, projectEntries, isMutating, selectedTab];
}

class BinError extends BinState {
  final String message;
  final List<DeletedTaskEntry> taskEntries;
  final List<DeletedProjectEntry> projectEntries;
  final int selectedTab;

  const BinError({
    required this.message,
    this.taskEntries = const [],
    this.projectEntries = const [],
    this.selectedTab = 0,
  });

  @override
  List<Object?> get props => [message, taskEntries, projectEntries, selectedTab];
}