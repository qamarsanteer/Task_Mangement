import 'project_member_role.dart';

/// حالة الدعوة: بانتظار الرد / مقبولة / مرفوضة
enum InviteStatus { pending, accepted, declined }

class ProjectMemberEntity {
  /// id سجل العضوية نفسه (مش userId بالضرورة)
  final String id;

  /// null لحد ما تُقبل الدعوة ويرتبط السجل بحساب مستخدم فعلي
  final String? userId;

  /// معروف من لحظة إرسال الدعوة
  final String email;

  /// null لحد ما يصير عند الشخص حساب (الباك اند هو يلي بيعبّيها)
  final String? fullName;

  /// null لحد ما يصير عند الشخص حساب
  final String? avatarUrl;

  final ProjectMemberRole role;
  final InviteStatus status;
  final DateTime invitedAt;

  /// null لحد ما يقبل الدعوة فعليًا
  final DateTime? joinedAt;

  const ProjectMemberEntity({
    required this.id,
    this.userId,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.invitedAt,
    this.joinedAt,
  });

  /// الاسم المعروض: الاسم الكامل إذا موجود، وإلا الإيميل كبديل
  String get displayName => (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email;
}
