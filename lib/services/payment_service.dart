import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/payment_model.dart';
import '../services/session_service.dart';

class PaymentService {
  static const String baseUrl =
      'https://automatic-library-management.onrender.com';

  // =========================================================
  // GET USER ID (internal helper)
  // =========================================================

  Future<int> _getUserId() async {
    final userId = await SessionService.getUserId();
    if (userId == null) {
      throw Exception('Session expired. Please log in again.');
    }
    return userId;
  }

  // =========================================================
  // SHARED HEADERS (internal helper)
  // =========================================================

  Future<Map<String, String>> _headers() async {
    final userId = await _getUserId();
    final token = await SessionService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-USER-ID': userId.toString(),
    };
  }

  // =========================================================
  // CREATE PAYMENT / RAZORPAY ORDER
  // =========================================================

  Future<Payment> createPayment({
    required int userId,
    required int bookingId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/payments/create');
      final headers = await _headers();

      print('========================================');
      print('CREATE PAYMENT REQUEST');
      print('URL: $uri');
      print('USER ID: $userId');
      print('BOOKING ID: $bookingId');
      print('HEADERS: $headers');
      print('========================================');

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({'bookingId': bookingId}),
          )
          .timeout(const Duration(seconds: 30));

      print('CREATE PAYMENT STATUS: ${response.statusCode}');
      print('CREATE PAYMENT RESPONSE: ${response.body}');
      print('CREATE PAYMENT HEADERS: ${response.headers}');

      return _handleResponse(response);
    } catch (e) {
      print('CREATE PAYMENT ERROR: $e');
      rethrow;
    }
  }

  // =========================================================
  // VERIFY RAZORPAY PAYMENT
  // =========================================================

  Future<Payment> verifyPayment({
    required int userId,
    required int bookingId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/payments/verify');
      final headers = await _headers();

      print('========================================');
      print('VERIFY PAYMENT REQUEST');
      print('URL: $uri');
      print('USER ID: $userId');
      print('BOOKING ID: $bookingId');
      print('RAZORPAY PAYMENT ID: $razorpayPaymentId');
      print('RAZORPAY ORDER ID: $razorpayOrderId');
      print('========================================');

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'bookingId': bookingId,
              'razorpayPaymentId': razorpayPaymentId,
              'razorpayOrderId': razorpayOrderId,
              'razorpaySignature': razorpaySignature,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('VERIFY PAYMENT STATUS: ${response.statusCode}');
      print('VERIFY PAYMENT RESPONSE: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('VERIFY PAYMENT ERROR: $e');
      rethrow;
    }
  }

  // =========================================================
  // HANDLE RESPONSE (internal helper)
  // =========================================================

  Payment _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) {
          throw Exception('Empty response received from payment server.');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw Exception('Invalid response format from payment server.');
        }
        return Payment.fromJson(decoded);

      case 400:
        throw Exception('Bad request: ${_extractErrorMessage(response.body)}');

      case 401:
        throw Exception('Session expired. Please log in again.');

      case 403:
        // Backend is blocking the request.
        // Fix: permit /payments/** in Spring Security for X-USER-ID header.
        final detail = response.body.isNotEmpty
            ? _extractErrorMessage(response.body)
            : 'Access denied. Check backend security configuration.';
        throw Exception('403 Forbidden: $detail');

      case 404:
        throw Exception('Booking not found. Please try again.');

      case 409:
        throw Exception('Payment already exists for this booking.');

      case 500:
        throw Exception('Server error. Please try again later.');

      default:
        throw Exception(
          'Unexpected error (${response.statusCode}): '
          '${_extractErrorMessage(response.body)}',
        );
    }
  }

  // =========================================================
  // EXTRACT ERROR MESSAGE (internal helper)
  // =========================================================

  String _extractErrorMessage(String responseBody) {
    if (responseBody.isEmpty) {
      return 'No error details received from server.';
    }

    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map) {
        // Spring Boot standard error fields
        if (decoded['message'] != null) return decoded['message'].toString();
        if (decoded['error'] != null) return decoded['error'].toString();
        if (decoded['detail'] != null) return decoded['detail'].toString();
      }

      if (decoded is String) return decoded;
    } catch (_) {
      // Not JSON — return raw body
    }

    return responseBody.replaceAll('"', '');
  }
}
