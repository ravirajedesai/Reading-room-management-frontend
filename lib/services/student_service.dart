import 'session_service.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StudentService {
  static const String baseUrl =
      "https://automatic-library-management-git-409107405882.asia-south1.run.app";

  // ============================================================
  // GET TOKEN
  // ============================================================

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ============================================================
  // COMMON HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    final Map<String, String> headers = {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
    final libraryId = await SessionService.getActiveLibraryId();
    if (libraryId != null) {
      headers['X-Library-ID'] = libraryId.toString();
    }
    return headers;
  }

  // ============================================================
  // ADD STUDENT
  // ============================================================

  static Future<Map<String, dynamic>> addStudent({
    required int userId,
    required String city,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/students/add"),
      headers: await _headers(),
      body: jsonEncode({
        "city": city,
        "address": address,
        "user": {"id": userId},
      }),
    );

    print("ADD STUDENT STATUS: ${response.statusCode}");
    print("ADD STUDENT RESPONSE: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.trim().isEmpty) {
        final Map<String, String> headers = {};
    final libraryId = await SessionService.getActiveLibraryId();
    if (libraryId != null) {
      headers['X-Library-ID'] = libraryId.toString();
    }
    return headers;
  }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(
      "Failed to add student: "
      "${response.statusCode} ${response.body}",
    );
  }

  // ============================================================
  // GET ALL STUDENTS
  // ============================================================

  static Future<List<dynamic>> getAllStudents() async {
    final response = await http.get(
      Uri.parse("$baseUrl/students"),
      headers: await _headers(),
    );

    print("GET ALL STUDENTS STATUS: ${response.statusCode}");
    print("GET ALL STUDENTS RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      return [];
    }

    throw Exception(
      "Failed to load students: "
      "${response.statusCode} ${response.body}",
    );
  }

  // ============================================================
  // GET STUDENT BY MOBILE
  // ============================================================

  static Future<Map<String, dynamic>> getStudentByMobile(String mobile) async {
    final response = await http.get(
      Uri.parse("$baseUrl/students/mobile/$mobile"),
      headers: await _headers(),
    );

    print("GET STUDENT BY MOBILE STATUS: ${response.statusCode}");
    print("GET STUDENT BY MOBILE RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty) {
        throw Exception("Empty student response");
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(
      "Student not found: "
      "${response.statusCode} ${response.body}",
    );
  }

  // ============================================================
  // GET STUDENT BY USER ID
  // ============================================================

  static Future<Map<String, dynamic>> getStudentByUserId(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/students/user/$userId"),
      headers: await _headers(),
    );

    print(
      "GET STUDENT BY USERID STATUS: "
      "${response.statusCode}",
    );

    print(
      "GET STUDENT BY USERID RESPONSE: "
      "${response.body}",
    );

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty) {
        throw Exception("Empty student response");
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(
      "Failed to load student: "
      "${response.statusCode} ${response.body}",
    );
  }

  // ============================================================
  // UPDATE STUDENT
  // ============================================================

  static Future<Map<String, dynamic>> updateStudent({
    required String mobile,
    required String city,
    required String address,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/students/update/$mobile"),
      headers: await _headers(),
      body: jsonEncode({"city": city, "address": address}),
    );

    print("UPDATE STUDENT STATUS: ${response.statusCode}");
    print("UPDATE STUDENT RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty) {
        final Map<String, String> headers = {};
    final libraryId = await SessionService.getActiveLibraryId();
    if (libraryId != null) {
      headers['X-Library-ID'] = libraryId.toString();
    }
    return headers;
  }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(
      "Failed to update student: "
      "${response.statusCode} ${response.body}",
    );
  }

  // ============================================================
  // GET MY BOOKING
  //
  // Backend:
  //
  // 200 -> PENDING / ACTIVE booking
  // 400/404 + "No active or pending booking found"
  //      -> no booking
  //
  // Other errors -> actual error
  //
  // Response contains:
  //
  // bookingId
  // userId
  // seatId
  // seatNumber
  // startDate
  // endDate
  // bookingStatus
  // paymentId
  // amount
  // paymentStatus
  // paymentMethod
  // approvalStatus
  // paymentType
  // transactionId
  // paidAt
  //
  // ============================================================

  // ============================================================
  // GET MY BOOKING
  // ============================================================

  static Future<Map<String, dynamic>?> getMyBooking(int userId) async {
    final url = "$baseUrl/bookings/my-booking/$userId";

    print("========================================");
    print("GET MY BOOKING");
    print("USER ID: $userId");
    print("URL: $url");

    final response = await http.get(Uri.parse(url), headers: await _headers());

    print("BOOKING STATUS: ${response.statusCode}");
    print("BOOKING RAW RESPONSE: ${response.body}");
    print("========================================");

    // ==========================================================
    // NO BOOKING
    // ==========================================================

    if (response.statusCode == 400 || response.statusCode == 404) {
      final body = response.body.toLowerCase();

      if (body.contains("no active or pending booking") ||
          body.contains("booking not found")) {
        print("NO ACTIVE/PENDING BOOKING");
        return null;
      }
    }

    // ==========================================================
    // SUCCESS
    // ==========================================================

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty || response.body.trim() == "null") {
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded == null) {
        return null;
      }

      if (decoded is Map<String, dynamic>) {
        print("BOOKING MAP: $decoded");

        // ======================================================
        // IMPORTANT
        // Backend MUST return:
        //
        // {
        //   "id": 43,
        //   ...
        // }
        //
        // If old backend still returns bookingId, temporarily
        // normalize it here.
        // ======================================================

        if (decoded['id'] == null && decoded['bookingId'] != null) {
          decoded['id'] = decoded['bookingId'];

          print(
            "WARNING: Backend returned bookingId. "
            "Normalized to id: ${decoded['id']}",
          );
        }

        print("FINAL BOOKING ID: ${decoded['id']}");

        return decoded;
      }

      return Map<String, dynamic>.from(decoded);
    }

    // ==========================================================
    // EXPIRED
    // ==========================================================

    if (response.body.toLowerCase().contains("pending booking has expired")) {
      throw Exception("Your pending booking has expired.");
    }

    // ==========================================================
    // OTHER ERROR
    // ==========================================================

    throw Exception(
      "Failed to load booking: "
      "${response.statusCode} ${response.body}",
    );
  }
  // ============================================================
  // CANCEL PENDING BOOKING
  // ============================================================

  static Future<void> cancelPendingBooking({
    required int bookingId,
    required int userId,
  }) async {
    final url = "$baseUrl/bookings/cancel/$bookingId/$userId";

    print("========================================");
    print("CANCEL PENDING BOOKING");
    print("BOOKING ID: $bookingId");
    print("USER ID: $userId");
    print("URL: $url");

    final response = await http.delete(
      Uri.parse(url),
      headers: await _headers(),
    );

    print(
      "CANCEL STATUS: "
      "${response.statusCode}",
    );

    print(
      "CANCEL RESPONSE: "
      "${response.body}",
    );

    print("========================================");

    // ==========================================================
    // SUCCESS
    // ==========================================================

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    throw Exception(
      "Failed to cancel booking: "
      "${response.statusCode} ${response.body}",
    );
  }
}

