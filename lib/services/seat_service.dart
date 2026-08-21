import 'session_service.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/seat_model.dart';

class SeatService {
  static const String baseUrl =
      "https://automatic-library-management-git-409107405882.asia-south1.run.app";

  // =========================================================
  // GET TOKEN
  // =========================================================

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  // =========================================================
  // GET USER ID
  // =========================================================

  static Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final dynamic value = prefs.get('userId');

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  // =========================================================
  // COMMON HEADERS
  // =========================================================

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    final userId = await _getUserId();

    if (token == null || token.isEmpty) {
      throw Exception('User session expired. Please login again.');
    }
    if (userId == null) {
      throw Exception('User ID not found. Please login again.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'X-USER-ID': userId.toString(),
    };
    
    final libraryId = await SessionService.getActiveLibraryId();
    if (libraryId != null) {
      headers['X-Library-ID'] = libraryId.toString();
    }
    return headers;
  }

  // =========================================================
  // GET ALL SEATS
  //
  // GET /seats
  //
  // X-USER-ID: 39
  //
  // Backend response:
  //
  // {
  //   "id": 100,
  //   "seatNumber": 100,
  //   "status": "PENDING",
  //   "pending": true,
  //   "pendingByCurrentUser": true
  // }
  //
  // =========================================================

  Future<List<Seat>> getAllSeats() async {
    final userId = await _getUserId();

    if (userId == null) {
      throw Exception('User ID not found. Please login again.');
    }

    final headers = await _headers();

    print('========================================');
    print('GET ALL SEATS');
    print('USER ID: $userId');
    print('X-USER-ID HEADER: ${headers['X-USER-ID']}');
    print('========================================');

    // =======================================================
    // IMPORTANT
    //
    // DO NOT send:
    //
    // /seats?userId=39
    //
    // Backend expects:
    //
    // X-USER-ID: 39
    // =======================================================

    final response = await http
        .get(Uri.parse('$baseUrl/seats'), headers: headers)
        .timeout(const Duration(seconds: 30));

    print('========================================');
    print('GET ALL SEATS STATUS: ${response.statusCode}');
    print('GET ALL SEATS BODY: ${response.body}');
    print('========================================');

    // =======================================================
    // STATUS CHECK
    // =======================================================

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load seats: '
        '${response.statusCode} ${response.body}',
      );
    }

    // =======================================================
    // JSON
    // =======================================================

    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw Exception('Invalid JSON received from seats API.');
    }

    // =======================================================
    // LIST CHECK
    // =======================================================

    if (decoded is! List) {
      throw Exception('Invalid seats response from server.');
    }

    // =======================================================
    // PARSE SEATS
    // =======================================================

    final List<Seat> result = [];

    for (final item in decoded) {
      if (item is Map) {
        final seat = Seat.fromJson(Map<String, dynamic>.from(item));

        result.add(seat);
      }
    }

    // =======================================================
    // DEBUG SEAT STATUS
    // =======================================================

    for (final seat in result) {
      if (seat.isPending) {
        print(
          'SEAT ${seat.seatNumber}: '
          'PENDING | '
          'MY PENDING: ${seat.pendingByCurrentUser} | '
          'SELECTABLE: ${seat.isSelectable}',
        );
      }
    }

    return result;
  }

  // =========================================================
  // GET SEAT STATS
  // =========================================================

  Future<Map<String, dynamic>> getSeatStats() async {
    final headers = await _headers();

    final response = await http
        .get(Uri.parse('$baseUrl/seats/stats'), headers: headers)
        .timeout(const Duration(seconds: 30));

    print('========================================');
    print('SEAT STATS STATUS: ${response.statusCode}');
    print('SEAT STATS BODY: ${response.body}');
    print('========================================');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load seat stats: '
        '${response.statusCode} ${response.body}',
      );
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw Exception('Invalid JSON received from seat stats API.');
    }

    if (decoded is! Map) {
      throw Exception('Invalid seat stats response.');
    }

    return Map<String, dynamic>.from(decoded);
  }
}


