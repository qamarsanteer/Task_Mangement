import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/attachment_bytes_cache.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/entities/task_label.dart';
import '../../../task/presentation/bloc/task_bloc.dart';
import '../../../task/presentation/bloc/task_event.dart';
import '../../../task/presentation/screens/task_detail_screen.dart';
import '../../domain/entities/project_option.dart';
import '../../domain/entities/task_with_context.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CalendarBloc>(),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  bool _tasksLoaded = false;   // عشان ما نعيد التحميل كل مرة تتغير فيها الـ dependencies

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _displayedMonth = DateTime(now.year, now.month, 1);
    // شيلنا _loadTasks() من هون
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tasksLoaded) {
      _tasksLoaded = true;
      _loadTasks();
    }
  }

  void _loadTasks() {
    final l10n = AppLocalizations.of(context)!;
    context.read<CalendarBloc>().add(CalendarTasksLoadRequested(inboxLabel: l10n.inbox));
  }


  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<TaskWithContext> _tasksForSelectedDate(List<TaskWithContext> allTasks) {
    return allTasks.where((entry) {
      final due = entry.task.dueDate;
      if (due == null) return false;
      return _isSameDay(due, _selectedDate);
    }).toList()
      ..sort((a, b) => a.task.title.compareTo(b.task.title));
  }

  bool _hasTaskOn(List<TaskWithContext> allTasks, DateTime day) {
    return allTasks.any((entry) {
      final due = entry.task.dueDate;
      if (due == null) return false;
      return _isSameDay(due, day);
    });
  }

  void _goToPreviousMonth() {
    setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1));
  }

  void _goToNextMonth() {
    setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1));
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _displayedMonth = DateTime(date.year, date.month, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    _selectDate(DateTime(now.year, now.month, now.day));
  }

  Future<void> _openTaskDetail(TaskWithContext entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<TaskBloc>()..add(TasksLoadRequested(entry.projectId)),
          child: TaskDetailScreen(task: entry.task),
        ),
      ),
    );
    if (mounted) _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendar),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showComingSoon(context, l10n)),
          if (!isToday)
            TextButton(
              onPressed: _goToToday,
              child: Text(l10n.today),
            ),
        ],
      ),
      body: BlocConsumer<CalendarBloc, CalendarState>(
        listener: (context, state) {
          if (state is CalendarError) {
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
          final isLoading = state is CalendarLoading || state is CalendarInitial;
          final hasError = state is CalendarError;

          final allTasks = state is CalendarLoaded
              ? state.tasks
              : state is CalendarError
                  ? state.tasks
                  : <TaskWithContext>[];
          final workspaces = state is CalendarLoaded
              ? state.workspaces
              : state is CalendarError
                  ? state.workspaces
                  : const [];
          final projectOptions = state is CalendarLoaded
              ? state.projectOptions
              : state is CalendarError
                  ? state.projectOptions
                  : const <ProjectOption>[];

          return RefreshIndicator(
            onRefresh: () async => _loadTasks(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildCalendarCard(context, locale, allTasks)),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ..._buildTasksSlivers(context, l10n, allTasks, workspaces, projectOptions, isLoading, hasError),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, String locale, List<TaskWithContext> allTasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthLabel = DateFormat.yMMMM(locale).format(_displayedMonth);

    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    final referenceSunday = DateTime(2023, 1, 1);
    final weekdayLabels = List.generate(7, (i) {
      final d = referenceSunday.add(Duration(days: i));
      final name = DateFormat.E(locale).format(d);
      return name.isNotEmpty ? name.substring(0, 1) : '';
    });

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _goToPreviousMonth,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _goToNextMonth,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ],
          ),
          Row(
            children: weekdayLabels
                .map((label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          for (int row = 0; row < rowCount; row++)
            Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNumber = cellIndex - leadingBlanks + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }
                final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
                return Expanded(child: _buildDayCell(context, date, isDark, allTasks));
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, bool isDark, List<TaskWithContext> allTasks) {
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final hasTask = _hasTaskOn(allTasks, date);

    Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    if (isSelected) textColor = Colors.white;

    return InkWell(
      onTap: () => _selectDate(date),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: (!isSelected && isToday) ? Border.all(color: AppColors.primary, width: 1.5) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (hasTask)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTasksSlivers(
    BuildContext context,
    AppLocalizations l10n,
    List<TaskWithContext> allTasks,
    List workspaces,
    List<ProjectOption> projectOptions,
    bool isLoading,
    bool hasError,
  ) {
    final formattedDate = DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(_selectedDate);
    final tasks = _tasksForSelectedDate(allTasks);

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.calendarTasksOn(formattedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (!isLoading && tasks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (hasError)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.calendarLoadError, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                ],
              ),
            ),
          ),
        ),
      if (isLoading)
        const SliverPadding(
          padding: EdgeInsets.only(top: 40, bottom: 40),
          sliver: SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
        )
      else if (tasks.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(context, l10n, workspaces, projectOptions),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == tasks.length * 2) {
                  return _buildAddTaskTile(context, l10n, workspaces, projectOptions);
                }
                if (index.isOdd) return const SizedBox(height: 12);
                return _buildTaskTile(context, l10n, tasks[index ~/ 2]);
              },
              childCount: tasks.length * 2 + 1,
            ),
          ),
        ),
    ];
  }

  Widget _buildAddTaskTile(
    BuildContext context,
    AppLocalizations l10n,
    List workspaces,
    List<ProjectOption> projectOptions,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showAddTaskDialog(context, l10n, workspaces, projectOptions),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
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

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.comingSoon),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    List workspaces,
    List<ProjectOption> projectOptions,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined, size: 64, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: _buildAddTaskTile(context, l10n, workspaces, projectOptions)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, AppLocalizations l10n, TaskWithContext entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final task = entry.task;
    final label = TaskLabels.byId(task.labelId);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openTaskDetail(entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_box_outline_blank, color: AppColors.error),
                    tooltip: l10n.calendarDeleteTaskTooltip,
                    onPressed: () => _confirmDeleteTask(context, l10n, entry),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    iconSize: 20,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ),
                  if (label != null) ...[
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(label.colorValue), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                  ],
                  _buildPriorityIcon(task),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${entry.workspaceName} • ${entry.projectName}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, AppLocalizations l10n, TaskWithContext entry) {
    final bloc = context.read<CalendarBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteTaskTitle),
        content: Text('${l10n.deleteTaskConfirm(entry.task.title)}\n${l10n.actionCannotBeUndone}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              bloc.add(CalendarTaskDeleteRequested(entry));
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

    return Icon(icon, size: 16, color: color);
  }

  void _showAddTaskDialog(
    BuildContext context,
    AppLocalizations l10n,
    List workspacesRaw,
    List<ProjectOption> projectOptions,
  ) {
    final workspaces = workspacesRaw.cast();
    if (workspaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noProjectsForTask),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final bloc = context.read<CalendarBloc>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<String> attachmentPaths = [];

    final workspaceOptions = workspaces.map((w) => MapEntry(w.id as String, w.name as String)).toList();

    String? selectedWorkspaceId = workspaceOptions.length == 1 ? workspaceOptions.first.key : null;
    ProjectOption? selectedProject;
    if (selectedWorkspaceId != null) {
      final projectsInWorkspace = projectOptions.where((o) => o.workspaceId == selectedWorkspaceId).toList();
      if (projectsInWorkspace.length == 1) selectedProject = projectsInWorkspace.first;
    }
    DateTime? selectedDate = _selectedDate;
    bool isImportant = true;
    bool isUrgent = true;
    String? selectedLabelId;
    RepeatFrequency repeatFrequency = RepeatFrequency.none;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final projectsForWorkspace = selectedWorkspaceId == null
              ? const <ProjectOption>[]
              : projectOptions.where((o) => o.workspaceId == selectedWorkspaceId).toList();

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
                    FormField<String>(
                      initialValue: selectedWorkspaceId,
                      validator: (value) => value == null ? l10n.requiredField : null,
                      builder: (field) => InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.workspace,
                          errorText: field.errorText,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedWorkspaceId,
                            hint: Text(l10n.selectWorkspaceHint),
                            items: workspaceOptions
                                .map((entry) => DropdownMenuItem(
                                      value: entry.key,
                                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedWorkspaceId = value;
                                selectedProject = null;
                              });
                              field.didChange(value);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormField<ProjectOption>(
                      key: ValueKey(selectedWorkspaceId),
                      initialValue: selectedProject,
                      validator: (value) => value == null ? l10n.requiredField : null,
                      builder: (field) => InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.selectProjectLabel,
                          errorText: field.errorText,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ProjectOption>(
                            isExpanded: true,
                            value: selectedProject,
                            hint: Text(l10n.selectProjectHint),
                            items: projectsForWorkspace
                                .map((option) => DropdownMenuItem(
                                      value: option,
                                      child: Text(option.projectName, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: selectedWorkspaceId == null
                                ? null
                                : (value) {
                                    setDialogState(() => selectedProject = value);
                                    field.didChange(value);
                                  },
                          ),
                        ),
                      ),
                    ),
                    if (selectedWorkspaceId != null && projectsForWorkspace.isEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.noProjectsInWorkspace,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                      ),
                    ],
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
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
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
                  final project = selectedProject;
                  if (project == null) return;

                  Navigator.pop(dialogContext);
                  bloc.add(CalendarTaskCreateRequested(
                    project: project,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                    isImportant: isImportant,
                    isUrgent: isUrgent,
                    dueDate: selectedDate,
                    labelId: selectedLabelId,
                    repeatFrequency: repeatFrequency,
                    attachmentPaths: attachmentPaths,
                    inboxLabel: l10n.inbox,
                  ));

                  if (selectedDate != null) {
                    _selectDate(DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day));
                  }
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