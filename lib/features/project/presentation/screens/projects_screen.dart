import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../workspace/domain/entities/workspace_entity.dart';
import '../../domain/entities/project_entity.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatelessWidget {
  final WorkspaceEntity workspace;
  const ProjectsScreen({super.key, required this.workspace});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProjectBloc>()..add(ProjectsLoadRequested(workspace.id)),
      child: _ProjectsView(workspace: workspace),
    );
  }
}

class _ProjectsView extends StatelessWidget {
  final WorkspaceEntity workspace;
  const _ProjectsView({required this.workspace});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(workspace.name),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showComingSoon(context, l10n)),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showComingSoon(context, l10n)),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showComingSoon(context, l10n)),
        ],
      ),
      body: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ProjectError) {
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
          if (state is ProjectLoading || state is ProjectInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final projects = state is ProjectLoaded
              ? state.projects
              : state is ProjectError
                  ? state.projects
                  : <ProjectEntity>[];

          if (projects.isEmpty) {
            return _buildEmptyState(context, l10n);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == projects.length) {
                return _buildAddProjectTile(context, l10n);
              }
              return _buildProjectTile(context, l10n, projects[index]);
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
            Icon(Icons.folder_outlined, size: 72, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              l10n.noProjects,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noProjectsSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddProjectDialog(context, l10n),
              icon: const Icon(Icons.add),
              label: Text(l10n.addProject),
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

  Widget _buildProjectTile(BuildContext context, AppLocalizations l10n, ProjectEntity project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          onPressed: () => _confirmDeleteProject(context, l10n, project),
        ),
        title: Text(
          project.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
        ),
      ),
    );
  }

  Widget _buildAddProjectTile(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showAddProjectDialog(context, l10n),
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
            Text(l10n.addProject, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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

  void _showAddProjectDialog(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final bloc = context.read<ProjectBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.addProject),
        content: Form(
          key: formKey,
          child: CustomTextField(
            controller: controller,
            label: l10n.projectNameLabel,
            hint: l10n.projectNameHint,
            autofocus: true,
            validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                bloc.add(ProjectCreateRequested(workspaceId: workspace.id, name: controller.text.trim()));
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

  void _confirmDeleteProject(BuildContext context, AppLocalizations l10n, ProjectEntity project) {
    final bloc = context.read<ProjectBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteProjectTitle),
        content: Text('${l10n.deleteProjectConfirm(project.name)}\n${l10n.actionCannotBeUndone}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              bloc.add(ProjectDeleteRequested(project.id));
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