import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/attachment_bytes_cache.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../project/domain/entities/project_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_label.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import 'task_detail_screen.dart';

/// وصف عمود واحد بالـ Board (ربع من مصفوفة أيزنهاور: أهمية × استعجال).
/// كل عمود بيعرض بس التاسكات يلي بتطابق (isImportant, isUrgent) تبعتو،
/// وضمن نفس المشروع الحالي (project.id) — مش كل تاسكات الـ workspace.
class _Quadrant {
  final bool isImportant;
  final bool isUrgent;
  final IconData icon;
  final Color color;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) subtitle;

  _Quadrant({
    required this.isImportant,
    required this.isUrgent,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

final List<_Quadrant> _quadrants = [
  _Quadrant(
    isImportant: true,
    isUrgent: true,
    icon: Icons.flag,
    color: AppColors.error,
    title: (l10n) => l10n.eisenhowerDoFirst,
    subtitle: (l10n) => l10n.doItNow,
  ),
  _Quadrant(
    isImportant: true,
    isUrgent: false,
    icon: Icons.flag,
    color: Colors.orange,
    title: (l10n) => l10n.eisenhowerPlan,
    subtitle: (l10n) => l10n.planIt,
  ),
  _Quadrant(
    isImportant: false,
    isUrgent: true,
    icon: Icons.flag,
    color: Colors.amber,
    title: (l10n) => l10n.eisenhowerDelegate,
    subtitle: (l10n) => l10n.delegateIt,
  ),
  _Quadrant(
    isImportant: false,
    isUrgent: false,
    icon: Icons.flag,
    color: AppColors.textSecondaryLight,
    title: (l10n) => l10n.eisenhowerEliminate,
    subtitle: (l10n) => l10n.later,
  ),
];

/// شاشة عرض تاسكات مشروع واحد بشكل Board مبني على مصفوفة أيزنهاور
/// (مهم/عاجل). أربع أعمدة ثابتة — بدون drag & drop حالياً، التنقل بين
/// الأرباع بيصير من شاشة تفاصيل التاسك (تعديل isImportant/isUrgent).
/// بتستخدم نفس TaskBloc الموجود مسبقاً بالـ context (مررناه بـ
/// BlocProvider.value من TasksScreen)، فمافي تحميل إضافي ولا استدعاء
/// جديد للـ API — هاي بس شاشة عرض/تصنيف تانية لنفس التاسكات المحمّلة.
class BoardViewScreen extends StatelessWidget {
  final ProjectEntity project;
  final String workspaceName;
  const BoardViewScreen({super.key, required this.project, required this.workspaceName});

@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return Scaffold(
    appBar: AppBar(
      title: Text(project.name),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.comingSoon),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.comingSoon),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
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

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            itemCount: _quadrants.length,
            itemBuilder: (context, index) {
              final quadrant = _quadrants[index];
              final columnTasks = tasks
                  .where((t) => t.isImportant == quadrant.isImportant && t.isUrgent == quadrant.isUrgent)
                  .toList();
              return _BoardColumn(
                quadrant: quadrant,
                tasks: columnTasks,
                project: project,
                workspaceName: workspaceName,
              );
            },
          );
        },
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  final _Quadrant quadrant;
  final List<TaskEntity> tasks;
  final ProjectEntity project;
  final String workspaceName;

  const _BoardColumn({
    required this.quadrant,
    required this.tasks,
    required this.project,
    required this.workspaceName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, l10n, isDark),
          const Divider(height: 1),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.boardColumnEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _BoardCard(
                    task: tasks[index],
                    isDark: isDark,
                    project: project,
                    workspaceName: workspaceName,
                  ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          Icon(
            quadrant.icon,
            color: quadrant.color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quadrant.title(l10n),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  quadrant.subtitle(l10n),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: quadrant.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${tasks.length}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: quadrant.color),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: quadrant.color, size: 22),
            tooltip: l10n.addTask,
            onPressed: () => _showQuickAddDialog(context, l10n),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// ديالوج إضافة التاسك بالبورد — نفس حقول ديالوج الإضافة بشاشة
  /// الكالندر/التاسكات بالضبط (كل الحقول إجبارية ما عدا الوصف
  /// والمرفقات)، بفرق واحد: هون الأهمية والاستعجال مش قابلين للتعديل
  /// من المستخدم إطلاقاً — بيتثبتوا تلقائياً حسب العمود (الربع) يلي
  /// المستخدم ضغط "إضافة" فيه، وبيظهروا بس كبطاقة للعرض (Read-only).
  void _showQuickAddDialog(BuildContext context, AppLocalizations l10n) {
    final bloc = context.read<TaskBloc>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    DateTime? selectedDate;
    String? selectedLabelId;
    RepeatFrequency repeatFrequency = RepeatFrequency.none;
    List<String> attachmentPaths = [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(quadrant.icon, color: quadrant.color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(quadrant.title(l10n))),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة تعرض الأهمية/الاستعجال الثابتين تبع هاد العمود
                  // بس للعرض — المستخدم ما بيقدر يبدلهم من هون، لأنهم
                  // محددين أصلاً حسب العمود يلي ضغط "إضافة" فيه.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: quadrant.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: quadrant.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(quadrant.icon, color: quadrant.color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n.importanceLabel}: ${quadrant.isImportant ? l10n.important : l10n.notImportant}'
                            '  •  '
                            '${l10n.urgencyLabel}: ${quadrant.isUrgent ? l10n.urgent : l10n.notUrgent}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: quadrant.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        final selected = result.files.map((f) => kIsWeb ? f.name : (f.path ?? f.name)).toList();
                        for (final f in result.files) {
                          if (f.bytes != null) {
                            AttachmentBytesCache.instance.put(kIsWeb ? f.name : (f.path ?? f.name), f.bytes!);
                          }
                        }
                        setState(() {
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
                    projectId: project.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                    // ثابتين حسب العمود (الربع) وما إلهم علاقة بأي اختيار
                    // من المستخدم بهاد الديالوج.
                    isImportant: quadrant.isImportant,
                    isUrgent: quadrant.isUrgent,
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
}

class _BoardCard extends StatelessWidget {
  final TaskEntity task;
  final bool isDark;
  final ProjectEntity project;
  final String workspaceName;

  const _BoardCard({
    required this.task,
    required this.isDark,
    required this.project,
    required this.workspaceName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = TaskLabels.byId(task.labelId);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<TaskBloc>(),
              child: TaskDetailScreen(task: task),
            ),
          ),
        ),
        child: Padding(
          // مساواة من كل الجهات — ما عاد في زر ثابت على اليمين
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════
              // صف العنوان + مربع الحذف (يتحرك حسب اتجاه اللغة)
              // ═══════════════════════════════════════════════════════
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,  // نفس TasksScreen
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_box_outline_blank, color: AppColors.error),
                    tooltip: l10n.delete,
                    onPressed: () => _confirmDelete(context, l10n),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (label != null || task.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (label != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: Color(label.colorValue), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (task.dueDate != null) ...[
                      Icon(
                        Icons.event_outlined,
                        size: 13,
                        color: task.isOverdue
                            ? AppColors.error
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatDate(task.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: task.isOverdue ? FontWeight.w700 : FontWeight.normal,
                          color: task.isOverdue
                              ? AppColors.error
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppLocalizations l10n) {
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
                projectName: project.name,
                workspaceId: project.workspaceId,
                workspaceName: workspaceName,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}