import 'session_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OwnerService {
  static const String baseUrl =
      "https://automatic-library-management-git-409107405882.asia-south1.run.app";

  // =========================================================
  // COMMON HEADERS
  // =========================================================

  static Future<Map<String, String>> _headers(String token) async {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
    final libraryId = await SessionService.getActiveLibraryId();
    if (libraryId != null) {
      headers['X-Library-ID'] = libraryId.toString();
    }
    return headers;
  }

  // =========================================================
  // GET ALL USERS
  // =========================================================

  static Future<List<dynamic>> getAllUsers(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/owner/users"),
      headers: await _headers(token),
    );

    print("GET USERS STATUS: ${response.statusCode}");
    print("GET USERS BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      throw Exception("Invalid users response format.");
    }

    _handleCommonErrors(response);

    throw Exception(
      "Failed to get users: "
      "${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // GET ALL BOOKINGS
  // =========================================================

  static Future<List<dynamic>> getAllBookings(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/owner/bookings"),
      headers: await _headers(token),
    );

    print("GET BOOKINGS STATUS: ${response.statusCode}");
    print("GET BOOKINGS BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      throw Exception("Invalid bookings response format.");
    }

    _handleCommonErrors(response);

    throw Exception(
      "Failed to get bookings: "
      "${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // GET ALL PAYMENTS
  // =========================================================

  static Future<List<dynamic>> getAllPayments(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/owner/payments"),
      headers: await _headers(token),
    );

    print("GET PAYMENTS STATUS: ${response.statusCode}");
    print("GET PAYMENTS BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      throw Exception("Invalid payments response format.");
    }

    _handleCommonErrors(response);

    throw Exception(
      "Failed to get payments: "
      "${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // GET PAID STUDENTS (WITH PAGINATION SUPPORT)
  // =========================================================

  static Future<List<dynamic>> getPaidStudents(
    String token, {
    int page = 0,
    int size = 10,
    int? ownerId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/owner/paid-students?page=$page&size=$size'),
            headers: {
              ...await _headers(token),
              if (ownerId != null) 'X-USER-ID': ownerId.toString(),
            },
          )
          .timeout(const Duration(seconds: 30));

      print("GET PAID STUDENTS STATUS: ${response.statusCode}");
      print("GET PAID STUDENTS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map && decoded['content'] is List) {
          return decoded['content'];
        }
        return [];
      } else {
        throw Exception(
          'Failed to load paid students (${response.statusCode})',
        );
      }
    } catch (e) {
      print('Error in getPaidStudents: $e');
      rethrow;
    }
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

    final response = await http.get(uri, headers: await _headers(token));

    print("PAYMENT HISTORY STATUS: ${response.statusCode}");
    print("PAYMENT HISTORY BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      throw Exception("Invalid payment history response format.");
    }

    _handleCommonErrors(response);

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
          headers: await _headers(token),
        )
        .timeout(const Duration(seconds: 30));

    print("DASHBOARD STATS STATUS: ${response.statusCode}");
    print("DASHBOARD STATS BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception("Invalid dashboard stats response format.");
    }

    _handleCommonErrors(response);

    throw Exception(
      "Failed to get dashboard stats: "
      "${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // GET PENDING BOOKINGS / WAITING SEATS
  // =========================================================

  static Future<List<dynamic>> getPendingBookings(
    String token,
    int ownerId,
  ) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/bookings/owner/pending"),
          headers: {...await _headers(token), "X-USER-ID": ownerId.toString()},
        )
        .timeout(const Duration(seconds: 30));

    print("=========================================");
    print("PENDING BOOKINGS / WAITING SEATS");
    print("OWNER ID: $ownerId");
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");
    print("=========================================");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      throw Exception("Invalid pending bookings response format.");
    }

    _handleCommonErrors(response);

    throw Exception(
      "Failed to load pending bookings: "
      "${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // GET PENDING PAYMENT REQUESTS
  // =========================================================

  static Future<List<dynamic>> getPendingPaymentRequests(
    String token,
    int ownerId,
  ) async {
    final response = await http
        .get(
          Uri.parse("$baseUrl/payments/owner/pending"),
          headers: {...await _headers(token), "X-USER-ID": ownerId.toString()},
        )
        .timeout(const Duration(seconds: 30));

    print("=========================================");
    print("PENDING PAYMENT REQUESTS");
    print("OWNER ID: $ownerId");
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");
    print("=========================================");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      throw Exception("Invalid pending payments response format.");
    }

    _handleCommonErrors(response);

    throw Exception(
      "Failed to load pending payments: "
      "${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // APPROVE PAYMENT REQUEST
  // =========================================================

  static Future<Map<String, dynamic>> approvePaymentRequest(
    String token,
    int ownerId,
    int paymentId,
  ) async {
    final url = "$baseUrl/payments/owner/$ownerId/$paymentId/approve";

    print("=========================================");
    print("APPROVE PAYMENT REQUEST");
    print("OWNER ID: $ownerId");
    print("PAYMENT ID: $paymentId");
    print("URL: $url");
    print("=========================================");

    final response = await http
        .post(
          Uri.parse(url),
          headers: {...await _headers(token), "X-USER-ID": ownerId.toString()},
        )
        .timeout(const Duration(seconds: 30));

    print("APPROVE STATUS: ${response.statusCode}");
    print("APPROVE BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception("Invalid approve payment response.");
    }

    _handleCommonErrors(response);

    throw Exception(
      "Failed to approve payment: "
      "${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // REJECT PAYMENT REQUEST
  // =========================================================

  static Future<Map<String, dynamic>> rejectPaymentRequest(
    String token,
    int ownerId,
    int paymentId,
  ) async {
    final url = "$baseUrl/payments/owner/$ownerId/$paymentId/reject";

    print("=========================================");
    print("REJECT PAYMENT REQUEST");
    print("OWNER ID: $ownerId");
    print("PAYMENT ID: $paymentId");
    print("URL: $url");
    print("=========================================");

    final response = await http
        .post(
          Uri.parse(url),
          headers: {...await _headers(token), "X-USER-ID": ownerId.toString()},
        )
        .timeout(const Duration(seconds: 30));

    print("REJECT STATUS: ${response.statusCode}");
    print("REJECT BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception("Invalid reject payment response.");
    }

    _handleCommonErrors(response);

    throw Exception(
      "Failed to reject payment: "
      "${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // CONFIRM CASH PAYMENT
  // =========================================================

  static Future<Map<String, dynamic>> confirmCashPayment(
    String token,
    int ownerId,
    int paymentId,
  ) async {
    final url = "$baseUrl/payments/owner/$paymentId/confirm-cash";

    print("=========================================");
    print("CONFIRM CASH PAYMENT");
    print("OWNER ID: $ownerId");
    print("PAYMENT ID: $paymentId");
    print("URL: $url");
    print("=========================================");

    final response = await http
        .post(
          Uri.parse(url),
          headers: {...await _headers(token), "X-USER-ID": ownerId.toString()},
        )
        .timeout(const Duration(seconds: 30));

    print("CASH CONFIRM STATUS: ${response.statusCode}");
    print("CASH CONFIRM BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception("Invalid cash confirmation response.");
    }

    _handleCommonErrors(response);

    throw Exception(
      "Failed to confirm cash payment: "
      "${response.statusCode} ${response.body}",
    );
  }

  // =========================================================
  // REMOVE PENDING BOOKING
  // =========================================================

  static Future<void> removePendingBooking(
    String token,
    int ownerId,
    int bookingId,
  ) async {
    final url = "$baseUrl/bookings/owner/pending/$bookingId";

    print("=========================================");
    print("REMOVE PENDING BOOKING");
    print("OWNER ID: $ownerId");
    print("BOOKING ID: $bookingId");
    print("URL: $url");
    print("=========================================");

    final response = await http
        .delete(
          Uri.parse(url),
          headers: {...await _headers(token), "X-USER-ID": ownerId.toString()},
        )
        .timeout(const Duration(seconds: 30));

    print("REMOVE PENDING STATUS: ${response.statusCode}");
    print("REMOVE PENDING BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    _handleCommonErrors(response);
  }

  // =========================================================
  // COMMON ERROR HANDLING
  // =========================================================

  static void _handleCommonErrors(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception("Session expired. Please login again.");
    }

    if (response.statusCode == 403) {
      throw Exception("Access denied. Owner permission required.");
    }

    if (response.statusCode == 404) {
      throw Exception("Requested resource was not found.");
    }

    if (response.statusCode == 500) {
      throw Exception("Server error: ${response.body}");
    }
  }
}