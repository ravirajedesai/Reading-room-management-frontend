import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String serverUrl =
      "https://automatic-library-management.onrender.com";

  static const String baseUrl = "$serverUrl/users";

  // ==========================================================
  // REGISTER
  // ==========================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String mobile,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "mobile": mobile, "password": password}),
    );

    print("REGISTER STATUS: ${response.statusCode}");
    print("REGISTER RESPONSE: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      "Registration failed: "
      "${response.statusCode} ${response.body}",
    );
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  static Future<Map<String, dynamic>> login({
    required String mobile,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile": mobile, "password": password}),
    );

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN RESPONSE BODY: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      print("LOGIN DATA: $data");

      // ======================================================
      // CHECK ROLE
      // ======================================================

      if (data['role'] == null) {
        throw Exception("Login response does not contain user role");
      }

      // ======================================================
      // CHECK JWT
      // ======================================================

      if (data['token'] == null || data['token'].toString().isEmpty) {
        throw Exception("Login response does not contain JWT token");
      }

      return data;
    }

    throw Exception(
      "Login failed: "
      "${response.statusCode} ${response.body}",
    );
  }

  // ==========================================================
  // SAVE FCM TOKEN
  // ==========================================================

  static Future<void> saveFcmToken({
    required int userId,
    required String token,
  }) async {
    print("======================================");
    print("SAVING FCM TOKEN");
    print("USER ID: $userId");
    print("FCM TOKEN: $token");

    final uri = Uri.parse(
      "$baseUrl/$userId/fcm-token",
    ).replace(queryParameters: {"fcmToken": token});

    print("FCM TOKEN URL: $uri");

    final response = await http.put(uri);

    print("FCM TOKEN SAVE STATUS: ${response.statusCode}");
    print("FCM TOKEN SAVE RESPONSE: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to save FCM token: "
        "${response.statusCode} ${response.body}",
      );
    }

    print("FCM TOKEN SAVED SUCCESSFULLY");
  }
}
