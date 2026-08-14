import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl =
      "https://automatic-library-management.onrender.com/users";

  // ================= REGISTER =================

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

  // ================= LOGIN =================

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
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      "Login failed: "
      "${response.statusCode} ${response.body}",
    );
  }
}
