import 'session_service.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment_model.dart';

class PaymentService {
  static const String baseUrl =
      'https://automatic-library-management-git-409107405882.asia-south1.run.app';

  // =========================================================
  // TOKEN
  // =========================================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // =========================================================
  // USER ID
  // =========================================================

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  // =========================================================
  // HEADERS
  // =========================================================

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    final userId = await _getUserId();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing. Please login again.');
    }

    if (userId == null) {
      throw Exception('User ID is missing. Please login again.');
    }

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-USER-ID': userId.toString(),
    };
    final libraryId = await SessionService.getActiveLibraryId();
    if (libraryId != null) {
      headers['X-Library-ID'] = libraryId.toString();
    }
    return headers;
  }

  // =========================================================
  // RAZORPAY KEY
  // =========================================================

  Future<String> getRazorpayKey() async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/payments/razorpay-key'),
      headers: headers,
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Unable to load payment configuration.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded['keyId'] != null) {
        return decoded['keyId'].toString();
      }

      throw Exception('Unable to load payment configuration.');
    }

    throw Exception(
      _extractErrorMessage(
        decoded,
        'Unable to load payment configuration.',
        response,
      ),
    );
  }

  // =========================================================
  // CREATE PAYMENT
  //
  // FULL + ONLINE
  //     -> Razorpay order returned immediately
  //
  // CONCESSIONAL + ONLINE
  //     -> PENDING approval
  //     -> no Razorpay order yet
  //
  // CASH
  //     -> PENDING owner approval
  // =========================================================

  Future<Payment> createPayment({
    required int bookingId,
    required String paymentType,
    required String paymentMethod,
  }) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse('$baseUrl/payments/create'),
      headers: headers,
      body: jsonEncode({
        'bookingId': bookingId,
        'paymentType': paymentType,
        'paymentMethod': paymentMethod,
      }),
    );

    return _handlePaymentResponse(response, 'Unable to create payment.');
  }

  // =========================================================
  // VERIFY ONLINE PAYMENT
  // =========================================================

  Future<Payment> verifyPayment({
    required int bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify'),
      headers: headers,
      body: jsonEncode({
        'bookingId': bookingId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      }),
    );

    return _handlePaymentResponse(response, 'Unable to verify payment.');
  }

  // =========================================================
  // GET PAYMENT BY BOOKING
  // =========================================================
  //
  // Backend can return null when payment does not exist.
  //
  // Therefore this MUST return Payment?
  // =========================================================

  Future<Payment?> getPaymentByBooking(int bookingId) async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/payments/booking/$bookingId'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim() == 'null' || response.body.trim().isEmpty) {
        return null;
      }

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          return Payment.fromJson(decoded);
        }

        return null;
      } catch (_) {
        throw Exception('Unable to read payment information.');
      }
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    throw Exception(
      _extractErrorMessage(decoded, 'Unable to get payment.', response),
    );
  }

  // =========================================================
  // CREATE RENEWAL PAYMENT
  // =========================================================

  Future<Payment> createRenewalPayment(int bookingId) async {
    final headers = await _headers();

    final uri = Uri.parse(
      '$baseUrl/payments/renew',
    ).replace(queryParameters: {'bookingId': bookingId.toString()});

    final response = await http.post(uri, headers: headers);

    return _handlePaymentResponse(
      response,
      'Unable to create renewal payment.',
    );
  }

  // =========================================================
  // VERIFY RENEWAL PAYMENT
  // =========================================================

  Future<Payment> verifyRenewalPayment({
    required int bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse('$baseUrl/payments/renew/verify'),
      headers: headers,
      body: jsonEncode({
        'bookingId': bookingId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      }),
    );

    return _handlePaymentResponse(
      response,
      'Unable to verify renewal payment.',
    );
  }

  // =========================================================
  // OWNER - GET PENDING REQUESTS
  // =========================================================

  Future<List<Payment>> getPendingPaymentRequests() async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/payments/owner/pending'),
      headers: headers,
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Unable to load pending payment requests. '
        'Server returned invalid response.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => Payment.fromJson(json))
            .toList();
      }

      throw Exception(
        'Unable to load pending payment requests. '
        'Invalid server response.',
      );
    }

    throw Exception(
      _extractErrorMessage(
        decoded,
        'Unable to load pending payment requests.',
        response,
      ),
    );
  }

  // =========================================================
  // OWNER - APPROVE PAYMENT
  // =========================================================
  //
  // CASH:
  //   Approval immediately makes payment SUCCESS
  //   and activates booking/seat.
  //
  // CONCESSIONAL + ONLINE:
  //   Approval only changes approvalStatus to APPROVED.
  //   Student must then call createPayment() again.
  // =========================================================

  Future<Payment> approvePayment({required int paymentId}) async {
    final headers = await _headers();

    final ownerId = await _getUserId();

    if (ownerId == null) {
      throw Exception('Owner ID is missing. Please login again.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/payments/owner/$ownerId/$paymentId/approve'),
      headers: headers,
    );

    return _handlePaymentResponse(
      response,
      'Unable to approve payment request.',
    );
  }

  // =========================================================
  // OWNER - REJECT PAYMENT
  // =========================================================

  Future<Payment> rejectPayment({required int paymentId}) async {
    final headers = await _headers();

    final ownerId = await _getUserId();

    if (ownerId == null) {
      throw Exception('Owner ID is missing. Please login again.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/payments/owner/$ownerId/$paymentId/reject'),
      headers: headers,
    );

    return _handlePaymentResponse(
      response,
      'Unable to reject payment request.',
    );
  }
  // =========================================================
  // STUDENT - PAYMENT NOTIFICATION
  //
  // Only APPROVED / REJECTED are returned.
  //
  // SUCCESSFUL normal Razorpay payment does NOT become
  // a dashboard notification.
  // =========================================================

  Future<Payment?> getPaymentNotificationForBooking(int bookingId) async {
    final payment = await getPaymentByBooking(bookingId);

    if (payment == null) {
      return null;
    }

    if (payment.approvalStatus == PaymentApprovalStatus.approved ||
        payment.approvalStatus == PaymentApprovalStatus.rejected) {
      return payment;
    }

    return null;
  }

  // =========================================================
  // OWNER - CONFIRM CASH PAYMENT
  //
  // NOTE:
  // Backend approvePayment() already handles CASH.
  //
  // This method is kept only for backward compatibility.
  // New frontend UI should NOT call this after approval.
  // =========================================================
  Future<List<Payment>> getPaymentNotifications() async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/payments/my-notifications'),
      headers: headers,
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Unable to load notifications.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => Payment.fromJson(json))
            .where(
              (payment) =>
                  payment.approvalStatus == PaymentApprovalStatus.approved ||
                  payment.approvalStatus == PaymentApprovalStatus.rejected,
            )
            .toList();
      }

      return [];
    }

    throw Exception(
      _extractErrorMessage(decoded, 'Unable to load notifications.', response),
    );
  }

  Future<Payment> confirmCashPayment({required int paymentId}) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse('$baseUrl/payments/owner/$paymentId/confirm-cash'),
      headers: headers,
    );

    return _handlePaymentResponse(response, 'Unable to confirm cash payment.');
  }

  // =========================================================
  // RESPONSE HANDLER
  // =========================================================

  Payment _handlePaymentResponse(
    http.Response response,
    String defaultMessage,
  ) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('$defaultMessage Server returned invalid response.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return Payment.fromJson(decoded);
      }

      throw Exception('$defaultMessage Invalid payment response.');
    }

    throw Exception(_extractErrorMessage(decoded, defaultMessage, response));
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  String _extractErrorMessage(
    dynamic decoded,
    String defaultMessage,
    http.Response response,
  ) {
    String message = defaultMessage;

    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] != null) {
        message = decoded['message'].toString();
      } else if (decoded['error'] != null) {
        message = decoded['error'].toString();
      } else if (decoded['details'] != null) {
        message = decoded['details'].toString();
      }
    } else if (response.body.isNotEmpty) {
      message = response.body;
    }

    return message;
  }
}

