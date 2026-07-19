import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.photoUrl,
    required super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photo_url'] ?? json['avatar'],
      token: json['token'] ?? json['access_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'photo_url': photoUrl,
      'token': token,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? photoUrl,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      token: token ?? this.token,
    );
  }
}
