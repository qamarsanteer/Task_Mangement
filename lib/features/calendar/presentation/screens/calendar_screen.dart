import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../project/domain/usecases/get_projects_usecase.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/entities/task_label.dart';
import '../../../task/domain/usecases/get_tasks_usecase.dart';
import '../../../task/presentation/bloc/task_bloc.dart';
import '../../../task/presentation/bloc/task_event.dart';
import '../../../task/presentation/screens/task_detail_screen.dart';
import '../../../workspace/domain/usecases/get_workspaces_usecase.dart';

/// تاسك مع سياقه (بأي مشروع وبأي ورك سبيس هو)، حتى نقدر نعرضه بشاشة
/// الكالندر يلي بتجمع تاسكات من كل المشاريع/الورك سبيسات مع بعض.
class _TaskWithContext {
  final TaskEntity task;
  final String projectId;
  final String projectName;
  final String workspaceName;

  const _TaskWithContext({
    required this.task,
    required this.projectId,
    required this.projectName,
    required this.workspaceName,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  bool _isLoading = true;
  bool _hasError = false;
  List<_TaskWithContext> _allTasks = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _displayedMonth = DateTime(now.year, now.month, 1);
    _loadAllTasks();
  }

  /// منجيب كل الورك سبيسات، وبكل وحدة فيهم كل المشاريع، وبكل مشروع كل
  /// التاسكات — وهيك منضمن إنو الكالندر بيشوف تاسكات المستخدم كلها،
  /// مهما كان المشروع أو الورك سبيس يلي هي فيه.
  Future<void> _loadAllTasks() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final workspacesResult = await getIt<GetWorkspacesUseCase>()();

      final workspaces = workspacesResult.fold(
        (failure) => null,
        (list) => list,
      );

      if (workspaces == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      final collected = <_TaskWithContext>[];

      for (final workspace in workspaces) {
        final projectsResult = await getIt<GetProjectsUseCase>()(workspace.id);
        final projects = projectsResult.fold((failure) => null, (list) => list);
        if (projects == null) continue;

        for (final project in projects) {
          final tasksResult = await getIt<GetTasksUseCase>()(project.id);
          final tasks = tasksResult.fold((failure) => null, (list) => list);
          if (tasks == null) continue;

          for (final task in tasks) {
            collected.add(_TaskWithContext(
              task: task,
              projectId: project.id,
              projectName: project.name,
              workspaceName: workspace.name,
            ));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _allTasks = collected;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<_TaskWithContext> get _tasksForSelectedDate {
    return _allTasks.where((entry) {
      final due = entry.task.dueDate;
      if (due == null) return false;
      return _isSameDay(due, _selectedDate);
    }).toList()
      ..sort((a, b) => a.task.title.compareTo(b.task.title));
  }

  bool _hasTaskOn(DateTime day) {
    return _allTasks.any((entry) {
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

  Future<void> _openTaskDetail(_TaskWithContext entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<TaskBloc>()..add(TasksLoadRequested(entry.projectId)),
          child: TaskDetailScreen(task: entry.task),
        ),
      ),
    );
    // بعد الرجوع من شاشة التفاصيل، ممكن يكون في تعديل صار على التاسك
    // (تغيير حالة، تعديل تاريخ، حذف...) فمنعيد التحميل حتى الكالندر
    // يضل متوافق مع آخر تحديث.
    _loadAllTasks();
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
          if (!isToday)
            TextButton(
              onPressed: _goToToday,
              child: Text(l10n.today),
            ),
          IconButton(
            icon: const Icon(Icons.event_outlined),
            tooltip: l10n.calendarPickDate,
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) _selectDate(picked);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllTasks,
        color: AppColors.primary,
        // ─── صرنا نستخدم CustomScrollView واحد للصفحة كلها (الكالندر +
        // الليستة) بدل Column/Expanded منفصلين. هيك لو الشاشة قصيرة أو
        // الكالندر إله ارتفاع كبير (6 أسابيع مثلاً)، الليستة ما بتنضغط
        // لارتفاع صفر — المستخدم بس بيقدر يسحب/يزحلق لتحت ليشوفها،
        // بدل ما تختفي بالكامل بدون أي إشعار.
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildCalendarCard(context, locale)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ..._buildTasksSlivers(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, String locale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthLabel = DateFormat.yMMMM(locale).format(_displayedMonth);

    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    // الأحد = 0 .. السبت = 6 (DateTime.weekday: الاثنين = 1 .. الأحد = 7)
    final leadingBlanks = firstOfMonth.weekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    // أسماء الأيام (حرف واحد) حسب اللغة الحالية، بادئين من الأحد.
    final referenceSunday = DateTime(2023, 1, 1); // أحد
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
                return Expanded(child: _buildDayCell(context, date, isDark));
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, bool isDark) {
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final hasTask = _hasTaskOn(date);

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

  List<Widget> _buildTasksSlivers(BuildContext context, AppLocalizations l10n) {
    final formattedDate = DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(_selectedDate);
    final tasks = _tasksForSelectedDate;

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
              if (!_isLoading && tasks.isNotEmpty)
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
      if (_hasError)
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
      if (_isLoading)
        const SliverPadding(
          padding: EdgeInsets.only(top: 40, bottom: 40),
          sliver: SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
        )
      else if (tasks.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(context, l10n),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index.isOdd) return const SizedBox(height: 12);
                return _buildTaskTile(context, l10n, tasks[index ~/ 2]);
              },
              childCount: tasks.length * 2 - 1,
            ),
          ),
        ),
    ];
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, AppLocalizations l10n, _TaskWithContext entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final task = entry.task;
    final label = TaskLabels.byId(task.labelId);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openTaskDetail(entry),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                if (label != null) ...[
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(label.colorValue), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                ],
                _buildPriorityIcon(task),
              ],
            ),
            const SizedBox(height: 8),
            Row(
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
          ],
        ),
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
}
