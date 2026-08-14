import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/student_service.dart';
import 'seat_booking_page.dart';
import 'dashboard_page.dart';
import '../widgets/app_drawer.dart';

class StudentPage extends StatefulWidget {
  final String name;
  final String mobile;
  final int userId;

  const StudentPage({
    super.key,
    required this.name,
    required this.mobile,
    required this.userId,
  });

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  // ============================================================
  // PROFILE
  // ============================================================

  Map<String, dynamic>? studentProfile;
  bool profileLoading = true;

  // ============================================================
  // BOOKING
  // ============================================================

  Map<String, dynamic>? activeBooking;
  bool bookingLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadUserProfile();
    loadActiveBooking();
  }

  // ============================================================
  // LOAD USER PROFILE
  // ============================================================

  Future<void> loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      profileLoading = true;
    });

    try {
      debugPrint("========================================");
      debugPrint("LOADING USER PROFILE");
      debugPrint("MOBILE: ${widget.mobile}");

      final student = await StudentService.getStudentByMobile(widget.mobile);

      debugPrint("PROFILE RESPONSE: $student");
      debugPrint("========================================");

      if (!mounted) return;

      setState(() {
        studentProfile = Map<String, dynamic>.from(student);
        profileLoading = false;
      });
    } catch (e) {
      debugPrint("PROFILE ERROR: $e");

      if (!mounted) return;

      setState(() {
        studentProfile = null;
        profileLoading = false;
      });
    }
  }

  // ============================================================
  // LOAD ACTIVE BOOKING
  // ============================================================

  Future<void> loadActiveBooking() async {
    if (!mounted) return;

    setState(() {
      bookingLoading = true;
    });

    try {
      debugPrint("========================================");
      debugPrint("LOADING ACTIVE BOOKING");
      debugPrint("USER ID: ${widget.userId}");

      final Map<String, dynamic>? booking = await StudentService.getMyBooking(
        widget.userId,
      );

      debugPrint("BOOKING RESPONSE:");
      debugPrint("$booking");
      debugPrint("========================================");

      if (!mounted) return;

      setState(() {
        activeBooking = booking;
        bookingLoading = false;
      });
    } catch (e) {
      debugPrint("========================================");
      debugPrint("BOOKING LOAD ERROR:");
      debugPrint("$e");
      debugPrint("========================================");

      if (!mounted) return;

      setState(() {
        activeBooking = null;
        bookingLoading = false;
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshPage() async {
    await Future.wait([loadUserProfile(), loadActiveBooking()]);
  }

  // ============================================================
  // PROFILE VALUE
  // ============================================================

  String _profileValue(String key, String defaultValue) {
    if (studentProfile == null) {
      return defaultValue;
    }

    final value = studentProfile![key];

    if (value == null) {
      return defaultValue;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return defaultValue;
    }

    return text;
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _profileCard() {
    if (profileLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    final name = _profileValue("name", widget.name);
    final mobile = _profileValue("mobile", widget.mobile);
    final city = _profileValue("city", "City not available");
    final address = _profileValue("address", "Address not available");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.indigo, size: 26),
              ),

              const SizedBox(width: 12),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Profile",
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Your personal information",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ======================================================
          // USER
          // ======================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.indigo,
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "U",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Name",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _profileRow(icon: Icons.phone, title: "Mobile Number", value: mobile),

          const SizedBox(height: 10),

          _profileRow(icon: Icons.location_city, title: "City", value: city),

          const SizedBox(height: 10),

          _profileRow(icon: Icons.home, title: "Address", value: address),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE ROW
  // ============================================================

  Widget _profileRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.indigo, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE BOOKING CARD
  // ============================================================

  Widget _activeBookingCard() {
    if (bookingLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    if (activeBooking == null) {
      return _noBookingCard();
    }

    final booking = activeBooking!;

    final seatNumber = booking["seatNumber"]?.toString() ?? "-";

    final seatId = booking["seatId"]?.toString() ?? "-";

    final bookingId =
        booking["bookingId"]?.toString() ?? booking["id"]?.toString() ?? "-";

    final bookingStatus = booking["bookingStatus"]?.toString() ?? "-";

    final startDate = booking["startDate"]?.toString() ?? "-";

    final endDate = booking["endDate"]?.toString() ?? "-";

    final paymentId = booking["paymentId"]?.toString() ?? "-";

    final amount = booking["amount"]?.toString() ?? "0";

    final paymentStatus = booking["paymentStatus"]?.toString() ?? "-";

    final paymentMethod = booking["paymentMethod"]?.toString() ?? "-";

    final transactionId = booking["transactionId"]?.toString() ?? "-";

    final paidAt = booking["paidAt"]?.toString() ?? "-";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Color(0xff3949AB)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.20),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_seat,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Seat Booking",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Your seat and payment details",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bookingStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ======================================================
          // SEAT NUMBER
          // ======================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_seat,
                    color: Colors.indigo,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Text(
                    "Seat Number",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),

                Text(
                  seatNumber,
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          _whiteDetailRow("Seat ID", seatId),

          const SizedBox(height: 12),

          // ======================================================
          // VALIDITY
          // ======================================================
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _bookingInfo(
                    "Valid From",
                    startDate,
                    Icons.calendar_today,
                  ),
                ),

                Container(width: 1, height: 45, color: Colors.white24),

                Expanded(
                  child: _bookingInfo(
                    "Valid Until",
                    endDate,
                    Icons.event_available,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // PAYMENT SECTION
          // ======================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payment, color: Colors.white, size: 20),

                    SizedBox(width: 8),

                    Text(
                      "Payment Information",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _bookingDetailRow("Payment Status", paymentStatus),

                const SizedBox(height: 9),

                _bookingDetailRow("Payment ID", paymentId),

                const SizedBox(height: 9),

                _bookingDetailRow("Amount Paid", "₹$amount"),

                const SizedBox(height: 9),

                _bookingDetailRow("Payment Method", paymentMethod),

                const SizedBox(height: 9),

                _bookingDetailRow("Transaction ID", transactionId),

                const SizedBox(height: 9),

                _bookingDetailRow("Paid At", paidAt),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // BOOKING INFORMATION
          // ======================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      color: Colors.white,
                      size: 20,
                    ),

                    SizedBox(width: 8),

                    Text(
                      "Booking Information",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _bookingDetailRow("Booking ID", bookingId),

                const SizedBox(height: 9),

                _bookingDetailRow("Booking Status", bookingStatus),

                const SizedBox(height: 9),

                _bookingDetailRow("Start Date", startDate),

                const SizedBox(height: 9),

                _bookingDetailRow("End Date", endDate),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // ======================================================
          // PAYMENT RECEIPT BUTTON
          // ======================================================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showPaymentSlip,
              icon: const Icon(Icons.receipt_long),
              label: const Text(
                "VIEW PAYMENT RECEIPT",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WHITE DETAIL ROW
  // ============================================================

  Widget _whiteDetailRow(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),

          const Spacer(),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO BOOKING CARD
  // ============================================================

  Widget _noBookingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_seat_outlined,
              size: 42,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "No Active Seat Booking",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          const Text(
            "You don't have an active seat reservation.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openSeatBooking,
              icon: const Icon(Icons.event_seat),
              label: const Text("BOOK SEAT"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING INFO
  // ============================================================

  Widget _bookingInfo(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),

          const SizedBox(height: 5),

          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING DETAIL ROW
  // ============================================================

  Widget _bookingDetailRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OPEN SEAT BOOKING
  // ============================================================

  Future<void> _openSeatBooking() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatBookingPage(
          userId: widget.userId,
          name: widget.name,
          mobile: widget.mobile,
        ),
      ),
    );

    await loadActiveBooking();
  }

  // ============================================================
  // PAYMENT RECEIPT DIALOG
  // ============================================================

  void _showPaymentSlip() {
    if (activeBooking == null) return;

    final booking = activeBooking!;

    final bookingId =
        booking["bookingId"]?.toString() ?? booking["id"]?.toString() ?? "-";

    final seatNumber = booking["seatNumber"]?.toString() ?? "-";

    final seatId = booking["seatId"]?.toString() ?? "-";

    final paymentId = booking["paymentId"]?.toString() ?? "-";

    final amount = booking["amount"]?.toString() ?? "0";

    final paymentStatus = booking["paymentStatus"]?.toString() ?? "-";

    final paymentMethod = booking["paymentMethod"]?.toString() ?? "-";

    final transactionId = booking["transactionId"]?.toString() ?? "-";

    final paidAt = booking["paidAt"]?.toString() ?? "-";

    final startDate = booking["startDate"]?.toString() ?? "-";

    final endDate = booking["endDate"]?.toString() ?? "-";

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.indigo),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  "Payment Receipt",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==================================================
                // SUCCESS ICON
                // ==================================================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 45,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  paymentStatus.toUpperCase() == "SUCCESS"
                      ? "Payment Successful"
                      : "Payment Status: $paymentStatus",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: paymentStatus.toUpperCase() == "SUCCESS"
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),

                const SizedBox(height: 20),

                _receiptRow("Student", widget.name),

                _receiptRow("Mobile", widget.mobile),

                _receiptRow("Seat Number", seatNumber),

                _receiptRow("Seat ID", seatId),

                _receiptRow("Booking ID", bookingId),

                _receiptRow("Payment ID", paymentId),

                _receiptRow("Payment Status", paymentStatus),

                _receiptRow("Payment Method", paymentMethod),

                _receiptRow("Amount", "₹$amount"),

                _receiptRow("Transaction ID", transactionId),

                _receiptRow("Paid At", paidAt),

                _receiptRow("Valid From", startDate),

                _receiptRow("Valid Until", endDate),
              ],
            ),
          ),

          actions: [
            // ==================================================
            // CLOSE
            // ==================================================
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("CLOSE"),
            ),

            // ==================================================
            // DOWNLOAD
            // ==================================================
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _downloadPaymentReceipt();
              },
              icon: const Icon(Icons.download),
              label: const Text("DOWNLOAD"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DOWNLOAD / SHARE PAYMENT RECEIPT PDF
  // ============================================================

  Future<void> _downloadPaymentReceipt() async {
    if (activeBooking == null) return;

    try {
      final booking = activeBooking!;

      final bookingId =
          booking["bookingId"]?.toString() ?? booking["id"]?.toString() ?? "-";

      final seatNumber = booking["seatNumber"]?.toString() ?? "-";

      final seatId = booking["seatId"]?.toString() ?? "-";

      final paymentId = booking["paymentId"]?.toString() ?? "-";

      final amount = booking["amount"]?.toString() ?? "0";

      final paymentStatus = booking["paymentStatus"]?.toString() ?? "-";

      final paymentMethod = booking["paymentMethod"]?.toString() ?? "-";

      final transactionId = booking["transactionId"]?.toString() ?? "-";

      final paidAt = booking["paidAt"]?.toString() ?? "-";

      final startDate = booking["startDate"]?.toString() ?? "-";

      final endDate = booking["endDate"]?.toString() ?? "-";

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,

          margin: const pw.EdgeInsets.all(32),

          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,

              children: [
                // =================================================
                // HEADER
                // =================================================
                pw.Center(
                  child: pw.Text(
                    "READING ROOM",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 5),

                pw.Center(
                  child: pw.Text(
                    "Payment Receipt",
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ),

                pw.SizedBox(height: 25),

                // =================================================
                // PAYMENT STATUS
                // =================================================
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      paymentStatus.toUpperCase() == "SUCCESS"
                          ? "PAYMENT SUCCESSFUL"
                          : "PAYMENT STATUS: $paymentStatus",
                      style: pw.TextStyle(
                        color: PdfColors.green,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(height: 25),

                // =================================================
                // STUDENT INFORMATION
                // =================================================
                _pdfSectionTitle("Student Information"),

                _pdfRow("Student Name", widget.name),

                _pdfRow("Mobile Number", widget.mobile),

                pw.SizedBox(height: 18),

                // =================================================
                // BOOKING INFORMATION
                // =================================================
                _pdfSectionTitle("Booking Information"),

                _pdfRow("Booking ID", bookingId),

                _pdfRow("Seat Number", seatNumber),

                _pdfRow("Seat ID", seatId),

                _pdfRow("Valid From", startDate),

                _pdfRow("Valid Until", endDate),

                pw.SizedBox(height: 18),

                // =================================================
                // PAYMENT INFORMATION
                // =================================================
                _pdfSectionTitle("Payment Information"),

                _pdfRow("Payment ID", paymentId),

                _pdfRow("Payment Status", paymentStatus),

                _pdfRow("Amount Paid", "Rs. $amount"),

                _pdfRow("Payment Method", paymentMethod),

                _pdfRow("Transaction ID", transactionId),

                _pdfRow("Paid At", paidAt),

                pw.Spacer(),

                pw.Divider(),

                pw.Center(
                  child: pw.Text(
                    "Thank you for using our Reading Room.",
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      // ==========================================================
      // ANDROID SHARE / SAVE / PRINT
      // ==========================================================

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: "payment_receipt_$bookingId.pdf",
      );
    } catch (e) {
      debugPrint("PDF RECEIPT ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to generate receipt: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // RECEIPT ROW
  // ============================================================

  Widget _receiptRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF SECTION TITLE
  // ============================================================

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  // ============================================================
  // PDF ROW
  // ============================================================

  pw.Widget _pdfRow(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ),

          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer() {
    return AppDrawer(
      userId: widget.userId,
      name: widget.name,
      mobile: widget.mobile,
      selectedPage: "Student Management",
    );
  }
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ========================================================
      // DRAWER
      // ========================================================
      drawer: _buildDrawer(),

      // ========================================================
      // BODY
      // ========================================================
      body: RefreshIndicator(
        onRefresh: refreshPage,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(16),

          children: [
            // ====================================================
            // WELCOME
            // ====================================================
            Text(
              "Welcome, ${widget.name} 👋",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            const Text(
              "Manage your profile, seat and payments",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 18),

            // ====================================================
            // PROFILE
            // ====================================================
            _profileCard(),

            const SizedBox(height: 18),

            // ====================================================
            // BOOKING TITLE
            // ====================================================
            const Text(
              "Seat & Payment Information",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // ====================================================
            // BOOKING
            // ====================================================
            _activeBookingCard(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
