import 'package:taskle_app/src/features/auth/models/user_model.dart';

class AuthModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
