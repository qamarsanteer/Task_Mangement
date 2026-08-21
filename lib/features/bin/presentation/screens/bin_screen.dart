import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';
import '../../domain/entities/deleted_project_entry.dart';
import '../bloc/bin_bloc.dart';
import '../bloc/bin_event.dart';
import '../bloc/bin_state.dart';

class BinScreen extends StatelessWidget {
  const BinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BinBloc>()..add(LoadDeletedTasks()),
      child: const _BinView(),
    );
  }
}

class _BinView extends StatefulWidget {
  const _BinView();

  @override
  State<_BinView> createState() => _BinViewState();
}

class _BinViewState extends State<_BinView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final bloc = context.read<BinBloc>();
      if (_tabController.index == 0) {
        bloc.add(LoadDeletedTasks());
      } else {
        bloc.add(LoadDeletedProjects());
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bin),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.deletedTasks),
            Tab(text: l10n.deletedProjects),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: BlocConsumer<BinBloc, BinState>(
        listener: (context, state) {
          if (state is BinError) {
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
          if (state is BinLoading || state is BinInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final taskEntries = state is BinLoaded ? state.taskEntries
              : state is BinError ? state.taskEntries : <DeletedTaskEntry>[];
          final projectEntries = state is BinLoaded ? state.projectEntries
              : state is BinError ? state.projectEntries : <DeletedProjectEntry>[];
          final isMutating = state is BinLoaded && state.isMutating;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskTab(context, l10n, taskEntries, isDark, isMutating),
              _buildProjectTab(context, l10n, projectEntries, isDark, isMutating),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskTab(BuildContext context, AppLocalizations l10n,
      List<DeletedTaskEntry> entries, bool isDark, bool isMutating) {
    if (entries.isEmpty) return _buildEmptyState(context, l10n, isDark, l10n.noDeletedTasks);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildTaskCard(context, l10n, entries[index], isDark, isMutating),
    );
  }

  Widget _buildProjectTab(BuildContext context, AppLocalizations l10n,
      List<DeletedProjectEntry> entries, bool isDark, bool isMutating) {
    if (entries.isEmpty) return _buildEmptyState(context, l10n, isDark, l10n.noDeletedProjects);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildProjectCard(context, l10n, entries[index], isDark, isMutating),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 80, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : Colors.black12)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, AppLocalizations l10n,
      DeletedTaskEntry entry, bool isDark, bool isMutating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        title: Text(entry.task.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.binItemLocation(entry.projectName, entry.workspaceName),
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.deletedAgo(_getTimeAgo(context, entry.deletedAt))} • ${_daysRemainingText(context, l10n, entry)}',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: entry.daysRemaining <= 1 ? AppColors.error : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
        trailing: IgnorePointer(
          ignoring: isMutating,
          child: Opacity(
            opacity: isMutating ? 0.4 : 1,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) => value == 'restore'
                  ? _restoreTask(context, l10n, entry)
                  : _deleteForever(context, l10n, entry),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'restore',
                  child: Row(children: [const Icon(Icons.restore, color: AppColors.success), const SizedBox(width: 12), Text(l10n.restore)]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [const Icon(Icons.delete_forever, color: AppColors.error), const SizedBox(width: 12), Text(l10n.deleteForever)]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, AppLocalizations l10n,
      DeletedProjectEntry entry, bool isDark, bool isMutating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.folder_open, color: AppColors.primary),
        ),
        title: Text(entry.project.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.workspaceName} • ${entry.taskCount} ${l10n.tasks}',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.deletedAgo(_getTimeAgo(context, entry.deletedAt))} • ${_projectDaysRemainingText(context, l10n, entry)}',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: entry.daysRemaining <= 1 ? AppColors.error : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
        trailing: IgnorePointer(
          ignoring: isMutating,
          child: Opacity(
            opacity: isMutating ? 0.4 : 1,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'restore') _restoreProject(context, l10n, entry);
                else if (value == 'delete') _deleteProjectForever(context, l10n, entry);
                else if (value == 'view') _showProjectTasks(context, l10n, entry, isDark);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(children: [const Icon(Icons.visibility, color: AppColors.primary), const SizedBox(width: 12), Text(l10n.viewTasks)]),
                ),
                PopupMenuItem(
                  value: 'restore',
                  child: Row(children: [const Icon(Icons.restore, color: AppColors.success), const SizedBox(width: 12), Text(l10n.restore)]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [const Icon(Icons.delete_forever, color: AppColors.error), const SizedBox(width: 12), Text(l10n.deleteForever)]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProjectTasks(BuildContext context, AppLocalizations l10n, DeletedProjectEntry entry, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${entry.project.name} — ${l10n.tasks}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (entry.tasks.isEmpty)
              Text(l10n.noTasks, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: entry.tasks.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.check_circle_outline, size: 20),
                    title: Text(entry.tasks[i].title, style: const TextStyle(fontSize: 14)),
                    dense: true,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _daysRemainingText(BuildContext context, AppLocalizations l10n, DeletedTaskEntry entry) {
    if (entry.daysRemaining <= 1) return l10n.lastDayRemaining;
    return l10n.daysRemaining(entry.daysRemaining);
  }

  String _projectDaysRemainingText(BuildContext context, AppLocalizations l10n, DeletedProjectEntry entry) {
    if (entry.daysRemaining <= 1) return l10n.lastDayRemaining;
    return l10n.daysRemaining(entry.daysRemaining);
  }

  String _getTimeAgo(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} ${l10n.daysAgo}';
    if (diff.inHours > 0) return '${diff.inHours} ${l10n.hoursAgo}';
    return l10n.justNow;
  }

  void _restoreTask(BuildContext context, AppLocalizations l10n, DeletedTaskEntry entry) {
    context.read<BinBloc>().add(RestoreTask(entry.taskId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.taskRestored), backgroundColor: AppColors.success),
    );
  }

  void _deleteForever(BuildContext context, AppLocalizations l10n, DeletedTaskEntry entry) {
    final binBloc = context.read<BinBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteForever),
        content: Text(l10n.actionCannotBeUndone),
        actions: [
          ElevatedButton(
            onPressed: () {
              binBloc.add(DeleteTaskForever(entry.taskId));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.taskDeletedForever), backgroundColor: AppColors.error),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
        ],
      ),
    );
  }

  void _restoreProject(BuildContext context, AppLocalizations l10n, DeletedProjectEntry entry) {
    context.read<BinBloc>().add(RestoreProject(entry.projectId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.projectRestored), backgroundColor: AppColors.success),
    );
  }

  void _deleteProjectForever(BuildContext context, AppLocalizations l10n, DeletedProjectEntry entry) {
    final binBloc = context.read<BinBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteProjectForever),
        content: Text(l10n.projectDeleteWarning(entry.taskCount)),
        actions: [
          ElevatedButton(
            onPressed: () {
              binBloc.add(DeleteProjectForever(entry.projectId));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.projectDeletedForever), backgroundColor: AppColors.error),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
        ],
      ),
    );
  }
}