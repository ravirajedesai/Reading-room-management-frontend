import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seat_model.dart';

class SeatService {
  static const String baseUrl =
      "https://automatic-library-management.onrender.com";

  // =========================================================
  // GET TOKEN
  // =========================================================

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // =========================================================
  // GET ALL SEATS (kept for seat booking page)
  // =========================================================

  Future<List<Seat>> getAllSeats() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/seats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load seats: ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) throw Exception('Invalid seats response');

    return decoded.map<Seat>((json) {
      return Seat.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  // =========================================================
  // GET SEAT STATS (used by dashboard — fast, 3 counts only)
  // =========================================================

  Future<Map<String, dynamic>> getSeatStats() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/seats/stats'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    print('SEAT STATS STATUS: ${response.statusCode}');
    print('SEAT STATS BODY: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to load seat stats: ${response.statusCode} ${response.body}',
    );
  }
}
