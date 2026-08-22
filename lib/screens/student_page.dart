import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/booking_service.dart';
import '../services/student_service.dart';
import '../models/booking_model.dart';
import 'payment_page.dart';
import 'seat_booking_page.dart';
import 'pomodoro_page.dart';
import '../services/study_tracker_service.dart';
import '../services/session_service.dart';
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
  final BookingService _bookingService = BookingService();

  // ============================================================
  // PROFILE & BOOKING STATE
  // ============================================================

  Map<String, dynamic>? studentProfile;
  bool profileLoading = true;

  Map<String, dynamic>? activeBooking;
  bool bookingLoading = true;

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
    setState(() => profileLoading = true);

    try {
      final student = await StudentService.getStudentByUserId(widget.userId);
      if (!mounted) return;
      setState(() {
        studentProfile = Map<String, dynamic>.from(student);
        profileLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => profileLoading = false);
    }
  }

  // ============================================================
  // LOAD ACTIVE / PENDING BOOKING
  // ============================================================

  Future<void> loadActiveBooking() async {
    if (!mounted) return;
    setState(() => bookingLoading = true);

    try {
      final Map<String, dynamic>? booking = await StudentService.getMyBooking(
        widget.userId,
      );

      if (!mounted) return;
      setState(() {
        activeBooking = booking;
        bookingLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        activeBooking = null;
        bookingLoading = false;
      });
    }
  }

  Future<void> refreshPage() async {
    await Future.wait([loadUserProfile(), loadActiveBooking()]);
  }

  // ============================================================
  // CANCEL PENDING SEAT HOLD (STUDENT ACTION)
  // ============================================================

  Future<void> _cancelSeatHold(String bookingIdStr, String seatNumber) async {
    final int? bookingId = int.tryParse(bookingIdStr);
    if (bookingId == null) {
      _showMessage('Invalid booking ID', isError: true);
      return;
    }

    // 1. Show Confirmation Dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cancel Seat Hold?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to cancel your hold on Seat $seatNumber?\n\nThe seat will be released immediately and made available for other students.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Keep Hold',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Cancel Hold',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // 2. Loading dialog
    _showLoadingDialog('Cancelling your seat hold...');

    try {
      await _bookingService.cancelPendingBooking(
        bookingId: bookingId,
        userId: widget.userId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      _showMessage('Seat $seatNumber hold cancelled successfully.');
      await loadActiveBooking(); // Refresh to show no-booking card
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      _showMessage(_cleanError(e), isError: true);
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  String _cleanError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    return message;
  }

  String _profileValue(String key, String defaultValue) {
    if (studentProfile == null) return defaultValue;
    final value = studentProfile![key];
    if (value == null) return defaultValue;
    final text = value.toString().trim();
    return text.isEmpty ? defaultValue : text;
  }

  // ============================================================
  // STUDY ANALYTICS & POMODORO CARD
  // ============================================================

  Widget _studyAnalyticsCard() {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        StudyTrackerService.getTodayStudyMinutes(),
        StudyTrackerService.getThisWeekStudyMinutes(),
        StudyTrackerService.getStreakDays(),
        StudyTrackerService.getTotalPomodoroCount(),
      ]),
      builder: (context, snapshot) {
        final todayMins = snapshot.data?[0] ?? 0;
        final weekMins = snapshot.data?[1] ?? 0;
        final streak = snapshot.data?[2] ?? 1;
        final pomodoros = snapshot.data?[3] ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.timer_outlined, color: Colors.indigo, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Study Time & Pomodoro",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Productivity statistics",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo.shade800,
                      side: BorderSide(color: Colors.indigo.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text("Focus Mode", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await PomodoroPage.open(context);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.8),
              // 4 Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _studyMetricItem(
                      icon: Icons.hourglass_bottom_rounded,
                      label: "Today's Study",
                      value: StudyTrackerService.formatMinutesToHours(todayMins),
                      color: Colors.indigo,
                      bgColor: Colors.indigo.shade50,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _studyMetricItem(
                      icon: Icons.calendar_view_week_rounded,
                      label: "This Week",
                      value: StudyTrackerService.formatMinutesToHours(weekMins),
                      color: Colors.teal,
                      bgColor: Colors.teal.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _studyMetricItem(
                      icon: Icons.local_fire_department_rounded,
                      label: "Study Streak",
                      value: "$streak Days",
                      color: Colors.orange.shade800,
                      bgColor: Colors.orange.shade50,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _studyMetricItem(
                      icon: Icons.check_circle_outline_rounded,
                      label: "Pomodoros",
                      value: "$pomodoros Cycles",
                      color: Colors.deepPurple,
                      bgColor: Colors.deepPurple.shade50,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _studyMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

    final name = studentProfile != null
        ? _profileValue("name", widget.name)
        : widget.name;
    final mobile = studentProfile != null
        ? _profileValue("mobile", widget.mobile)
        : widget.mobile;
    final city = _profileValue("city", "");
    final address = _profileValue("address", "");

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
          if (studentProfile != null && city.isNotEmpty) ...[
            const SizedBox(height: 10),
            _profileRow(icon: Icons.location_city, title: "City", value: city),
          ],
          if (studentProfile != null && address.isNotEmpty) ...[
            const SizedBox(height: 10),
            _profileRow(icon: Icons.home, title: "Address", value: address),
          ],
        ],
      ),
    );
  }

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
  // ACTIVE BOOKING CARD (WITH PAY NOW & CANCEL HOLD BUTTONS)
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
    final approvalStatus = booking["approvalStatus"]?.toString() ?? "";
    final paymentType = booking["paymentType"]?.toString() ?? "";
    final transactionId = booking["transactionId"]?.toString() ?? "-";
    final paidAt = booking["paidAt"]?.toString() ?? "-";

    final deadlineInfo = _getPaymentDeadline(booking);
    final deadlineDate = deadlineInfo["deadline"] as DateTime?;
    final daysRemaining = deadlineInfo["daysRemaining"] as int;
    final deadlineExpired = deadlineInfo["expired"] as bool;

    final displayStatus = _getDisplayStatus(
      bookingStatus: bookingStatus,
      paymentStatus: paymentStatus,
      approvalStatus: approvalStatus,
      paymentType: paymentType,
      deadlineExpired: deadlineExpired,
    );

    final statusColor = _getStatusColor(
      bookingStatus: bookingStatus,
      paymentStatus: paymentStatus,
      approvalStatus: approvalStatus,
      paymentType: paymentType,
      deadlineExpired: deadlineExpired,
    );

    final paymentPending = paymentStatus.toUpperCase() == "PENDING";
    final isPendingHold =
        bookingStatus.toUpperCase() == "PENDING" || paymentPending;
    final concessionalApprovalPending =
        paymentType.toUpperCase() == "CONCESSIONAL" &&
        paymentPending &&
        approvalStatus.toUpperCase() == "PENDING";

    final canPayNow =
        paymentPending && !concessionalApprovalPending && !deadlineExpired;
    final temporaryBlocked =
        paymentPending && !concessionalApprovalPending && !deadlineExpired;

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
          // Header
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
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (temporaryBlocked) ...[
            _temporaryBlockedCard(
              deadlineDate: deadlineDate,
              daysRemaining: daysRemaining,
            ),
            const SizedBox(height: 12),
          ],

          if (concessionalApprovalPending) ...[
            _approvalPendingCard(),
            const SizedBox(height: 12),
          ],

          if (deadlineExpired && paymentPending) ...[
            _deadlineExpiredCard(),
            const SizedBox(height: 12),
          ],

          // Seat Number Box
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

          // Validity
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

          // Payment Information
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
                _bookingDetailRow("Amount", "₹$amount"),
                const SizedBox(height: 9),
                _bookingDetailRow("Payment Method", paymentMethod),
                if (paymentType.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  _bookingDetailRow("Payment Type", paymentType),
                ],
                if (approvalStatus.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  _bookingDetailRow("Approval Status", approvalStatus),
                ],
                if (transactionId != "-" && transactionId.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  _bookingDetailRow("Transaction ID", transactionId),
                ],
                if (paidAt != "-" && paidAt.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  _bookingDetailRow("Paid At", paidAt),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Booking Information
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
                if (paymentPending && deadlineDate != null) ...[
                  const SizedBox(height: 9),
                  _bookingDetailRow(
                    "Payment Deadline",
                    _formatDisplayDate(deadlineDate),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // ACTION BUTTONS: PAY NOW + CANCEL HOLD
          // ======================================================
          if (isPendingHold) ...[
            if (canPayNow)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openPayment,
                  icon: const Icon(Icons.payment, size: 20),
                  label: const Text(
                    "PAY NOW",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Cancel Seat Hold Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelSeatHold(bookingId, seatNumber),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text(
                  "CANCEL SEAT HOLD",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white60, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          // ======================================================
          // RECEIPT (ONLY WHEN PAID)
          // ======================================================
          if (_isPaymentSuccessful(paymentStatus))
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
  // STATUS CARDS
  // ============================================================

  Widget _temporaryBlockedCard({
    required DateTime? deadlineDate,
    required int daysRemaining,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_clock,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "TEMPORARY SEAT BLOCKED",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "This seat is temporarily reserved for you. Complete the payment to confirm your booking.",
            style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 10),
          if (deadlineDate != null)
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    daysRemaining <= 0
                        ? "Payment deadline is today"
                        : "$daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDisplayDate(deadlineDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _approvalPendingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.45)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top, color: Colors.orange, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "OWNER APPROVAL PENDING",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Your concessional payment request is waiting for owner approval. Payment will be available after approval.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deadlineExpiredCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.45)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PAYMENT DEADLINE EXPIRED",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "The temporary 5-day payment period has expired. Please create a new booking.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPaymentDeadline(Map<String, dynamic> booking) {
    DateTime? reservationDate;
    final possibleDates = [
      booking["createdAt"],
      booking["bookingDate"],
      booking["reservationDate"],
      booking["reservedAt"],
      booking["createdOn"],
      booking["startDate"],
    ];

    for (final value in possibleDates) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty || text == "-") continue;
      try {
        reservationDate = DateTime.parse(text);
        break;
      } catch (_) {}
    }

    if (reservationDate == null) {
      return {"deadline": null, "daysRemaining": 0, "expired": false};
    }

    final deadline = reservationDate.add(const Duration(days: 5));
    final now = DateTime.now();
    final difference = deadline.difference(now);
    final expired = now.isAfter(deadline);
    int daysRemaining = difference.inDays;
    if (!expired && daysRemaining < 1) daysRemaining = 1;
    if (expired) daysRemaining = 0;

    return {
      "deadline": deadline,
      "daysRemaining": daysRemaining,
      "expired": expired,
    };
  }

  String _getDisplayStatus({
    required String bookingStatus,
    required String paymentStatus,
    required String approvalStatus,
    required String paymentType,
    required bool deadlineExpired,
  }) {
    final booking = bookingStatus.toUpperCase();
    final payment = paymentStatus.toUpperCase();
    final approval = approvalStatus.toUpperCase();
    final type = paymentType.toUpperCase();

    if (type == "CONCESSIONAL" &&
        payment == "PENDING" &&
        approval == "PENDING") {
      return "APPROVAL PENDING";
    }
    if (payment == "SUCCESS") {
      return booking == "ACTIVE" ? "BOOKED" : "PAID";
    }
    if (payment == "PENDING" && deadlineExpired) {
      return "EXPIRED";
    }
    if (payment == "PENDING") {
      return "PAYMENT PENDING";
    }
    if (payment == "FAILED") {
      return "PAYMENT FAILED";
    }
    if (booking == "CANCELLED") {
      return "CANCELLED";
    }
    return booking.isNotEmpty ? booking : "PENDING";
  }

  Color _getStatusColor({
    required String bookingStatus,
    required String paymentStatus,
    required String approvalStatus,
    required String paymentType,
    required bool deadlineExpired,
  }) {
    final booking = bookingStatus.toUpperCase();
    final payment = paymentStatus.toUpperCase();
    final approval = approvalStatus.toUpperCase();
    final type = paymentType.toUpperCase();

    if (type == "CONCESSIONAL" &&
        payment == "PENDING" &&
        approval == "PENDING") {
      return Colors.orange;
    }
    if (payment == "SUCCESS") {
      return Colors.green;
    }
    if (payment == "PENDING" && deadlineExpired) {
      return Colors.red;
    }
    if (payment == "PENDING") {
      return Colors.orange;
    }
    if (payment == "FAILED" || booking == "CANCELLED") {
      return Colors.red;
    }
    return Colors.orange;
  }

  bool _isPaymentSuccessful(String paymentStatus) {
    return paymentStatus.toUpperCase() == "SUCCESS";
  }

  Future<void> _openPayment() async {
    if (activeBooking == null) return;
    final booking = activeBooking!;
    final paymentStatus = booking["paymentStatus"]?.toString() ?? "";
    final approvalStatus = booking["approvalStatus"]?.toString() ?? "";
    final paymentType = booking["paymentType"]?.toString() ?? "";

    if (paymentStatus.toUpperCase() != "PENDING") return;

    if (paymentType.toUpperCase() == "CONCESSIONAL" &&
        approvalStatus.toUpperCase() == "PENDING") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment is waiting for owner approval."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final deadlineInfo = _getPaymentDeadline(booking);
    if (deadlineInfo["expired"] as bool) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("The 5-day payment period has expired."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Booking? bookingObj;
    try {
      bookingObj = Booking.fromJson(booking);
    } catch (_) {
      bookingObj = Booking(
        id: int.tryParse(booking["bookingId"]?.toString() ?? booking["id"]?.toString() ?? ""),
        userId: widget.userId,
        seatId: int.tryParse(booking["seatId"]?.toString() ?? ""),
        seatNumber: int.tryParse(booking["seatNumber"]?.toString() ?? ""),
        amount: double.tryParse(booking["amount"]?.toString() ?? ""),
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          booking: bookingObj!,
        ),
      ),
    );

    await loadActiveBooking();
  }

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
            "You don't have an active or pending seat reservation.",
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

  String _formatDisplayDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // PAYMENT RECEIPT
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
    final paymentType = booking["paymentType"]?.toString() ?? "-";
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
                _receiptRow("Payment Type", paymentType),
                _receiptRow("Amount", "₹$amount"),
                _receiptRow("Transaction ID", transactionId),
                _receiptRow("Paid At", paidAt),
                _receiptRow("Valid From", startDate),
                _receiptRow("Valid Until", endDate),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("CLOSE"),
            ),
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
      final paymentType = booking["paymentType"]?.toString() ?? "-";
      final transactionId = booking["transactionId"]?.toString() ?? "-";
      final paidAt = booking["paidAt"]?.toString() ?? "-";
      final startDate = booking["startDate"]?.toString() ?? "-";
      final endDate = booking["endDate"]?.toString() ?? "-";

      final String libName = await SessionService.getActiveLibraryName() ?? "READING ROOM";
      final String? libAddress = await SessionService.getActiveLibraryAddress();

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    libName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                if (libAddress != null && libAddress.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Center(
                    child: pw.Text(
                      libAddress,
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                    ),
                  ),
                ],
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    "Payment Receipt",
                    style: const pw.TextStyle(fontSize: 15, color: PdfColors.grey800),
                  ),
                ),
                pw.SizedBox(height: 25),
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
                _pdfSectionTitle("Student Information"),
                _pdfRow("Student Name", widget.name),
                _pdfRow("Mobile Number", widget.mobile),
                pw.SizedBox(height: 18),
                _pdfSectionTitle("Booking Information"),
                _pdfRow("Booking ID", bookingId),
                _pdfRow("Seat Number", seatNumber),
                _pdfRow("Seat ID", seatId),
                _pdfRow("Valid From", startDate),
                _pdfRow("Valid Until", endDate),
                pw.SizedBox(height: 18),
                _pdfSectionTitle("Payment Information"),
                _pdfRow("Payment ID", paymentId),
                _pdfRow("Payment Status", paymentStatus),
                _pdfRow("Payment Type", paymentType),
                _pdfRow("Amount Paid", "Rs. $amount"),
                _pdfRow("Payment Method", paymentMethod),
                _pdfRow("Transaction ID", transactionId),
                _pdfRow("Paid At", paidAt),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    "Thank you for choosing $libName.",
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
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: "payment_receipt_$bookingId.pdf",
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to generate receipt: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
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
      drawer: AppDrawer(
        userId: widget.userId,
        name: widget.name,
        mobile: widget.mobile,
        selectedPage: "Student Profile",
        role: "STUDENT",
      ),
      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
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
            _studyAnalyticsCard(),
            const SizedBox(height: 18),
            _profileCard(),
            const SizedBox(height: 18),
            const Text(
              "Seat & Payment Information",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _activeBookingCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
