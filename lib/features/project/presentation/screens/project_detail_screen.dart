import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/project_entity.dart';

/// شاشة مبدئية بس — لعرض قائمة الـ Tasks جوا الـ Project.
/// TODO: بناء فيتشر Tasks كامل هون (data source, repository, bloc, UI)
/// بنفس النمط يلي اتبنى فيه Workspace وProject.
class ProjectDetailScreen extends StatelessWidget {
  final ProjectEntity project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(project.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_outlined, size: 72, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              l10n.comingSoon,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}