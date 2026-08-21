/// حالة الدعوة: بانتظار الرد / مقبولة / مرفوضة
enum InviteStatus { pending, accepted, declined }

class ProjectMemberEntity {
  final String id;

  final String? userId;

  final String email;

  final String? fullName;

  final String? avatarUrl;

  final InviteStatus status;
  final DateTime invitedAt;

  final DateTime? joinedAt;

  const ProjectMemberEntity({
    required this.id,
    this.userId,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.status,
    required this.invitedAt,
    this.joinedAt,
  });

  String get displayName => (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email;
}
