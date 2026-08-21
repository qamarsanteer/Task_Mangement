import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/events/task_changes_bus.dart';
import '../../../../core/utils/attachment_bytes_cache.dart';
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

class TimelineViewScreen extends StatelessWidget {
  final ProjectEntity project;
  final String workspaceName;

  const TimelineViewScreen({
    super.key,
    required this.project,
    required this.workspaceName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskBloc>()..add(TasksLoadRequested(project.id)),
      child: _TimelineView(project: project, workspaceName: workspaceName),
    );
  }
}

class _TimelineView extends StatefulWidget {
  final ProjectEntity project;
  final String workspaceName;

  const _TimelineView({required this.project, required this.workspaceName});

  @override
  State<_TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<_TimelineView> {
  static const double _hourRowHeight = 64;
  static const double _hourLabelWidth = 52;
  static const int _collapsedNoTimeCount = 3;

  late DateTime _selectedDay;
  bool _noTimeExpanded = false;
  StreamSubscription<String>? _taskChangesSubscription;
  final ScrollController _hourScrollController = ScrollController();
  bool _didAutoScroll = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);

    _taskChangesSubscription = getIt<TaskChangesBus>().onProjectChanged.listen((changedProjectId) {
      if (changedProjectId == widget.project.id && mounted) {
        context.read<TaskBloc>().add(TasksLoadRequested(widget.project.id));
      }
    });
  }

  @override
  void dispose() {
    _taskChangesSubscription?.cancel();
    _hourScrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _loadTasks() {
    context.read<TaskBloc>().add(TasksLoadRequested(widget.project.id));
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDay = _selectedDay.subtract(const Duration(days: 1));
      _noTimeExpanded = false;
      _didAutoScroll = !_isSameDay(_selectedDay, DateTime.now());
    });
  }

  void _goToNextDay() {
    setState(() {
      _selectedDay = _selectedDay.add(const Duration(days: 1));
      _noTimeExpanded = false;
      _didAutoScroll = !_isSameDay(_selectedDay, DateTime.now());
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDay = DateTime(now.year, now.month, now.day);
      _noTimeExpanded = false;
    });
    _didAutoScroll = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScrollToNow());
  }

  int _untimedPriorityScore(TaskEntity task) {
    if (task.isImportant && task.isUrgent) return 0;
    if (task.isImportant) return 1;
    if (task.isUrgent) return 2;
    return 3;
  }

  List<TaskEntity> _tasksForSelectedDay(List<TaskEntity> allTasks) {
    return allTasks.where((task) {
      final start = task.startDate;
      if (start == null) return false;
      return _isSameDay(start, _selectedDay);
    }).toList();
  }

  bool _hasTaskOn(List<TaskEntity> allTasks, DateTime day) {
    return allTasks.any((task) {
      final start = task.startDate;
      if (start == null) return false;
      return _isSameDay(start, day);
    });
  }

  void _autoScrollToNow() {
    if (_didAutoScroll || !_hourScrollController.hasClients) return;
    if (!_isSameDay(_selectedDay, DateTime.now())) return;
    _didAutoScroll = true;
    final targetHour = (DateTime.now().hour - 1).clamp(0, 23);
    _hourScrollController.animateTo(
      targetHour * _hourRowHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openTaskDetail(TaskEntity task) async {
    final bloc = context.read<TaskBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: TaskDetailScreen(task: task),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isToday = _isSameDay(_selectedDay, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.project.name} · ${l10n.viewTimeline}'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showComingSoon(context, l10n)),
          if (!isToday)
            TextButton(
              onPressed: _goToToday,
              child: Text(l10n.today),
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
          final isLoading = state is TaskInitial || state is TaskLoading;
          final allTasks = state is TaskLoaded
              ? state.tasks
              : state is TaskError
                  ? state.tasks
                  : const <TaskEntity>[];

          final dayTasks = _tasksForSelectedDay(allTasks);
          final untimedTasks = dayTasks.where((t) => !t.hasStartTime).toList()
            ..sort((a, b) {
              final scoreCompare = _untimedPriorityScore(a).compareTo(_untimedPriorityScore(b));
              if (scoreCompare != 0) return scoreCompare;
              final aCreated = a.createdAt ?? DateTime(1970);
              final bCreated = b.createdAt ?? DateTime(1970);
              return aCreated.compareTo(bCreated);
            });
          final timedTasks = dayTasks.where((t) => t.hasStartTime).toList()
            ..sort((a, b) => a.startDate!.compareTo(b.startDate!));

          if (!isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _autoScrollToNow());
          }

          return RefreshIndicator(
            onRefresh: () async => _loadTasks(),
            color: AppColors.primary,
            child: Column(
              children: [
                _buildDayHeader(context, l10n, allTasks),
                if (isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (dayTasks.isEmpty)
                  Expanded(child: _buildEmptyState(context, l10n))
                else ...[
                  _buildNoTimeSection(context, l10n, untimedTasks),
                  Expanded(child: _buildHourlyGrid(context, l10n, timedTasks)),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context, l10n),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.addTask),
      ),
    );
  }



  Widget _buildDayHeader(BuildContext context, AppLocalizations l10n, List<TaskEntity> allTasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = _isSameDay(_selectedDay, DateTime.now());
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat.yMMMMEEEEd(locale).format(_selectedDay);
    final hasTask = _hasTaskOn(allTasks, _selectedDay);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPreviousDay,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickSpecificDay(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Text(
                      dayLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isToday ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                    if (hasTask)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextDay,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }

  Future<void> _pickSpecificDay(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      final now = DateTime.now();
      final isPickedToday = picked.year == now.year && picked.month == now.month && picked.day == now.day;
      setState(() {
        _selectedDay = DateTime(picked.year, picked.month, picked.day);
        _noTimeExpanded = false;
        _didAutoScroll = !isPickedToday;
      });
    }
  }


  Widget _buildNoTimeSection(BuildContext context, AppLocalizations l10n, List<TaskEntity> untimedTasks) {
    if (untimedTasks.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleTasks = _noTimeExpanded ? untimedTasks : untimedTasks.take(_collapsedNoTimeCount).toList();
    final hiddenCount = untimedTasks.length - visibleTasks.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.timelineNoTimeSection,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${untimedTasks.length}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final task in visibleTasks) ...[
            _buildUntimedTaskRow(context, l10n, task),
            const SizedBox(height: 6),
          ],
          if (hiddenCount > 0 || _noTimeExpanded)
            InkWell(
              onTap: () => setState(() => _noTimeExpanded = !_noTimeExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _noTimeExpanded ? l10n.timelineShowLess : l10n.timelineShowAll(untimedTasks.length),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUntimedTaskRow(BuildContext context, AppLocalizations l10n, TaskEntity task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = TaskLabels.byId(task.labelId);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openTaskDetail(task),
      onLongPress: () => _confirmDeleteTask(context, l10n, task),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _buildPriorityIcon(task, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (label != null) Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(label.colorValue), shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

 
  Widget _buildHourlyGrid(BuildContext context, AppLocalizations l10n, List<TaskEntity> timedTasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDay, now);

    final Map<int, List<TaskEntity>> tasksByHour = {for (int h = 0; h < 24; h++) h: []};
    for (final task in timedTasks) {
      final hour = task.startDate!.hour.clamp(0, 23);
      tasksByHour[hour]!.add(task);
    }

    return ListView.builder(
      controller: _hourScrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: 24,
      itemBuilder: (context, hour) {
        final isCurrentHour = isToday && hour == now.hour;
        final tasksThisHour = tasksByHour[hour]!;

        return IntrinsicHeight(
          child: Container(
            constraints: const BoxConstraints(minHeight: _hourRowHeight),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.6)),
              color: isCurrentHour ? AppColors.primary.withOpacity(0.05) : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _hourLabelWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrentHour ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrentHour ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 2,
                  margin: const EdgeInsets.only(top: 6),
                  color: isCurrentHour ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: tasksThisHour.isEmpty
                        ? const SizedBox(height: _hourRowHeight - 12)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final task in tasksThisHour) ...[
                                _buildTimedTaskCard(context, l10n, task),
                                const SizedBox(height: 6),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimedTaskCard(BuildContext context, AppLocalizations l10n, TaskEntity task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = TaskLabels.byId(task.labelId);
    final timeLabel = DateFormat.Hm(Localizations.localeOf(context).toString()).format(task.startDate!);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 3))],
        border: Border(left: BorderSide(color: label != null ? Color(label.colorValue) : AppColors.primary, width: 3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openTaskDetail(task),
        onLongPress: () => _confirmDeleteTask(context, l10n, task),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Text(
                timeLabel,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              _buildPriorityIcon(task, size: 14),
            ],
          ),
        ),
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
            Icon(Icons.view_timeline_outlined, size: 64, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              l10n.calendarNoTasksForDate,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.calendarNoTasksForDateSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.comingSoon),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPriorityIcon(TaskEntity task, {double size = 16}) {
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

    return Icon(icon, size: size, color: color);
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

  void _showAddTaskDialog(BuildContext context, AppLocalizations l10n) {
    final bloc = context.read<TaskBloc>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<String> attachmentPaths = [];

    DateTime? selectedStartDate = _selectedDay;
    TimeOfDay? selectedStartTime;
    DateTime? selectedDueDate;
    bool isImportant = true;
    bool isUrgent = true;
    String? selectedLabelId;
    RepeatFrequency repeatFrequency = RepeatFrequency.none;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
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
                      initialValue: selectedStartDate,
                      validator: (value) => value == null ? l10n.requiredField : null,
                      builder: (field) => InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedStartDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedStartDate = picked);
                            field.didChange(picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.startDateLabel,
                            errorText: field.errorText,
                          ),
                          child: Text(selectedStartDate != null ? _formatFullDate(selectedStartDate!) : l10n.selectStartDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    FormField<TimeOfDay>(
                      initialValue: selectedStartTime,
                      builder: (field) => InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedStartTime = picked);
                            field.didChange(picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(labelText: l10n.startTimeLabel),
                          child: Text(selectedStartTime != null ? selectedStartTime!.format(dialogContext) : l10n.selectStartTime),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    FormField<DateTime>(
                      initialValue: selectedDueDate,
                      validator: (value) => value == null ? l10n.requiredField : null,
                      builder: (field) => InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDueDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDueDate = picked);
                            field.didChange(picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.dueDateLabel,
                            errorText: field.errorText,
                          ),
                          child: Text(selectedDueDate != null ? _formatFullDate(selectedDueDate!) : l10n.selectDueDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedToggle(
                      label: l10n.importanceLabel,
                      trueLabel: l10n.important,
                      falseLabel: l10n.notImportant,
                      value: isImportant,
                      onChanged: (value) => setDialogState(() => isImportant = value),
                    ),
                    const SizedBox(height: 12),
                    SegmentedToggle(
                      label: l10n.urgencyLabel,
                      trueLabel: l10n.urgent,
                      falseLabel: l10n.notUrgent,
                      value: isUrgent,
                      onChanged: (value) => setDialogState(() => isUrgent = value),
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
                                  final newValue = label.id;
                                  setDialogState(() => selectedLabelId = newValue);
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
                      onChanged: (value) => setDialogState(() => repeatFrequency = value ?? RepeatFrequency.none),
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
                          setDialogState(() {
                            for (final path in selected) {
                              if (!attachmentPaths.contains(path)) {
                                attachmentPaths.add(path);
                              }
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(attachmentPaths.isEmpty ? l10n.attachmentsLabel : l10n.addMoreAttachments),
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
                            onDeleted: () => setDialogState(() => attachmentPaths.remove(path)),
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
                  if (!formKey.currentState!.validate()) return;

                  final combinedStartDate = DateTime(
                    selectedStartDate!.year,
                    selectedStartDate!.month,
                    selectedStartDate!.day,
                    selectedStartTime?.hour ?? 0,
                    selectedStartTime?.minute ?? 0,
                  );

                  Navigator.pop(dialogContext);
                  bloc.add(TaskCreateRequested(
                    projectId: widget.project.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                    isImportant: isImportant,
                    isUrgent: isUrgent,
                    dueDate: selectedDueDate,
                    startDate: combinedStartDate,
                    hasStartTime: selectedStartTime != null,
                    labelId: selectedLabelId,
                    repeatFrequency: repeatFrequency,
                    attachmentPaths: attachmentPaths,
                  ));

                  setState(() {
                    _selectedDay = DateTime(selectedStartDate!.year, selectedStartDate!.month, selectedStartDate!.day);
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: Text(l10n.create),
              ),
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            ],
          );
        },
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
}