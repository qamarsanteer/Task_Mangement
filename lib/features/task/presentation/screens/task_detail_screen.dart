import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/attachment_bytes_cache.dart';
import 'attachment_preview_screen.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_label.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

/// شاشة تفاصيل التاسك — كل خاصية (property) هون قابلة للتعديل لحالها،
/// وبشكل منفصل عن باقي الخصائص: بيضغط المستخدم على أيقونة القلم الصغيرة
/// جنب الخاصية يلي بدو يعدلها، فيظهرلو ديالوغ فيه الحقل جاهز للتعديل،
/// وبعدين لازم يضغط "حفظ" (تأكيد) حتى تنطبق التعديلات — بالضبط متل نفس
/// النمط المستخدم بشاشة البروفايل (ProfileScreen).
///
/// كل ديالوغ تعديل، لما يحفظ، بيبعت TaskUpdateRequested بكل حقول التاسك
/// (مش بس الحقل يلي تغيّر) لأنه هيك عامل الـ Repository/UseCase بالباك
/// إند (شوفي التعليق بأعلى TaskRepository.updateTask).
class TaskDetailScreen extends StatelessWidget {
  final TaskEntity task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.taskDetails)),
      body: BlocConsumer<TaskBloc, TaskState>(
        // ─── منسمع لأي خطأ (متل فشل رفع مرفق) ومنعرضه بـ SnackBar، بدل ما
        // تفشل العملية بصمت وبدون أي إشعار للمستخدم ───
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
          // نجيب أحدث نسخة من المهمة من الـ state (بعد أي تعديل بالحالة)
          final tasks = state is TaskLoaded ? state.tasks : (state is TaskError ? state.tasks : <TaskEntity>[]);
          TaskEntity currentTask = task;
          for (final t in tasks) {
            if (t.id == task.id) {
              currentTask = t;
              break;
            }
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final label = TaskLabels.byId(currentTask.labelId);
          final isMutating = state is TaskLoaded && state.isMutating;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── العنوان ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        currentTask.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          decoration: currentTask.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    _buildEditIcon(
                      context: context,
                      isDark: isDark,
                      tooltip: l10n.editTaskTitle,
                      onPressed: isMutating ? null : () => _showEditTitleDialog(context, l10n, currentTask),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ─── الوصف ───
                _buildSectionHeader(
                  context: context,
                  isDark: isDark,
                  title: l10n.taskDescriptionLabel,
                  tooltip: l10n.editDescription,
                  onEdit: isMutating ? null : () => _showEditDescriptionDialog(context, l10n, currentTask),
                ),
                const SizedBox(height: 6),
                Text(
                  (currentTask.description != null && currentTask.description!.isNotEmpty) ? currentTask.description! : '-',
                  style: TextStyle(fontSize: 15, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),

                const SizedBox(height: 24),

                // ─── الحالة (Status) — قابلة للتعديل مباشرة (تاغز)، ما بتحتاج قلم ───
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
                      onSelected: isMutating
                          ? null
                          : (_) {
                              context.read<TaskBloc>().add(TaskStatusChangeRequested(taskId: currentTask.id, status: status));
                            },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ─── تاريخ الاستحقاق ───
                _buildEditableInfoRow(
                  context: context,
                  isDark: isDark,
                  label: l10n.dueDateLabel,
                  value: currentTask.dueDate != null ? _formatDate(currentTask.dueDate!) : '-',
                  tooltip: l10n.editDueDate,
                  onEdit: isMutating ? null : () => _showEditDueDateDialog(context, l10n, currentTask),
                ),
                if (currentTask.isOverdue) ...[
                  const SizedBox(height: 4),
                  Text(l10n.overdue, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                ],

                const SizedBox(height: 16),

                // ─── الأولوية — محورين مستقلين (أهمية/استعجال)، فبنعرض
                // حالة كل محور بوضوح حتى لما تكون "غير مهم وغير عاجل" ───
                _buildEditableInfoRow(
                  context: context,
                  isDark: isDark,
                  label: l10n.priorityLabel,
                  value:
                      '${currentTask.isImportant ? l10n.important : l10n.notImportant}، '
                      '${currentTask.isUrgent ? l10n.urgent : l10n.notUrgent}',
                  tooltip: l10n.editPriority,
                  onEdit: isMutating ? null : () => _showEditPriorityDialog(context, l10n, currentTask),
                ),

                const SizedBox(height: 16),

                // ─── التصنيف (Label) ───
                _buildSectionHeader(
                  context: context,
                  isDark: isDark,
                  title: l10n.labelField,
                  tooltip: l10n.editLabel,
                  onEdit: isMutating ? null : () => _showEditLabelDialog(context, l10n, currentTask),
                ),
                const SizedBox(height: 8),
                if (label != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Color(label.colorValue).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(_labelName(l10n, label.id), style: TextStyle(color: Color(label.colorValue), fontWeight: FontWeight.w600)),
                  )
                else
                  Text('-', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),

                const SizedBox(height: 16),

                // ─── التكرار ───
                _buildEditableInfoRow(
                  context: context,
                  isDark: isDark,
                  label: l10n.repeatEveryLabel,
                  value: _repeatLabel(l10n, currentTask.repeatFrequency),
                  tooltip: l10n.editRepeat,
                  onEdit: isMutating ? null : () => _showEditRepeatDialog(context, l10n, currentTask),
                ),

                const SizedBox(height: 16),

                // ─── تاريخ الإضافة — للعرض فقط، ما بتتعدل (حقل نظام) ───
                if (currentTask.createdAt != null) ...[
                  _buildInfoRow(context, l10n.addDateLabel, _formatDate(currentTask.createdAt!), isDark),
                  const SizedBox(height: 16),
                ],

                // ─── المرفقات ───
                _buildSectionHeader(
                  context: context,
                  isDark: isDark,
                  title: l10n.attachmentsLabel,
                  tooltip: l10n.addAttachment,
                  editIcon: Icons.add,
                  onEdit: isMutating ? null : () => _addAttachments(context, currentTask.id),
                ),
                const SizedBox(height: 8),
                if (currentTask.attachmentUrls.isEmpty)
                  Text('-', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))
                else
                  ...currentTask.attachmentUrls.map(
                    (url) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => _openAttachment(context, l10n, url),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(child: Text(url.split('/').last, overflow: TextOverflow.ellipsis)),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                                tooltip: l10n.removeAttachment,
                                visualDensity: VisualDensity.compact,
                                onPressed: isMutating ? null : () => _confirmRemoveAttachment(context, l10n, currentTask.id, url),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── عناصر بناء عامة (UI helpers) ───

  TextStyle _sectionTitleStyle(bool isDark) {
    return TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
  }

  Widget _buildEditIcon({
    required BuildContext context,
    required bool isDark,
    required String tooltip,
    required VoidCallback? onPressed,
    IconData icon = Icons.edit,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }

  /// عنوان قسم (متل "الوصف" أو "التصنيف") مع أيقونة تعديل جنبو.
  Widget _buildSectionHeader({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String tooltip,
    required VoidCallback? onEdit,
    IconData editIcon = Icons.edit,
  }) {
    return Row(
      children: [
        Text(title, style: _sectionTitleStyle(isDark)),
        const Spacer(),
        _buildEditIcon(context: context, isDark: isDark, tooltip: tooltip, onPressed: onEdit, icon: editIcon),
      ],
    );
  }

  /// صف "تسمية: قيمة" للعرض فقط، بدون أيقونة تعديل (حقول نظام).
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

  /// نفس _buildInfoRow بس مع أيقونة قلم بآخر الصف لفتح ديالوغ التعديل.
  Widget _buildEditableInfoRow({
    required BuildContext context,
    required bool isDark,
    required String label,
    required String value,
    required String tooltip,
    required VoidCallback? onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        ),
        _buildEditIcon(context: context, isDark: isDark, tooltip: tooltip, onPressed: onEdit),
      ],
    );
  }

  // ─── ديالوغات التعديل — كل واحد لحاله، وبيبعت TaskUpdateRequested بكل الحقول ───

  void _dispatchUpdate(
    BuildContext context,
    TaskEntity base, {
    String? title,
    String? description,
    bool? isImportant,
    bool? isUrgent,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? labelId,
    bool clearLabel = false,
    RepeatFrequency? repeatFrequency,
  }) {
    context.read<TaskBloc>().add(TaskUpdateRequested(
          taskId: base.id,
          title: title ?? base.title,
          description: description ?? base.description,
          isImportant: isImportant ?? base.isImportant,
          isUrgent: isUrgent ?? base.isUrgent,
          dueDate: clearDueDate ? null : (dueDate ?? base.dueDate),
          labelId: clearLabel ? null : (labelId ?? base.labelId),
          repeatFrequency: repeatFrequency ?? base.repeatFrequency,
        ));
  }

  // ─── تعديل العنوان لحاله ───
  void _showEditTitleDialog(BuildContext context, AppLocalizations l10n, TaskEntity currentTask) {
    final titleController = TextEditingController(text: currentTask.title);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.editTaskTitle),
        content: Form(
          key: formKey,
          child: CustomTextField(
            controller: titleController,
            label: l10n.taskTitleLabel,
            hint: l10n.taskTitleHint,
            autofocus: true,
            validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _dispatchUpdate(context, currentTask, title: titleController.text.trim());
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(l10n.save),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
        ],
      ),
    );
  }

  // ─── تعديل الوصف لحاله ───
  void _showEditDescriptionDialog(BuildContext context, AppLocalizations l10n, TaskEntity currentTask) {
    final descriptionController = TextEditingController(text: currentTask.description ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.editDescription),
        content: CustomTextField(
          controller: descriptionController,
          label: l10n.taskDescriptionLabel,
          hint: l10n.taskDescriptionHint,
          autofocus: true,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final value = descriptionController.text.trim();
              _dispatchUpdate(context, currentTask, description: value.isEmpty ? null : value);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(l10n.save),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
        ],
      ),
    );
  }

  // ─── تعديل تاريخ الاستحقاق لحاله ───
  void _showEditDueDateDialog(BuildContext context, AppLocalizations l10n, TaskEntity currentTask) {
    // تاريخ الاستحقاق صار حقل إجباري، فما عاد في خيار "مسح التاريخ" هون —
    // المستخدم بس بيقدر يبدّل التاريخ لتاريخ تاني، مش يخليه فاضي.
    DateTime? selectedDate = currentTask.dueDate;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.editDueDate),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() { selectedDate = picked; errorText = null; });
                },
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l10n.dueDateLabel, errorText: errorText),
                  child: Text(selectedDate != null ? _formatDate(selectedDate!) : l10n.selectDueDate),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (selectedDate == null) {
                  setState(() => errorText = l10n.requiredField);
                  return;
                }
                _dispatchUpdate(context, currentTask, dueDate: selectedDate);
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: Text(l10n.save),
            ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ],
        ),
      ),
    );
  }

  // ─── تعديل الأولوية (مهم/غير مهم) و(عاجل/غير عاجل) — محورين مستقلين،
  // كل واحد فيهم اختيار إجباري بين قيمتين، فما فيه حاجة لأي validation
  // لأنه دايماً في قيمة محددة ───
  void _showEditPriorityDialog(BuildContext context, AppLocalizations l10n, TaskEntity currentTask) {
    bool isImportant = currentTask.isImportant;
    bool isUrgent = currentTask.isUrgent;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.editPriority),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _dispatchUpdate(context, currentTask, isImportant: isImportant, isUrgent: isUrgent);
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: Text(l10n.save),
            ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ],
        ),
      ),
    );
  }

  // ─── تعديل التصنيف (Label) لحاله ───
  void _showEditLabelDialog(BuildContext context, AppLocalizations l10n, TaskEntity currentTask) {
    // التصنيف صار حقل إجباري، فشلنا خيار "بدون تصنيف" — المستخدم لازم
    // يختار تصنيف من القائمة، وبيقدر بس يبدّل التصنيف مش يمسحه بالكامل.
    String? selectedLabelId = currentTask.labelId;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.editLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskLabels.predefined.map((option) {
                  final selected = selectedLabelId == option.id;
                  return ChoiceChip(
                    label: Text(_labelName(l10n, option.id)),
                    selected: selected,
                    selectedColor: Color(option.colorValue),
                    labelStyle: TextStyle(color: selected ? Colors.white : null),
                    onSelected: (_) => setState(() { selectedLabelId = option.id; errorText = null; }),
                  );
                }).toList(),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (selectedLabelId == null) {
                  setState(() => errorText = l10n.requiredField);
                  return;
                }
                _dispatchUpdate(context, currentTask, labelId: selectedLabelId);
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: Text(l10n.save),
            ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ],
        ),
      ),
    );
  }

  // ─── تعديل التكرار لحاله ───
  void _showEditRepeatDialog(BuildContext context, AppLocalizations l10n, TaskEntity currentTask) {
    RepeatFrequency repeatFrequency = currentTask.repeatFrequency;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.editRepeat),
          content: DropdownButtonFormField<RepeatFrequency>(
            value: repeatFrequency,
            decoration: InputDecoration(labelText: l10n.repeatEveryLabel),
            items: RepeatFrequency.values.map((f) => DropdownMenuItem(value: f, child: Text(_repeatLabel(l10n, f)))).toList(),
            onChanged: (value) => setState(() => repeatFrequency = value ?? RepeatFrequency.none),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _dispatchUpdate(context, currentTask, repeatFrequency: repeatFrequency);
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: Text(l10n.save),
            ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ],
        ),
      ),
    );
  }

  // ─── إضافة مرفقات — بتنفتح مباشرة (بدون ديالوغ تأكيد إضافي، لأنه اختيار
  // الملفات نفسه هو التأكيد؛ بمجرد ما تختار ملف بينرفع فوراً) ───
  Future<void> _addAttachments(BuildContext context, String taskId) async {
    final bloc = context.read<TaskBloc>();
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
    if (result != null) {
      // على الويب (Chrome)، الوصول لـ PlatformFile.path مش بيرجّع null —
      // عم يرمي Exception فوراً (file_picker 8.x)! يعني ?? ما كانت توصل
      // تشتغل أصلاً، والاستثناء كان عم يوقع بمنتصف .map() بدون ما ينلقط
      // بأي مكان، فـ Bloc ما كان يوصله الـ event نهائياً — هيك بالضبط كانت
      // بتصير المشكلة بصمت. هلق منتفادى لمس .path كلياً إذا كنا عالويب.
      final paths = result.files.map((f) => kIsWeb ? f.name : (f.path ?? f.name)).toList();
      // منخزّن محتوى الملف (bytes) بالذاكرة حتى نقدر نفتحه/نعاينه من نفس
      // الشاشة (شوفي attachment_bytes_cache.dart لتفاصيل ليش بالذاكرة بس).
      for (final f in result.files) {
        if (f.bytes != null) {
          AttachmentBytesCache.instance.put(kIsWeb ? f.name : (f.path ?? f.name), f.bytes!);
        }
      }
      if (paths.isNotEmpty) {
        bloc.add(TaskAttachmentAddRequested(taskId: taskId, filePaths: paths));
      }
    }
  }

  // ─── حذف مرفق موجود — منسأل تأكيد قبل ما نحذف، لأنه هون فعل غير قابل
  // للتراجع (ما متل الإضافة يلي بتصير مباشرة) ───
  void _confirmRemoveAttachment(BuildContext context, AppLocalizations l10n, String taskId, String url) {
    final bloc = context.read<TaskBloc>();
    final fileName = url.split('/').last;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.removeAttachment),
        content: Text('${l10n.deleteTaskConfirm(fileName)}\n${l10n.actionCannotBeUndone}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              bloc.add(TaskAttachmentRemoveRequested(taskId: taskId, attachmentUrl: url));
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

  // ─── فتح/معاينة مرفق موجود بالضغط عليه — هلق منفتح شاشة معاينة جوا
  // التطبيق (AttachmentPreviewScreen) بدل ما نخلي الملف ينزّل مباشرة
  // عالجهاز؛ التحميل الفعلي صار فعل منفصل وصريح جوا هاي الشاشة (زر
  // "تحميل") ───
  Future<void> _openAttachment(BuildContext context, AppLocalizations l10n, String url) async {
    final bytes = AttachmentBytesCache.instance.get(url);
    if (bytes == null) {
      // صار Refresh للصفحة أو التطبيق أعيد فتحه من جديد، فمحتوى الملف
      // (المخزّن بالذاكرة بس حالياً لعدم وجود سيرفر حقيقي) ضاع، وضل بس
      // اسمه محفوظ. هاد قيد مؤقت لحد ما ينضاف سيرفر رفع فعلي.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.attachmentContentUnavailable),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttachmentPreviewScreen(fileName: url.split('/').last, bytes: bytes),
      ),
    );
  }

  // ─── Helpers نصّية ───

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