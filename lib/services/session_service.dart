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

  // =========================================================
  // ACTIVE LIBRARY DETAILS
  // =========================================================

  static Future<void> saveActiveLibrary({
    required int id,
    required String name,
    String? address,
    String? phone,
    String? code,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeLibraryId', id);
    await prefs.setString('activeLibraryName', name);
    if (address != null) await prefs.setString('activeLibraryAddress', address);
    if (phone != null) await prefs.setString('activeLibraryPhone', phone);
    if (code != null) await prefs.setString('activeLibraryCode', code);
  }

  static Future<void> saveActiveLibraryId(int libraryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeLibraryId', libraryId);
  }

  static Future<int?> getActiveLibraryId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('activeLibraryId');
  }

  static Future<String?> getActiveLibraryName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeLibraryName');
  }

  static Future<String?> getActiveLibraryAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeLibraryAddress');
  }

  static Future<String?> getActiveLibraryPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeLibraryPhone');
  }

  static Future<void> clearActiveLibraryId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeLibraryId');
    await prefs.remove('activeLibraryName');
    await prefs.remove('activeLibraryAddress');
    await prefs.remove('activeLibraryPhone');
    await prefs.remove('activeLibraryCode');
  }
}
