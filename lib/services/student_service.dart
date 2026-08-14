import 'dart:convert';
import 'package:http/http.dart' as http;

class StudentService {
  static const String baseUrl =
      "https://automatic-library-management.onrender.com";

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
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "city": city,
        "address": address,
        "user": {"id": userId},
      }),
    );

    print("ADD STUDENT STATUS: ${response.statusCode}");
    print("ADD STUDENT RESPONSE: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
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
    final response = await http.get(Uri.parse("$baseUrl/students"));

    print("GET ALL STUDENTS STATUS: ${response.statusCode}");
    print("GET ALL STUDENTS RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
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
    );

    print("GET STUDENT STATUS: ${response.statusCode}");
    print("GET STUDENT RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception(
      "Student not found: "
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
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"city": city, "address": address}),
    );

    print("UPDATE STUDENT STATUS: ${response.statusCode}");
    print("UPDATE STUDENT RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception(
      "Failed to update student: "
      "${response.statusCode} ${response.body}",
    );
  }

  // ============================================================
  // GET MY ACTIVE BOOKING
  // ============================================================

  static Future<Map<String, dynamic>?> getMyBooking(int userId) async {
    final url = "$baseUrl/bookings/my-booking/$userId";

    print("========================================");
    print("GET MY BOOKING");
    print("USER ID: $userId");
    print("URL: $url");

    final response = await http.get(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );

    print("BOOKING STATUS: ${response.statusCode}");
    print("BOOKING RESPONSE: ${response.body}");
    print("========================================");

    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty || response.body.trim() == "null") {
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded == null) {
        return null;
      }

      return Map<String, dynamic>.from(decoded);
    }

    if (response.statusCode == 404) {
      return null;
    }

    throw Exception(
      "Failed to load booking: "
      "${response.statusCode} ${response.body}",
    );
  }
}
