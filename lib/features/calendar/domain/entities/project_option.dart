import 'package:equatable/equatable.dart';

/// مشروع (مع الورك سبيس التابع إلها) نعرضه بقائمة اختيار المشروع
/// بديالوج "إضافة تاسك" — منجمعها مسبقاً وقت تحميل تاسكات الكالندر
/// حتى ما نضطر نعيد نداء الـ API وقت ما المستخدم بس يفتح الديالوج.
class ProjectOption extends Equatable {
  final String projectId;
  final String projectName;
  final String workspaceId;
  final String workspaceName;

  const ProjectOption({
    required this.projectId,
    required this.projectName,
    required this.workspaceId,
    required this.workspaceName,
  });

  @override
  List<Object?> get props => [projectId, projectName, workspaceId, workspaceName];
}