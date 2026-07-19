import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/bloc/theme/theme_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/workspace_entity.dart';
import '../bloc/workspace_bloc.dart';
import '../bloc/workspace_event.dart';
import '../bloc/workspace_state.dart';
import '../../../project/presentation/screens/projects_screen.dart';

class WorkspacesScreen extends StatelessWidget {
  const WorkspacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WorkspaceBloc>()..add(const WorkspacesLoadRequested()),
      child: const _WorkspacesView(),
    );
  }
}

class _WorkspacesView extends StatelessWidget {
  const _WorkspacesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // ربط صريح بـ ThemeBloc عشان نضمن إعادة بناء الشاشة كاملة
    // (بما فيها ListView وبطاقات الـ workspace) فوراً عند تغيير الثيم،
    // بدل ما نعتمد بس على انتشار InheritedWidget يلي مش موثوق دايماً
    // جوا IndexedStack.
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.workspacesTitle),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () => _showComingSoon(context, l10n)),
              IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showComingSoon(context, l10n)),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showComingSoon(context, l10n)),
            ],
          ),
          body: BlocConsumer<WorkspaceBloc, WorkspaceState>(
            listener: (context, state) {
              if (state is WorkspaceError) {
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
              if (state is WorkspaceLoading || state is WorkspaceInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              final workspaces = state is WorkspaceLoaded
                  ? state.workspaces
                  : state is WorkspaceError
                      ? state.workspaces
                      : <WorkspaceEntity>[];

              if (workspaces.isEmpty) {
                return _buildEmptyState(context, l10n, themeState.isDarkMode);
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: workspaces.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == workspaces.length) {
                    return _buildAddWorkspaceTile(context, l10n);
                  }
                  return _buildWorkspaceTile(context, l10n, workspaces[index], themeState.isDarkMode);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_outlined, size: 72, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              l10n.noWorkspaces,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noWorkspacesSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddWorkspaceDialog(context, l10n),
              icon: const Icon(Icons.add),
              label: Text(l10n.addWorkspace),
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

  Widget _buildWorkspaceTile(BuildContext context, AppLocalizations l10n, WorkspaceEntity workspace, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: IconButton(
          icon: const Icon(Icons.check_box_outline_blank, color: AppColors.error),
          tooltip: l10n.delete,
          onPressed: () => _confirmDeleteWorkspace(context, l10n, workspace),
        ),
        title: Text(
          workspace.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>ProjectsScreen(workspace: workspace)),
        ),
      ),
    );
  }

  Widget _buildAddWorkspaceTile(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showAddWorkspaceDialog(context, l10n),
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
            Text(l10n.addWorkspace, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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

  void _showAddWorkspaceDialog(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final bloc = context.read<WorkspaceBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.addWorkspace),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.workspaceNameLabel, hintText: l10n.workspaceNameHint),
            validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                bloc.add(WorkspaceCreateRequested(controller.text.trim()));
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWorkspace(BuildContext context, AppLocalizations l10n, WorkspaceEntity workspace) {
    final bloc = context.read<WorkspaceBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteWorkspaceTitle),
        content: Text('${l10n.deleteWorkspaceConfirm(workspace.name)}\n${l10n.actionCannotBeUndone}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              bloc.add(WorkspaceDeleteRequested(workspace.id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}