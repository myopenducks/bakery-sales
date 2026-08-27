import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

class UserModel {
  final String id;
  final String username;
  final DateTime? createdAt;

  UserModel({required this.id, required this.username, this.createdAt});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<String> login(String username, String password) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'username': username, 'password': password},
    );
    final token = response.data['token'] as String;
    await TokenStorage.saveToken(token);
    return token;
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      if (response.data['user'] != null) {
        return UserModel.fromJson(response.data['user']);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _dio.post(
      ApiEndpoints.changePassword,
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() async {
    await TokenStorage.clearToken();
  }
}
