import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../project/domain/entities/project_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_label.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatelessWidget {
  final ProjectEntity project;
  const TasksScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskBloc>()..add(TasksLoadRequested(project.id)),
      child: _TasksView(project: project),
    );
  }
}

class _TasksView extends StatelessWidget {
  final ProjectEntity project;
  const _TasksView({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showComingSoon(context, l10n)),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showComingSoon(context, l10n)),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showViewSelector(context, l10n)),
        ],
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TaskLoading || state is TaskInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = state is TaskLoaded
              ? state.tasks
              : state is TaskError
                  ? state.tasks
                  : <TaskEntity>[];

          if (tasks.isEmpty) {
            return _buildEmptyState(context, l10n);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == tasks.length) {
                return _buildAddTaskTile(context, l10n);
              }
              return _buildTaskTile(context, l10n, tasks[index]);
            },
          );
        },
      ),
    );
  }

  // ---------- Empty state ----------

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_outlined, size: 72, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(l10n.noTasks, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            Text(l10n.noTasksSubtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddTaskDialog(context, l10n),
              icon: const Icon(Icons.add),
              label: Text(l10n.addTask),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Task tile ----------

  Widget _buildTaskTile(BuildContext context, AppLocalizations l10n, TaskEntity task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = TaskLabels.byId(task.labelId);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<TaskBloc>(),
              child: TaskDetailScreen(task: task),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // مربع الحذف
            IconButton(
              icon: const Icon(Icons.check_box_outline_blank, color: AppColors.error),
              tooltip: l10n.delete,
              onPressed: () => _confirmDeleteTask(context, l10n, task),
            ),

            // العنوان
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),

            // الثلاث مؤشرات: Label + Priority + Due Date
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) _buildDot(Color(label.colorValue)),
                  if (label != null) const SizedBox(width: 6),
                  _buildPriorityIcon(task),
                  if (task.dueDate != null) ...[
                    const SizedBox(width: 6),
                    _buildDueDateChip(task, isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _buildPriorityIcon(TaskEntity task) {
    IconData icon = Icons.flag_outlined;
    Color color = AppColors.textSecondaryLight;

    if (task.isImportant && task.isUrgent) {
      icon = Icons.flag;
      color = AppColors.error;
    } else if (task.isImportant) {
      icon = Icons.flag;
      color = Colors.orange;
    } else if (task.isUrgent) {
      icon = Icons.flag;
      color = Colors.amber;
    }

    return Icon(icon, size: 18, color: color);
  }

  Widget _buildDueDateChip(TaskEntity task, bool isDark) {
    final color = task.isOverdue ? AppColors.error : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    return Row(
      children: [
        Icon(Icons.event_outlined, size: 14, color: color),
        const SizedBox(width: 2),
        Text(_formatDate(task.dueDate!), style: TextStyle(fontSize: 11, color: color, fontWeight: task.isOverdue ? FontWeight.w700 : FontWeight.normal)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  // ---------- Add task tile/dialog ----------

  Widget _buildAddTaskTile(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showAddTaskDialog(context, l10n),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(l10n.addTask, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AppLocalizations l10n) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final bloc = context.read<TaskBloc>();

    DateTime? selectedDate;
    bool isImportant = false;
    bool isUrgent = false;
    String? selectedLabelId;
    RepeatFrequency repeatFrequency = RepeatFrequency.none;
    List<String> attachmentPaths = [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.addTask),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: titleController,
                    label: l10n.taskTitleLabel,
                    hint: l10n.taskTitleHint,
                    autofocus: true,
                    validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: descriptionController,
                    label: l10n.taskDescriptionLabel,
                    hint: l10n.taskDescriptionHint,
                  ),
                  const SizedBox(height: 16),

                  // تاريخ الاستحقاق
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: l10n.dueDateLabel),
                      child: Text(selectedDate != null ? _formatFullDate(selectedDate!) : l10n.selectDueDate),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // الأولوية
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isImportant,
                          onChanged: (value) => setState(() => isImportant = value ?? false),
                          title: Text(l10n.important, style: const TextStyle(fontSize: 13)),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isUrgent,
                          onChanged: (value) => setState(() => isUrgent = value ?? false),
                          title: Text(l10n.urgent, style: const TextStyle(fontSize: 13)),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Label
                  Text(l10n.labelField, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskLabels.predefined.map((label) {
                      final selected = selectedLabelId == label.id;
                      return ChoiceChip(
                        label: Text(_labelName(l10n, label.id)),
                        selected: selected,
                        selectedColor: Color(label.colorValue),
                        labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 12),
                        onSelected: (_) => setState(() => selectedLabelId = selected ? null : label.id),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // التكرار
                  DropdownButtonFormField<RepeatFrequency>(
                    value: repeatFrequency,
                    decoration: InputDecoration(labelText: l10n.repeatEveryLabel),
                    items: RepeatFrequency.values
                        .map((f) => DropdownMenuItem(value: f, child: Text(_repeatLabel(l10n, f))))
                        .toList(),
                    onChanged: (value) => setState(() => repeatFrequency = value ?? RepeatFrequency.none),
                  ),

                  const SizedBox(height: 16),

                  // المرفقات
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                      if (result != null) {
                        setState(() => attachmentPaths = result.paths.whereType<String>().toList());
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(attachmentPaths.isEmpty ? l10n.attachmentsLabel : '${attachmentPaths.length} ${l10n.filesSelected}'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  bloc.add(TaskCreateRequested(
                    projectId: project.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                    isImportant: isImportant,
                    isUrgent: isUrgent,
                    dueDate: selectedDate,
                    labelId: selectedLabelId,
                    repeatFrequency: repeatFrequency,
                    attachmentPaths: attachmentPaths,
                  ));
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
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

  String _formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ---------- Delete confirmation ----------

  void _confirmDeleteTask(BuildContext context, AppLocalizations l10n, TaskEntity task) {
    final bloc = context.read<TaskBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteTaskTitle),
        content: Text('${l10n.deleteTaskConfirm(task.title)}\n${l10n.actionCannotBeUndone}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              bloc.add(TaskDeleteRequested(task.id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  // ---------- View selector ----------

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.comingSoon), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  void _showViewSelector(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.selectView, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 8),
              ListTile(leading: const Icon(Icons.check, color: AppColors.primary), title: Text(l10n.viewList), onTap: () => Navigator.pop(sheetContext)),
              ListTile(leading: const Icon(Icons.view_column_outlined), title: Text(l10n.viewBoard), onTap: () { Navigator.pop(sheetContext); _showComingSoon(context, l10n); }),
              ListTile(leading: const Icon(Icons.view_timeline_outlined), title: Text(l10n.viewTimeline), onTap: () { Navigator.pop(sheetContext); _showComingSoon(context, l10n); }),
              ListTile(leading: const Icon(Icons.calendar_month_outlined), title: Text(l10n.viewCalendar), onTap: () { Navigator.pop(sheetContext); _showComingSoon(context, l10n); }),
            ],
          ),
        ),
      ),
    );
  }
}