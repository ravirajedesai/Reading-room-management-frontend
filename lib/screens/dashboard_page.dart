import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';
import '../services/seat_service.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../services/booking_service.dart';
import '../models/booking_model.dart';
import 'pomodoro_page.dart';
import '../services/study_tracker_service.dart';

class DashboardPage extends StatefulWidget {
  final int userId;
  final String name;
  final String mobile;

  const DashboardPage({
    super.key,
    required this.userId,
    required this.name,
    required this.mobile,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // =========================================================
  // READING ROOM FEES
  // =========================================================

  static const String monthlyFee = '₹1,000';
  static const String concessionFee = '₹700';

  // =========================================================
  // SERVICES
  // =========================================================

  final SeatService _seatService = SeatService();
  final BookingService _bookingService = BookingService();
  final PaymentService _paymentService = PaymentService();

  // =========================================================
  // SEAT DATA
  // =========================================================

  int _totalSeats = 0;
  int _availableSeats = 0;
  int _bookedSeats = 0;

  bool _hasCache = false;
  bool loadingSeats = true;

  String? seatError;

  // =========================================================
  // PAYMENT NOTIFICATION
  // =========================================================
  //
  // Notification is shown ONLY when:
  //
  // approvalStatus == APPROVED
  // OR
  // approvalStatus == REJECTED
  //
  // PENDING / NOT_REQUIRED are ignored.
  // =========================================================

  String _activeLibraryName = 'Reading Room';
  String? _activeLibraryAddress;

  Payment? _paymentNotification;

  bool loadingNotification = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadDashboardData();
  }

  // =========================================================
  // LOAD COMPLETE DASHBOARD
  // =========================================================

  Future<void> _loadLibraryInfo() async {
    final name = await SessionService.getActiveLibraryName();
    final address = await SessionService.getActiveLibraryAddress();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() {
        _activeLibraryName = name;
        _activeLibraryAddress = address;
      });
    }
  }

  Future<void> loadDashboardData() async {
    await Future.wait([_loadLibraryInfo(), loadSeatData(), loadPaymentNotification()]);
  }

  // =========================================================
  // LOAD SEAT STATS
  // =========================================================

  Future<void> loadSeatData() async {
    if (!_hasCache) {
      if (mounted) {
        setState(() {
          loadingSeats = true;
          seatError = null;
        });
      }
    }

    try {
      final stats = await _seatService.getSeatStats();

      if (!mounted) return;

      setState(() {
        _totalSeats = _parseNumber(stats['totalSeats']);
        _availableSeats = _parseNumber(stats['availableSeats']);
        _bookedSeats = _parseNumber(stats['bookedSeats']);

        _hasCache = true;
        loadingSeats = false;
        seatError = null;
      });
    } catch (e) {
      debugPrint('DASHBOARD SEAT ERROR: $e');

      if (!mounted) return;

      setState(() {
        loadingSeats = false;

        if (!_hasCache) {
          seatError = e.toString();
        }
      });
    }
  }

  // =========================================================
  // LOAD PAYMENT NOTIFICATION
  // =========================================================
  //
  // FLOW:
  //
  // 1. Get student's current booking.
  // 2. Get payment for that booking.
  // 3. Check approvalStatus.
  // 4. Show notification ONLY for APPROVED / REJECTED.
  //
  // =========================================================

  Future<void> loadPaymentNotification() async {
    if (mounted) {
      setState(() {
        loadingNotification = true;
      });
    }

    try {
      // -------------------------------------------------------
      // GET CURRENT BOOKING
      // -------------------------------------------------------

      final Booking? booking = await _bookingService.getMyBooking();

      // No booking -> no notification.
      if (booking == null || booking.id == null) {
        if (!mounted) return;

        setState(() {
          _paymentNotification = null;
          loadingNotification = false;
        });

        return;
      }

      // -------------------------------------------------------
      // GET PAYMENT
      // -------------------------------------------------------

      final Payment? payment = await _paymentService.getPaymentByBooking(
        booking.id!,
      );

      // -------------------------------------------------------
      // ONLY APPROVED / REJECTED
      // -------------------------------------------------------

      if (payment == null) {
        if (!mounted) return;

        setState(() {
          _paymentNotification = null;
          loadingNotification = false;
        });

        return;
      }

      final approvalStatus = payment.approvalStatus;

      if (approvalStatus == PaymentApprovalStatus.approved ||
          approvalStatus == PaymentApprovalStatus.rejected) {
        if (!mounted) return;

        setState(() {
          _paymentNotification = payment;
          loadingNotification = false;
        });

        debugPrint('PAYMENT NOTIFICATION: ${payment.approvalStatusText}');

        return;
      }

      // -------------------------------------------------------
      // PENDING / NOT REQUIRED
      //
      // No notification.
      // -------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _paymentNotification = null;
        loadingNotification = false;
      });
    } catch (e) {
      debugPrint('PAYMENT NOTIFICATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        _paymentNotification = null;
        loadingNotification = false;
      });
    }
  }

  // =========================================================
  // NUMBER PARSER
  // =========================================================

  int _parseNumber(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // =====================================================
      // DRAWER
      // =====================================================
      drawer: AppDrawer(
        userId: widget.userId,
        name: widget.name,
        mobile: widget.mobile,
        selectedPage: 'Dashboard',
        role: 'STUDENT',
      ),

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LibrarySelectionPage()),
            ).then((_) => _loadLibraryInfo());
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF4054C7)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _activeLibraryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF4054C7)),
                  ],
                ),
                if (_activeLibraryAddress != null && _activeLibraryAddress!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Text(
                      _activeLibraryAddress!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        actions: [
          // =================================================
          // NOTIFICATION BELL
          // =================================================
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _showNotifications,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF172033),
                ),
              ),

              // ------------------------------------------------
              // RED DOT
              //
              // Only shown when APPROVED / REJECTED exists.
              // ------------------------------------------------
              if (_paymentNotification != null)
                Positioned(
                  right: 8,
                  top: 7,
                  child: Container(
                    height: 9,
                    width: 9,
                    decoration: BoxDecoration(
                      color: _notificationColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 5),

          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFE8ECFF),
              child: Text(
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Color(0xFF4054C7),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadDashboardData,
          color: const Color(0xFF4054C7),

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 35),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // WELCOME
                // =================================================
                _welcomeSection(),

                const SizedBox(height: 18),
                _pomodoroHeroBanner(),

                const SizedBox(height: 26),

                // =================================================
                // ROOM OVERVIEW
                // =================================================
                const Text(
                  'Seat Overview',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Current reading room availability',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 16),

                if (seatError != null) _errorCard() else _seatStatistics(),

                const SizedBox(height: 28),

                // =================================================
                // FEES
                // =================================================
                _feesSection(),

                const SizedBox(height: 28),

                // =================================================
                // FACILITIES
                // =================================================
                _facilitiesSection(),

                const SizedBox(height: 28),

                // =================================================
                // READING ROOM HIGHLIGHT
                // =================================================
                _readingRoomHighlight(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // NOTIFICATION COLOR
  // =============================================================

  Color get _notificationColor {
    if (_paymentNotification?.approvalStatus ==
        PaymentApprovalStatus.approved) {
      return const Color(0xFF159570);
    }

    if (_paymentNotification?.approvalStatus ==
        PaymentApprovalStatus.rejected) {
      return Colors.red;
    }

    return Colors.transparent;
  }

  // =============================================================
  // SHOW NOTIFICATIONS
  // =============================================================

  void _showNotifications() {
    final payment = _paymentNotification;

    // ---------------------------------------------------------
    // No approved/rejected notification
    // ---------------------------------------------------------

    if (payment == null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF4054C7),
                    size: 30,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'No Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'You have no payment approval or rejection notifications.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );

      return;
    }

    // ---------------------------------------------------------
    // PAYMENT DECISION
    // ---------------------------------------------------------

    final bool approved =
        payment.approvalStatus == PaymentApprovalStatus.approved;

    final Color statusColor = approved ? const Color(0xFF159570) : Colors.red;

    final Color statusBackground = approved
        ? const Color(0xFFE8F8F2)
        : const Color(0xFFFFEEEE);

    final IconData statusIcon = approved
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    final String title = approved ? 'Payment Accepted' : 'Payment Rejected';

    final String message = approved
        ? 'Your payment request has been approved by the owner.'
        : 'Your payment request has been rejected by the owner.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // HANDLE
              // =================================================
              Center(
                child: Container(
                  height: 5,
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // =================================================
              // HEADER
              // =================================================
              Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: statusBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 29),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'Payment Notification',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =================================================
              // MESSAGE
              // =================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.45,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // PAYMENT DETAILS
              // =================================================
              _notificationDetailRow(
                icon: Icons.currency_rupee_rounded,
                title: 'Amount',
                value: payment.amount != null
                    ? '₹${payment.amount!.toStringAsFixed(2)}'
                    : 'Not Available',
              ),

              const SizedBox(height: 10),

              _notificationDetailRow(
                icon: Icons.payment_rounded,
                title: 'Payment Type',
                value: payment.paymentTypeText,
              ),

              const SizedBox(height: 10),

              _notificationDetailRow(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Payment Method',
                value: payment.paymentMethodText,
              ),

              const SizedBox(height: 10),

              _notificationDetailRow(
                icon: Icons.verified_rounded,
                title: 'Approval',
                value: payment.approvalStatusText,
              ),

              if (payment.seatNumber != null) ...[
                const SizedBox(height: 10),

                _notificationDetailRow(
                  icon: Icons.event_seat_rounded,
                  title: 'Seat',
                  value: payment.seatNumber!,
                ),
              ],

              const SizedBox(height: 22),

              // =================================================
              // CLOSE
              // =================================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4054C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =============================================================
  // NOTIFICATION DETAIL ROW
  // =============================================================

  Widget _notificationDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF4054C7)),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),

        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // WELCOME SECTION
  // =============================================================

  Widget _welcomeSection() {
    final firstLetter = widget.name.isNotEmpty
        ? widget.name.substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4054C7), Color(0xFF6575D6)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back 👋',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.name.isNotEmpty ? widget.name : 'User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: Colors.white70,
                    ),

                    const SizedBox(width: 5),

                    Flexible(
                      child: Text(
                        widget.mobile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // POMODORO HERO BANNER
  // =============================================================

  Widget _pomodoroHeroBanner() {
    return FutureBuilder<int>(
      future: StudyTrackerService.getTodayStudyMinutes(),
      builder: (context, snapshot) {
        final todayMins = snapshot.data ?? 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF312E81).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Pomodoro Focus Mode',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Today: ${StudyTrackerService.formatMinutesToHours(todayMins)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Boost your daily study retention with 25-minute distraction-free focus cycles.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.3),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await PomodoroPage.open(context);
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text(
                    'START FOCUS SESSION (25M)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF312E81),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =============================================================
  // SEAT STATISTICS
  // =============================================================

  Widget _seatStatistics() {
    if (loadingSeats) {
      return _loadingCard();
    }

    return Row(
      children: [
        Expanded(
          child: _smallStatCard(
            icon: Icons.event_seat_rounded,
            title: 'Total',
            value: _totalSeats.toString(),
            iconColor: const Color(0xFF4054C7),
            backgroundColor: const Color(0xFFEFF1FF),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _smallStatCard(
            icon: Icons.check_circle_rounded,
            title: 'Available',
            value: _availableSeats.toString(),
            iconColor: const Color(0xFF159570),
            backgroundColor: const Color(0xFFE8F8F2),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _smallStatCard(
            icon: Icons.event_seat_rounded,
            title: 'Booked',
            value: _bookedSeats.toString(),
            iconColor: Colors.orange,
            backgroundColor: const Color(0xFFFFF3E0),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // SMALL STAT CARD
  // =============================================================

  Widget _smallStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // FEES SECTION
  // =============================================================

  Widget _feesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Membership Plans',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'Choose the plan that suits your study needs.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: _feeCard(
                title: 'Monthly Fee',
                amount: monthlyFee,
                subtitle: 'Regular membership',
                icon: Icons.workspace_premium_rounded,
                gradient: const [Color(0xFF4054C7), Color(0xFF6575D6)],
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _feeCard(
                title: 'Concession',
                amount: concessionFee,
                subtitle: 'Special discounted fee',
                icon: Icons.discount_rounded,
                gradient: const [Color(0xFF159570), Color(0xFF42B883)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =============================================================
  // FEE CARD
  // =============================================================

  Widget _feeCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),

          const SizedBox(height: 13),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // FACILITIES SECTION
  // =============================================================

  Widget _facilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Facilities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'Everything you need for a comfortable study environment.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 15),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _facilityItem(
                      icon: Icons.ac_unit_rounded,
                      title: 'Air Conditioned',
                      subtitle: 'Comfortable study',
                      iconColor: const Color(0xFF4054C7),
                      backgroundColor: const Color(0xFFEFF1FF),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _facilityItem(
                      icon: Icons.wifi_rounded,
                      title: '24 hrs Wi-Fi',
                      subtitle: 'High-speed internet',
                      iconColor: const Color(0xFF159570),
                      backgroundColor: const Color(0xFFE8F8F2),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _facilityItem(
                      icon: Icons.water_drop_rounded,
                      title: 'Water Purifier',
                      subtitle: 'Clean drinking water',
                      iconColor: const Color(0xFF2980B9),
                      backgroundColor: const Color(0xFFEAF5FC),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _facilityItem(
                      icon: Icons.wc_rounded,
                      title: 'Separate Washroom',
                      subtitle: 'Convenient facilities',
                      iconColor: const Color(0xFF8E44AD),
                      backgroundColor: const Color(0xFFF5EAF9),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _facilityItem(
                      icon: Icons.restaurant_rounded,
                      title: 'Lunch & Dinner',
                      subtitle: 'Dedicated space',
                      iconColor: const Color(0xFFE67E22),
                      backgroundColor: const Color(0xFFFFF1E5),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _facilityItem(
                      icon: Icons.groups_rounded,
                      title: 'Group Discussion',
                      subtitle: 'Separate discussion area',
                      iconColor: const Color(0xFF16A085),
                      backgroundColor: const Color(0xFFE8F7F4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================
  // FACILITY ITEM
  // =============================================================

  Widget _facilityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 39,
            width: 39,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // READING ROOM HIGHLIGHT
  // =============================================================

  Widget _readingRoomHighlight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF172033),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A Better Place to Study',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Study peacefully with comfortable seating, '
                  'reliable internet and dedicated spaces for '
                  'your daily needs.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // LOADING CARD
  // =============================================================

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF4054C7)),
      ),
    );
  }

  // =============================================================
  // ERROR CARD
  // =============================================================

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Colors.red,
              size: 30,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Unable to load seat information',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(
            'Please check your internet connection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: loadSeatData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
