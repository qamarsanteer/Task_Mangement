import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../l10n/app_localizations.dart';

class BinScreen extends StatefulWidget {
  const BinScreen({super.key});
  @override
  State<BinScreen> createState() => _BinScreenState();
}

class _BinScreenState extends State<BinScreen> {
  final List<Map<String, dynamic>> _deletedTasks = [
    {'id': '1', 'title': 'Complete project documentation', 'date': DateTime.now().subtract(const Duration(days: 2))},
    {'id': '2', 'title': 'Review pull requests', 'date': DateTime.now().subtract(const Duration(days: 5))},
    {'id': '3', 'title': 'Update dependencies', 'date': DateTime.now().subtract(const Duration(days: 7))},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bin),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: _deletedTasks.isEmpty ? _buildEmptyState(context, isDark) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _deletedTasks.length,
        itemBuilder: (context, index) => _buildTaskCard(context, _deletedTasks[index], isDark),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.delete_outline, size: 80, color: isDark ? Colors.white24 : Colors.black12),
      const SizedBox(height: 16),
      Text(l10n.noDeletedTasks, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : Colors.black12)),
    ]));
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete_outline, color: AppColors.error)),
        title: Text(task['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(l10n.deletedAgo(_getTimeAgo(context, task['date'])), style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) => value == 'restore' ? _restoreTask(task) : _deleteForever(task),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'restore', child: Row(children: [const Icon(Icons.restore, color: AppColors.success), const SizedBox(width: 12), Text(l10n.restore)])),
            PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_forever, color: AppColors.error), const SizedBox(width: 12), Text(l10n.deleteForever)])),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} ${l10n.daysAgo}';
    if (diff.inHours > 0) return '${diff.inHours} ${l10n.hoursAgo}';
    return l10n.justNow;
  }

  void _restoreTask(Map<String, dynamic> task) {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _deletedTasks.removeWhere((t) => t['id'] == task['id']));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.taskRestored), backgroundColor: AppColors.success));
  }

  void _deleteForever(Map<String, dynamic> task) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.deleteForever),
      content: Text(l10n.actionCannotBeUndone),
      actions: [
        // ✅ Confirm (Delete Forever) أول
        ElevatedButton(
          onPressed: () { setState(() => _deletedTasks.removeWhere((t) => t['id'] == task['id'])); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          child: Text(l10n.delete),
        ),
        // ✅ Cancel تاني
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
      ],
    ));
  }
}
