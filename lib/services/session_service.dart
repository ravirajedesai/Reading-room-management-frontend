import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // =========================================================
  // SAVE LOGIN
  // =========================================================

  static Future<void> saveLogin({
    required int userId,
    required String name,
    required String mobile,
    required String role,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);

    await prefs.setInt('userId', userId);

    await prefs.setString('name', name);

    await prefs.setString('mobile', mobile);

    await prefs.setString('role', role.toUpperCase());

    await prefs.setString('token', token);
  }

  // =========================================================
  // CHECK LOGIN
  // =========================================================

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('isLoggedIn') ?? false;
  }

  // =========================================================
  // USER ID
  // =========================================================

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt('userId');
  }

  // =========================================================
  // NAME
  // =========================================================

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('name');
  }

  // =========================================================
  // MOBILE
  // =========================================================

  static Future<String?> getMobile() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('mobile');
  }

  // =========================================================
  // ROLE
  // =========================================================

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString('role');

    return role?.toUpperCase();
  }

  // =========================================================
  // TOKEN
  // =========================================================

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}

