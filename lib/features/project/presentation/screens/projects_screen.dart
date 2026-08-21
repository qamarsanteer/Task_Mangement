import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/events/task_changes_bus.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../workspace/domain/entities/workspace_entity.dart';
import '../../domain/entities/project_entity.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import '../../../task/presentation/screens/tasks_screen.dart';
import '../bloc/project_invite_bloc.dart';
import '../bloc/project_invite_event.dart';
import '../bloc/project_invite_state.dart';
import 'project_properties_screen.dart';

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

class _ProjectsView extends StatefulWidget {
  final WorkspaceEntity workspace;
  const _ProjectsView({required this.workspace});

  @override
  State<_ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<_ProjectsView> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  StreamSubscription<String>? _projectChangesSub;
  @override
  void initState() {
    super.initState();
    _projectChangesSub = getIt<TaskChangesBus>().onProjectChanged.listen((_) {
      if (mounted) {
        context.read<ProjectBloc>().add(ProjectsLoadRequested(widget.workspace.id));
      }
    });
  }

  @override
  void dispose() {
    _projectChangesSub?.cancel(); 
    super.dispose();
  }
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _activateSelection(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  void _selectAll(List<ProjectEntity> items) {
    setState(() {
      _selectedIds.addAll(items.map((e) => e.id));
    });
  }

  void _confirmDeleteSelected(BuildContext context, AppLocalizations l10n) {
    final bloc = context.read<ProjectBloc>();
    final count = _selectedIds.length;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteProjectTitle),
        content: Text('Are you sure you want to delete $count project(s)?\n${l10n.actionCannotBeUndone}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              bloc.add(ProjectsDeleteRequested(
                _selectedIds.toList(),
                workspaceId: widget.workspace.id,
                workspaceName: widget.workspace.name,
              ));
              Navigator.pop(dialogContext);
              _clearSelection();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
        ],
      ),
    );
  }

  void _showProjectActionsSheet(BuildContext context, AppLocalizations l10n) {
    final isSingle = _selectedIds.length == 1;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              if (isSingle)
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1),
                  title: Text(l10n.inviteMember),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    final projectId = _selectedIds.first;
                    _showInviteMemberDialog(context, l10n, projectId);
                  },
                ),
              if (isSingle)
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.projectProperties),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    final projectId = _selectedIds.first;
                    _openProjectProperties(context, projectId);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(
                  l10n.delete,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteSelected(context, l10n);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInviteMemberDialog(BuildContext context, AppLocalizations l10n, String projectId) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => getIt<ProjectInviteBloc>(),
        child: BlocConsumer<ProjectInviteBloc, ProjectInviteState>(
                    listener: (context, state) {
            if (state is ProjectInviteSuccess) {
              Navigator.pop(dialogContext);
              _clearSelection();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(l10n.inviteSentMessage(state.email)),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            } else if (state is ProjectInviteFailure) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
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
            final isLoading = state is ProjectInviteLoading;

            return StatefulBuilder(
              builder: (dialogContext, setDialogState) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(l10n.inviteMember),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextField(
                        controller: controller,
                        label: l10n.email,
                        hint: l10n.email,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.requiredField;
                          }
                          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return l10n.invalidEmail;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (formKey.currentState!.validate()) {
                              context.read<ProjectInviteBloc>().add(
                                    ProjectInviteMemberRequested(
                                      projectId: projectId,
                                      email: controller.text.trim(),
                                    ),
                                  );
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.send),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                TextButton(
                  onPressed: () {
                    final state = context.read<ProjectBloc>().state;
                    final items = state is ProjectLoaded
                        ? state.projects
                        : state is ProjectError
                            ? state.projects
                            : <ProjectEntity>[];
                    _selectAll(items);
                  },
                  child: const Text('Select All', style: TextStyle(color: Colors.white)),
                ),
                 if (_selectedIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showProjectActionsSheet(context, l10n),
                  ),
              ],
            )
          : AppBar(
              title: Text(widget.workspace.name),
              actions: [
                IconButton(icon: const Icon(Icons.search), onPressed: () => _showComingSoon(context, l10n)),
                IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showComingSoon(context, l10n)),
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
                  : [];

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
    final isSelected = _selectedIds.contains(project.id);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.15)
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(project.id),
                activeColor: AppColors.primary,
              )
            : IconButton(
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
        trailing: _isSelectionMode
            ? null
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(project.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TasksScreen(project: project, workspaceName: widget.workspace.name),
              ),
            );
          }
        },
        onLongPress: () => _activateSelection(project.id),
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

  void _openProjectProperties(BuildContext context, String projectId) {
    final state = context.read<ProjectBloc>().state;
    final projects = state is ProjectLoaded
        ? state.projects
        : state is ProjectError
            ? state.projects
            : <ProjectEntity>[];

    ProjectEntity? foundProject;
    for (final p in projects) {
      if (p.id == projectId) {
        foundProject = p;
        break;
      }
    }
    if (foundProject == null) return;
    final ProjectEntity project = foundProject;

    _clearSelection();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectPropertiesScreen(project: project)),
    );
  }

  void _showAddProjectDialog(BuildContext context, AppLocalizations l10n) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final bloc = context.read<ProjectBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.addProject),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: l10n.projectNameLabel,
                hint: l10n.projectNameHint,
                autofocus: true,
                validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: descriptionController,
                label: l10n.projectDescriptionLabel,
                hint: l10n.projectDescriptionHint,
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final description = descriptionController.text.trim();
                bloc.add(
                  ProjectCreateRequested(
                    workspaceId: widget.workspace.id,
                    name: nameController.text.trim(),
                    description: description.isEmpty ? null : description,
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(l10n.create),
          ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
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
          ElevatedButton(
            onPressed: () {
              // ═══ عدّل هون ═══
              bloc.add(ProjectDeleteRequested(
                project.id,
                workspaceId: widget.workspace.id,
                workspaceName: widget.workspace.name,
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
}