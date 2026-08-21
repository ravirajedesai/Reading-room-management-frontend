import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/booking_model.dart';
import '../models/payment_model.dart';
import 'session_service.dart';

class BookingService {
  static const String baseUrl =
      'https://automatic-library-management-git-409107405882.asia-south1.run.app';

  // =========================================================
  // HEADERS
  // =========================================================

  static Future<Map<String, String>> _headers() async {
    final token = await SessionService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('User session expired. Please login again.');
    }

    final Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final libraryId = await SessionService.getActiveLibraryId();
    if (libraryId != null) {
      headers['X-Library-ID'] = libraryId.toString();
    }
    return headers;
  }

  // =========================================================
  // HOLD SEAT
  // =========================================================

  Future<Map<String, dynamic>> holdSeat(int seatId) async {
    final userId = await SessionService.getUserId();

    if (userId == null) {
      throw Exception('User session expired. Please login again.');
    }

    final headers = await _headers();
    headers['X-USER-ID'] = userId.toString();

    final response = await http
        .post(
          Uri.parse('$baseUrl/bookings/hold'),
          headers: headers,
          body: jsonEncode({'seatId': seatId}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.trim().isEmpty) {
        throw Exception('Server returned an empty booking response.');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(_extractError(response, 'Failed to hold seat'));
  }

  // =========================================================
  // GET MY BOOKING
  // =========================================================

  Future<Booking?> getMyBooking() async {
    final userId = await SessionService.getUserId();

    if (userId == null) {
      throw Exception('User session expired. Please login again.');
    }

    final headers = await _headers();
    headers['X-USER-ID'] = userId.toString();

    final response = await http
        .get(
          Uri.parse('$baseUrl/bookings/my-booking/$userId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty || response.body.trim() == 'null') {
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid booking response.');
      }

      return Booking.fromJson(decoded);
    }

    if (response.statusCode == 400 || response.statusCode == 404) {
      final body = response.body.toLowerCase();

      if (body.contains('no active or pending booking') ||
          body.contains('booking not found') ||
          body.contains('no booking')) {
        return null;
      }
    }

    throw Exception(_extractError(response, 'Failed to load booking'));
  }

  // =========================================================
  // PAYMENT NOTIFICATION
  // =========================================================

  Future<Payment?> getPaymentNotification() async {
    final booking = await getMyBooking();

    if (booking == null) {
      return null;
    }

    final approvalStatus = booking.approvalStatus;

    if (approvalStatus == PaymentApprovalStatus.approved ||
        approvalStatus == PaymentApprovalStatus.rejected) {
      return Payment(
        id: booking.paymentId,
        userId: booking.userId,
        bookingId: booking.id,
        amount: booking.amount,
        studentName: booking.studentName,
        seatNumber: booking.seatNumber?.toString(),
        status: booking.paymentStatus,
        paymentMethod: booking.paymentMethod,
        approvalStatus: booking.approvalStatus,
        paymentType: booking.paymentType,
        transactionId: booking.transactionId,
        paidAt: booking.paidAt,
      );
    }

    return null;
  }

  // =========================================================
  // CANCEL PENDING BOOKING (STUDENT SELF-CANCEL)
  // Matches Spring Boot: PUT /bookings/cancel/{bookingId}/{userId}
  // =========================================================

  Future<void> cancelPendingBooking({
    required int bookingId,
    int? userId,
  }) async {
    // 1. Resolve User ID
    final resolvedUserId = userId ?? await SessionService.getUserId();

    if (resolvedUserId == null) {
      throw Exception('User session expired. Please login again.');
    }

    final headers = await _headers();
    headers['X-USER-ID'] = resolvedUserId.toString();

    // 2. Calls PUT endpoint on backend
    final response = await http
        .put(
          Uri.parse('$baseUrl/bookings/cancel/$bookingId/$resolvedUserId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));

    print("CANCEL BOOKING STATUS: ${response.statusCode}");
    print("CANCEL BOOKING BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    throw Exception(_extractError(response, 'Failed to cancel booking'));
  }

  // =========================================================
  // ERROR EXTRACTION
  // =========================================================

  String _extractError(http.Response response, String defaultMessage) {
    try {
      if (response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          if (decoded['message'] != null) {
            return decoded['message'].toString();
          }

          if (decoded['error'] != null) {
            return decoded['error'].toString();
          }

          if (decoded['detail'] != null) {
            return decoded['detail'].toString();
          }
        }
      }
    } catch (_) {}

    return '$defaultMessage (${response.statusCode})';
  }
}

