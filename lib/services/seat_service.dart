import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/seat_model.dart';

class SeatService {
  static const String baseUrl =
      "https://automatic-library-management.onrender.com";

  // =========================================================
  // GET ALL SEATS
  // =========================================================

  Future<List<Seat>> getAllSeats() async {
    final response = await http.get(Uri.parse('$baseUrl/seats'));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load seats: '
        '${response.statusCode} ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Invalid seats response');
    }

    return decoded.map<Seat>((json) {
      return Seat.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }
}
