import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../task/presentation/bloc/task_bloc.dart';
import '../../../task/presentation/bloc/task_event.dart';
import '../../../task/presentation/bloc/task_state.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/entities/task_progress_summary.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/project_member_entity.dart';
import '../bloc/project_members_bloc.dart';
import '../bloc/project_members_event.dart';
import '../bloc/project_members_state.dart';

class ProjectPropertiesScreen extends StatelessWidget {
  final ProjectEntity project;
  const ProjectPropertiesScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<TaskBloc>()..add(TasksLoadRequested(project.id)),
        ),
        BlocProvider(
          create: (_) => getIt<ProjectMembersBloc>()..add(ProjectMembersLoadRequested(project.id)),
        ),
      ],
      child: _ProjectPropertiesView(project: project),
    );
  }
}

class _ProjectPropertiesView extends StatelessWidget {
  final ProjectEntity project;
  const _ProjectPropertiesView({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.projectProperties)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            project.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 20),
          _buildDescriptionSection(context, l10n, isDark),
          const SizedBox(height: 24),
          _buildProgressSection(context, l10n, isDark),
          const SizedBox(height: 24),
          _buildMembersSection(context, l10n, isDark),
        ],
      ),
    );
  }


  Widget _buildDescriptionSection(BuildContext context, AppLocalizations l10n, bool isDark) {
    final hasDescription = project.description != null && project.description!.trim().isNotEmpty;

    return _SectionCard(
      isDark: isDark,
      title: l10n.projectDescriptionLabel,
      child: Text(
        hasDescription ? project.description! : l10n.noDescriptionAdded,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          fontStyle: hasDescription ? FontStyle.normal : FontStyle.italic,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, AppLocalizations l10n, bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: l10n.progressLabel,
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading || state is TaskInitial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final tasks = state is TaskLoaded
              ? state.tasks
              : state is TaskError
                  ? state.tasks
                  : const <TaskEntity>[];

          final summary = TaskProgressSummary.fromTasks(tasks);

          if (summary.total == 0) {
            return Text(
              l10n.noTasksYet,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SegmentedProgressBar(summary: summary),
              const SizedBox(height: 12),
              Text(
                '${(summary.completedRatio * 100).round()}%  •  ${l10n.tasksCountLabel(summary.total)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatusChip(color: AppColors.textSecondaryLight, label: l10n.notStartedLabel, count: summary.notStarted),
                  _StatusChip(color: AppColors.warning, label: l10n.pendingLabel, count: summary.pending),
                  _StatusChip(color: AppColors.info, label: l10n.inProgressLabel, count: summary.inProgress),
                  _StatusChip(color: AppColors.success, label: l10n.completedLabel, count: summary.completed),
                  if (summary.overdue > 0)
                    _StatusChip(color: AppColors.error, label: l10n.overdueLabel, count: summary.overdue),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, AppLocalizations l10n, bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: l10n.membersLabel,
      child: BlocBuilder<ProjectMembersBloc, ProjectMembersState>(
        builder: (context, state) {
          if (state is ProjectMembersLoading || state is ProjectMembersInitial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ProjectMembersError) {
            return Text(
              state.message,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            );
          }

          final members = (state as ProjectMembersLoaded).members;

          if (members.isEmpty) {
            return Text(
              l10n.noMembersYet,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            );
          }

          return Column(
            children: members
                .map((member) => _MemberTile(member: member, l10n: l10n, isDark: isDark))
                .toList(),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const _SectionCard({required this.isDark, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  final TaskProgressSummary summary;
  const _SegmentedProgressBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final remaining = summary.total - summary.completed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (summary.completed > 0)
              Expanded(flex: summary.completed, child: Container(color: AppColors.success)),
            if (remaining > 0)
              Expanded(flex: remaining, child: Container(color: AppColors.borderLight)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _StatusChip({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label · $count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ProjectMemberEntity member;
  final AppLocalizations l10n;
  final bool isDark;

  const _MemberTile({required this.member, required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPending = member.status == InviteStatus.pending;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
            child: member.avatarUrl == null
                ? Text(
                    member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                if (member.fullName != null && member.fullName!.trim().isNotEmpty)
                  Text(
                    member.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
          if (isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.pendingInviteLabel,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
              ),
            ),
        ],
      ),
    );
  }
}
