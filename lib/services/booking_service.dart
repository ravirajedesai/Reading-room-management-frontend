import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/booking_model.dart';
import 'session_service.dart';

class BookingException implements Exception {
  final String message;
  final int? statusCode;

  BookingException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class BookingService {
  static const String baseUrl =
      "https://automatic-library-management.onrender.com";

  // ============================================================
  // HOLD SEAT
  // ============================================================

  Future<Booking> holdSeat({required int userId, required int seatId}) async {
    // Get JWT saved during login
    final String? token = await SessionService.getToken();

    print("======================================");
    print("HOLD SEAT");
    print("USER ID: $userId");
    print("SEAT ID: $seatId");
    print(
      "JWT: ${token != null && token.isNotEmpty ? 'AVAILABLE' : 'MISSING'}",
    );
    print("======================================");

    if (token == null || token.isEmpty) {
      throw BookingException(
        message: "Login session expired. Please login again.",
      );
    }

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/hold'),

      headers: {
        'Content-Type': 'application/json',

        // JWT authentication
        'Authorization': 'Bearer $token',

        // Keep this if your backend still uses it
        'X-USER-ID': userId.toString(),
      },

      body: jsonEncode({'seatId': seatId}),
    );

    print("HOLD SEAT STATUS: ${response.statusCode}");
    print("HOLD SEAT RESPONSE: ${response.body}");

    // ============================================================
    // SUCCESS
    // ============================================================

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = jsonDecode(response.body);

        return Booking.fromJson(data);
      } catch (e) {
        throw BookingException(
          message: "Invalid booking response from server.",
          statusCode: response.statusCode,
        );
      }
    }

    // ============================================================
    // ERROR MESSAGE
    // ============================================================

    String message = "Unable to create booking";

    try {
      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          if (data['message'] != null &&
              data['message'].toString().trim().isNotEmpty) {
            message = data['message'].toString();
          } else if (data['error'] != null &&
              data['error'].toString().trim().isNotEmpty) {
            message = data['error'].toString();
          } else if (data['detail'] != null &&
              data['detail'].toString().trim().isNotEmpty) {
            message = data['detail'].toString();
          }
        } else {
          message = response.body;
        }
      }
    } catch (e) {
      if (response.body.isNotEmpty) {
        message = response.body;
      }
    }

    // ============================================================
    // 401 / 403
    // ============================================================

    if (response.statusCode == 401) {
      throw BookingException(
        message: "Unauthorized. Please login again.",
        statusCode: 401,
      );
    }

    if (response.statusCode == 403) {
      throw BookingException(
        message: "Access denied. Your login session may be invalid.",
        statusCode: 403,
      );
    }

    throw BookingException(message: message, statusCode: response.statusCode);
  }
}
