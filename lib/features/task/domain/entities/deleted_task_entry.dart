import 'task_entity.dart';

/// لقطة (Snapshot) لتاسك انحذف ونقل لسلة المحذوفات — بتحتفظ ببيانات
/// التاسك الكاملة + اسم المشروع والـ workspace اللي كان فيهم لحظة الحذف.
/// منخزّن الأسماء كـ snapshot (مش نجيبهم بالـ id وقت العرض) حتى تضل
/// واضحة حتى لو انحذف المشروع أو الـ workspace نفسه بعدين.
class DeletedTaskEntry {
  /// عدد الأيام المسموحة قبل الحذف النهائي التلقائي من السلة.
  static const int retentionDays = 30;

  final TaskEntity task;
  final String projectName;
  final String workspaceId;
  final String workspaceName;
  final DateTime deletedAt;

  const DeletedTaskEntry({
    required this.task,
    required this.projectName,
    required this.workspaceId,
    required this.workspaceName,
    required this.deletedAt,
  });

  String get taskId => task.id;

  /// عدد الأيام المتبقية قبل الحذف النهائي التلقائي (صفر كحد أدنى).
  int get daysRemaining {
    final elapsed = DateTime.now().difference(deletedAt).inDays;
    final remaining = retentionDays - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

  /// عدّت مدة الاحتفاظ (30 يوم) ولازم تنحذف نهائياً تلقائياً.
  bool get isExpired =>
      DateTime.now().difference(deletedAt).inDays >= retentionDays;
}