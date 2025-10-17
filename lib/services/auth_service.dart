import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_config.dart';
import '../models/user_profile.dart';
// import '../data/role_map.dart'; // Không dùng mock nữa, lấy từ backend

class AuthService {
  UserProfile? _current;
  UserProfile? get currentUser => _current;

  /// Đăng nhập bằng API backend (sửa lại dùng API thật, không mock)
  Future<UserProfile> signIn({
  required String identifier,
  required String password,
}) async {
  final response = await http.post(
  Uri.parse('${AppConfig.apiBase}/users/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': identifier,
      'password': password,
    }),
  );
  print('LOGIN RESPONSE: ${response.statusCode} - ${response.body}'); // Thêm dòng này để debug

  if (response.statusCode == 200 || response.statusCode == 201) {
    final data = jsonDecode(response.body);
    _current = UserProfile(
      id: data['id'].toString(),
      name: data['name'] ?? '',
      role: data['role'] ?? 'patient',
      email: data['email'] ?? '',
      avatar: data['avatar'],
    );
    return _current!;
  } else {
    throw Exception(jsonDecode(response.body)['message'] ?? 'Đăng nhập thất bại');
  }
}


  /// Đăng ký tài khoản mới qua API backend
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    String role = 'patient',
  }) async {
    final response = await http.post(
  Uri.parse('${AppConfig.apiBase}/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserProfile(
        id: data['id'].toString(),
        name: data['name'] ?? '',
        role: data['role'] ?? 'patient',
        email: data['email'] ?? '',  
        avatar: data['avatar'],
      );
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Đăng ký thất bại');
    }
  }

  Future<void> changePassword({
  required String email,
  required String oldPassword,
  required String newPassword,
}) async {
  final response = await http.patch(
  Uri.parse('${AppConfig.apiBase}/users/change-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    }),
  );
  if (response.statusCode == 200) {
    // Thành công
    return;
  } else {
    throw Exception(jsonDecode(response.body)['message'] ?? 'Đổi mật khẩu thất bại');
  }
}

  /// Đăng xuất (FE)
  void signOut() => _current = null;
}
