import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_label.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskEntity task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.taskDetails)),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          // نجيب أحدث نسخة من المهمة من الـ state (بعد أي تعديل بالحالة)
          final tasks = state is TaskLoaded ? state.tasks : (state is TaskError ? state.tasks : <TaskEntity>[]);
          final currentTask = tasks.firstWhere((t) => t.id == task.id, orElse: () => task);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final label = TaskLabels.byId(currentTask.labelId);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTask.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    decoration: currentTask.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (currentTask.description != null && currentTask.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    currentTask.description!,
                    style: TextStyle(fontSize: 15, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ],

                const SizedBox(height: 24),

                // الحالة (Status) — قابلة للتعديل هون بس
                Text(l10n.status, style: _sectionTitleStyle(isDark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TaskStatus.values.map((status) {
                    final selected = currentTask.status == status;
                    return ChoiceChip(
                      label: Text(_statusLabel(l10n, status)),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
                      onSelected: (_) {
                        context.read<TaskBloc>().add(TaskStatusChangeRequested(taskId: currentTask.id, status: status));
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                _buildInfoRow(context, l10n.dueDateLabel, currentTask.dueDate != null ? _formatDate(currentTask.dueDate!) : '-', isDark),
                if (currentTask.isOverdue) ...[
                  const SizedBox(height: 4),
                  Text(l10n.overdue, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                ],

                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  l10n.priorityLabel,
                  '${currentTask.isImportant ? l10n.important : ''} ${currentTask.isUrgent ? l10n.urgent : ''}'.trim().isEmpty
                      ? '-'
                      : '${currentTask.isImportant ? l10n.important : ''} ${currentTask.isUrgent ? l10n.urgent : ''}'.trim(),
                  isDark,
                ),

                const SizedBox(height: 16),
                if (label != null) ...[
                  Text(l10n.labelField, style: _sectionTitleStyle(isDark)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Color(label.colorValue).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(_labelName(l10n, label.id), style: TextStyle(color: Color(label.colorValue), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                ],

                if (currentTask.repeatFrequency != RepeatFrequency.none) ...[
                  _buildInfoRow(context, l10n.repeatEveryLabel, _repeatLabel(l10n, currentTask.repeatFrequency), isDark),
                  const SizedBox(height: 16),
                ],

                if (currentTask.createdAt != null) ...[
                  _buildInfoRow(context, l10n.addDateLabel, _formatDate(currentTask.createdAt!), isDark),
                  const SizedBox(height: 16),
                ],

                if (currentTask.attachmentUrls.isNotEmpty) ...[
                  Text(l10n.attachmentsLabel, style: _sectionTitleStyle(isDark)),
                  const SizedBox(height: 8),
                  ...currentTask.attachmentUrls.map(
                    (url) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(url.split('/').last, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  TextStyle _sectionTitleStyle(bool isDark) {
    return TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        ),
      ],
    );
  }

  String _statusLabel(AppLocalizations l10n, TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return l10n.taskStatusNotStarted;
      case TaskStatus.inProgress:
        return l10n.taskStatusInProgress;
      case TaskStatus.completed:
        return l10n.taskStatusCompleted;
    }
  }

  String _repeatLabel(AppLocalizations l10n, RepeatFrequency frequency) {
    switch (frequency) {
      case RepeatFrequency.daily:
        return l10n.repeatDaily;
      case RepeatFrequency.weekly:
        return l10n.repeatWeekly;
      case RepeatFrequency.monthly:
        return l10n.repeatMonthly;
      case RepeatFrequency.none:
        return l10n.repeatNone;
    }
  }

  String _labelName(AppLocalizations l10n, String id) {
    switch (id) {
      case 'work':
        return l10n.labelWork;
      case 'personal':
        return l10n.labelPersonal;
      case 'study':
        return l10n.labelStudy;
      case 'health':
        return l10n.labelHealth;
      case 'finance':
        return l10n.labelFinance;
      default:
        return l10n.labelOther;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}