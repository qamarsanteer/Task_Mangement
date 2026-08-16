import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/utils/attachment_bytes_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/segmented_toggle.dart';
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
  // اسم الـ workspace اللي المشروع تابع إلها — لازم يوصل من الشاشة اللي
  // فتحت TasksScreen (ProjectsScreen)، لأنه ProjectEntity ما فيها اسم
  // الـ workspace، بس id تبعها. منستخدمو كـ Snapshot وقت حذف أي تاسك.
  final String workspaceName;
  const TasksScreen({super.key, required this.project, required this.workspaceName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskBloc>()..add(TasksLoadRequested(project.id)),
      child: _TasksView(project: project, workspaceName: workspaceName),
    );
  }
}

class _TasksView extends StatefulWidget {
  final ProjectEntity project;
  final String workspaceName;
  const _TasksView({required this.project, required this.workspaceName});

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _activateSelection(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  void _selectAll(List<TaskEntity> items) {
    setState(() {
      _selectedIds.addAll(items.map((e) => e.id));
    });
  }

  void _confirmDeleteSelected(BuildContext context, AppLocalizations l10n) {
    final bloc = context.read<TaskBloc>();
    final count = _selectedIds.length;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteTaskTitle),
        content: Text('Are you sure you want to delete $count task(s)?\n${l10n.actionCannotBeUndone}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              bloc.add(TasksDeleteRequested(
                _selectedIds.toList(),
                projectName: widget.project.name,
                workspaceId: widget.project.workspaceId,
                workspaceName: widget.workspaceName,
              ));
              Navigator.pop(dialogContext);
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                TextButton(
                  onPressed: () {
                    final state = context.read<TaskBloc>().state;
                    final items = state is TaskLoaded
                        ? state.tasks
                        : state is TaskError
                            ? state.tasks
                            : <TaskEntity>[];
                    _selectAll(items);
                  },
                  child: const Text('Select All', style: TextStyle(color: Colors.white)),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => _confirmDeleteSelected(context, l10n),
                ),
              ],
            )
          : AppBar(
              title: Text(widget.project.name),
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
                  : [];

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

  Widget _buildTaskTile(BuildContext context, AppLocalizations l10n, TaskEntity task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = TaskLabels.byId(task.labelId);
    final isSelected = _selectedIds.contains(task.id);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.15)
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(task.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<TaskBloc>(),
                  child: TaskDetailScreen(task: task),
                ),
              ),
            );
          }
        },
        onLongPress: () => _activateSelection(task.id),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // checkbox أو زر الحذف الفردي
            _isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(task.id),
                    activeColor: AppColors.primary,
                  )
                : IconButton(
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

            // الثلاث مؤشرات
            if (!_isSelectionMode)
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
    // الأولوية صارت محورين مستقلين، كل واحد فيهم إجباري وإله قيمة افتراضية
    // واضحة (مهم/عاجل) — المستخدم بيقدر يبدلها لكن ما فيه حالة "بدون قيمة".
    bool isImportant = true;
    bool isUrgent = true;
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
                  FormField<DateTime>(
                    initialValue: selectedDate,
                    validator: (value) => value == null ? l10n.requiredField : null,
                    builder: (field) => InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                          field.didChange(picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.dueDateLabel,
                          errorText: field.errorText,
                        ),
                        child: Text(selectedDate != null ? _formatFullDate(selectedDate!) : l10n.selectDueDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ─── الأهمية والاستعجال صاروا محورين مستقلين، كل واحد
                  // فيهم اختيار إجباري بين قيمتين، بدل تشيك بوكس اختياري ───
                  SegmentedToggle(
                    label: l10n.importanceLabel,
                    trueLabel: l10n.important,
                    falseLabel: l10n.notImportant,
                    value: isImportant,
                    onChanged: (value) => setState(() => isImportant = value),
                  ),
                  const SizedBox(height: 12),
                  SegmentedToggle(
                    label: l10n.urgencyLabel,
                    trueLabel: l10n.urgent,
                    falseLabel: l10n.notUrgent,
                    value: isUrgent,
                    onChanged: (value) => setState(() => isUrgent = value),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.labelField, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  FormField<String>(
                    initialValue: selectedLabelId,
                    validator: (value) => value == null ? l10n.requiredField : null,
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              onSelected: (_) {
                                // ما منسمحش نلغي التحديد ونرجع لـ null هون —
                                // التصنيف صار حقل إجباري، فلازم يضل في تصنيف
                                // محدد دايماً (المستخدم بس بيقدر يبدّل التصنيف
                                // مش يمسحه بالكامل).
                                final newValue = label.id;
                                setState(() => selectedLabelId = newValue);
                                field.didChange(newValue);
                              },
                            );
                          }).toList(),
                        ),
                        if (field.errorText != null) ...[
                          const SizedBox(height: 6),
                          Text(field.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<RepeatFrequency>(
                    value: repeatFrequency,
                    decoration: InputDecoration(labelText: l10n.repeatEveryLabel),
                    items: RepeatFrequency.values
                        .map((f) => DropdownMenuItem(value: f, child: Text(_repeatLabel(l10n, f))))
                        .toList(),
                    onChanged: (value) => setState(() => repeatFrequency = value ?? RepeatFrequency.none),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
                      if (result != null) {
                        // على الويب (Chrome) الـ file_picker ما بيرجّع path أبداً (بيرجع null)،
                        // فلازم نرجع لاسم الملف كـ fallback، وإلا القائمة بتضل فاضية بصمت.
                        final selected = result.files.map((f) => kIsWeb ? f.name : (f.path ?? f.name)).toList();
                        // منخزّن محتوى الملف (bytes) بالذاكرة حتى نقدر نفتحه/نعاينه لاحقاً
                        // من شاشة تفاصيل التاسك (شوفي attachment_bytes_cache.dart).
                        for (final f in result.files) {
                          if (f.bytes != null) {
                            AttachmentBytesCache.instance.put(kIsWeb ? f.name : (f.path ?? f.name), f.bytes!);
                          }
                        }
                        setState(() {
                          // منضيف الملفات الجداد لقائمة الملفات المختارة سابقاً بدل
                          // ما نستبدلها بالكامل — قبل هيك، لو المستخدم ضغط زر
                          // الإرفاق أكتر من مرة (مثلاً حتى يضيف مرفقات بدفعات)، كانت
                          // آخر دفعة تلغي/تمسح الدفعات يلي قبلها، وهيك عملياً كان
                          // التاسك بينخلق بمرفق واحد بس مهما حاول المستخدم يضيف أكتر.
                          // منستبعد أي مسار موجود مسبقاً حتى ما نكرر نفس الملف مرتين.
                          for (final path in selected) {
                            if (!attachmentPaths.contains(path)) {
                              attachmentPaths.add(path);
                            }
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      attachmentPaths.isEmpty ? l10n.attachmentsLabel : l10n.addMoreAttachments,
                    ),
                  ),
                  if (attachmentPaths.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('${attachmentPaths.length} ${l10n.filesSelected}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: attachmentPaths.map((path) {
                        final fileName = path.split(RegExp(r'[\\/]')).last;
                        return Chip(
                          label: Text(fileName, overflow: TextOverflow.ellipsis),
                          onDeleted: () => setState(() => attachmentPaths.remove(path)),
                          deleteIconColor: AppColors.error,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  bloc.add(TaskCreateRequested(
                    projectId: widget.project.id,
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ],
        ),
      ),
    );
  }

  String _labelName(AppLocalizations l10n, String id) {
    switch (id) {
      case 'work': return l10n.labelWork;
      case 'personal': return l10n.labelPersonal;
      case 'study': return l10n.labelStudy;
      case 'health': return l10n.labelHealth;
      case 'finance': return l10n.labelFinance;
      default: return l10n.labelOther;
    }
  }

  String _repeatLabel(AppLocalizations l10n, RepeatFrequency frequency) {
    switch (frequency) {
      case RepeatFrequency.daily: return l10n.repeatDaily;
      case RepeatFrequency.weekly: return l10n.repeatWeekly;
      case RepeatFrequency.monthly: return l10n.repeatMonthly;
      case RepeatFrequency.none: return l10n.repeatNone;
    }
  }

  String _formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _confirmDeleteTask(BuildContext context, AppLocalizations l10n, TaskEntity task) {
    final bloc = context.read<TaskBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteTaskTitle),
        content: Text('${l10n.deleteTaskConfirm(task.title)}\n${l10n.actionCannotBeUndone}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              bloc.add(TaskDeleteRequested(
                task.id,
                projectName: widget.project.name,
                workspaceId: widget.project.workspaceId,
                workspaceName: widget.workspaceName,
              ));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
        ],
      ),
    );
  }

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