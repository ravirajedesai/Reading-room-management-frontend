import 'dart:convert';
import 'package:http/http.dart' as http;

class OwnerService {
  static const String baseUrl =
      "https://automatic-library-management.onrender.com";

  // =========================================================
  // COMMON HEADERS
  // =========================================================

  static Map<String, String> _headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // =========================================================
  // GET ALL USERS
  // =========================================================

  static Future<List<dynamic>> getAllUsers(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/owner/users"),
      headers: _headers(token),
    );

    print("GET USERS STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception(
      "Failed to get users: ${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // GET ALL BOOKINGS
  // =========================================================

  static Future<List<dynamic>> getAllBookings(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/owner/bookings"),
      headers: _headers(token),
    );

    print("GET BOOKINGS STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception(
      "Failed to get bookings: ${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // GET ALL PAYMENTS
  // =========================================================

  static Future<List<dynamic>> getAllPayments(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/owner/payments"),
      headers: _headers(token),
    );

    print("GET PAYMENTS STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception(
      "Failed to get payments: ${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // GET PAID USERS
  // =========================================================

  static Future<List<dynamic>> getPaidUsers(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/owner/users/paid"),
      headers: _headers(token),
    );

    print("GET PAID USERS STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception(
      "Failed to get paid users: ${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // USER PAYMENT HISTORY BY MOBILE
  // =========================================================

  static Future<List<dynamic>> getUserPaymentHistory(
    String token,
    String mobile,
  ) async {
    final uri = Uri.parse(
      "$baseUrl/owner/users/history",
    ).replace(queryParameters: {"mobile": mobile});

    final response = await http.get(uri, headers: _headers(token));

    print("PAYMENT HISTORY STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception(
      "Failed to get payment history: "
      "${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // DASHBOARD STATS
  // =========================================================

  static Future<Map<String, dynamic>> getDashboardStats(String token) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/owner/dashboard-stats"),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 10));

    print("DASHBOARD STATS STATUS: ${response.statusCode}");
    print("DASHBOARD STATS BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      "Failed to get dashboard stats: ${response.statusCode} ${response.body}",
    );
  }
}
