import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../task/domain/entities/deleted_task_entry.dart';
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

class _BinView extends StatelessWidget {
  const _BinView();

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

          final entries = state is BinLoaded
              ? state.entries
              : state is BinError
                  ? state.entries
                  : <DeletedTaskEntry>[];
          final isMutating = state is BinLoaded && state.isMutating;

          if (entries.isEmpty) {
            // إذا صار خطأ ومافي حتى قائمة سابقة نعرضها، منعرض حالة
            // الخطأ مع زر إعادة محاولة بدل الحالة الفارغة العادية.
            if (state is BinError) {
              return _buildErrorState(context, l10n, state.message, isDark);
            }
            return _buildEmptyState(context, l10n, isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) =>
                _buildTaskCard(context, l10n, entries[index], isDark, isMutating),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 80, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            l10n.noDeletedTasks,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : Colors.black12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n, String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<BinBloc>().add(LoadDeletedTasks()),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    AppLocalizations l10n,
    DeletedTaskEntry entry,
    bool isDark,
    bool isMutating,
  ) {
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
              // اسم المشروع والـ workspace اللي كان فيهم التاسك (Snapshot
              // محفوظ وقت الحذف، مش بيتغيّر حتى لو انحذف المشروع نفسه).
              Text(
                l10n.binItemLocation(entry.projectName, entry.workspaceName),
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.deletedAgo(_getTimeAgo(context, entry.deletedAt))} • ${_daysRemainingText(context, l10n, entry)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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

  String _daysRemainingText(BuildContext context, AppLocalizations l10n, DeletedTaskEntry entry) {
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
          // ✅ Confirm (Delete Forever) أول
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
          // ✅ Cancel تاني
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
        ],
      ),
    );
  }
}
