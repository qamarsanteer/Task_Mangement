class UserEntity {
  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;
  final String token;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
    required this.token,
  });

  UserEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? photoUrl,
    String? token,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      token: token ?? this.token,
    );
  }
}