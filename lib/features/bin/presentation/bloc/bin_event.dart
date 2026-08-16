import 'package:equatable/equatable.dart';

abstract class BinEvent extends Equatable {
  const BinEvent();
  @override
  List<Object?> get props => [];
}

/// طلب تحميل قائمة سلة المحذوفات. البلوك بيعمل تنظيف تلقائي (lazy purge)
/// لأي تاسك عدّى عليه 30 يوم قبل ما يرجّع القائمة (نفس منطق
/// TaskRepository.getDeletedTasks).
class LoadDeletedTasks extends BinEvent {}

/// استرجاع تاسك من السلة لمكانه الأصلي (نفس المشروع اللي كان فيه).
class RestoreTask extends BinEvent {
  final String taskId;
  const RestoreTask(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

/// حذف نهائي من السلة — ما في رجعة بعده.
class DeleteTaskForever extends BinEvent {
  final String taskId;
  const DeleteTaskForever(this.taskId);
  @override
  List<Object?> get props => [taskId];
}
