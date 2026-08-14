import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/booking_model.dart';

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

  Future<Booking> holdSeat({required int userId, required int seatId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/hold'),
      headers: {
        'Content-Type': 'application/json',
        'X-USER-ID': userId.toString(),
      },
      body: jsonEncode({'seatId': seatId}),
    );

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
    // ERROR
    // ============================================================

    String message = "Unable to create booking";

    try {
      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          // First priority: backend "message"
          if (data['message'] != null &&
              data['message'].toString().trim().isNotEmpty) {
            message = data['message'].toString();
          }
          // Fallback
          else if (data['error'] != null &&
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
      // If response is not JSON
      if (response.body.isNotEmpty) {
        message = response.body;
      }
    }

    // ============================================================
    // SPECIFIC ERROR HANDLING
    // ============================================================

    if (response.statusCode == 409) {
      throw BookingException(message: message, statusCode: response.statusCode);
    }

    if (response.statusCode == 400) {
      throw BookingException(message: message, statusCode: response.statusCode);
    }

    if (response.statusCode == 404) {
      throw BookingException(message: message, statusCode: response.statusCode);
    }

    // ============================================================
    // GENERAL ERROR
    // ============================================================

    throw BookingException(message: message, statusCode: response.statusCode);
  }
}
