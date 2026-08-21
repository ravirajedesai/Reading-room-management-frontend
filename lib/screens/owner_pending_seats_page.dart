import 'package:flutter/material.dart';

import '../services/owner_service.dart';
import '../services/session_service.dart';
import '../widgets/app_drawer.dart';

class OwnerPendingSeatsPage extends StatefulWidget {
  final int userId;
  final String name;
  final String mobile;
  final String role;

  const OwnerPendingSeatsPage({
    super.key,
    required this.userId,
    required this.name,
    required this.mobile,
    required this.role,
  });

  @override
  State<OwnerPendingSeatsPage> createState() => _OwnerPendingSeatsPageState();
}

class _OwnerPendingSeatsPageState extends State<OwnerPendingSeatsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _pendingSeats = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get isOwner => widget.role.trim().toUpperCase() == 'OWNER';

  @override
  void initState() {
    super.initState();

    if (!isOwner) {
      _isLoading = false;
      _errorMessage = 'Access denied. Owner access only.';
      return;
    }

    _loadPendingSeats();
  }

  // =============================================================
  // LOAD & ENRICH PENDING SEATS
  // =============================================================

  Future<void> _loadPendingSeats() async {
    if (!isOwner) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final token = await SessionService.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired. Please login again.';
        });
        return;
      }

      // 1. Fetch raw pending bookings
      final rawSeats = await OwnerService.getPendingBookings(
        token,
        widget.userId,
      );

      // 2. Fetch student directory to enrich missing names & mobiles
      Map<int, Map<String, String>> studentMap = {};
      try {
        final paidStudents = await OwnerService.getPaidStudents(
          token,
          ownerId: widget.userId,
        );
        if (paidStudents is List) {
          for (var s in paidStudents) {
            final uId = (s['userId'] as num?)?.toInt();
            final uName = s['userName']?.toString() ?? s['name']?.toString();
            final uMob = s['mobile']?.toString();
            if (uId != null && uName != null) {
              studentMap[uId] = {'name': uName, 'mobile': uMob ?? '-'};
            }
          }
        }
      } catch (_) {}

      // 3. Merge data
      List<Map<String, dynamic>> enriched = [];
      for (var item in rawSeats) {
        final map = Map<String, dynamic>.from(item as Map);
        final uId = (map['userId'] as num?)?.toInt();

        if (map['userName'] == null &&
            map['studentName'] == null &&
            map['name'] == null) {
          if (uId != null && studentMap.containsKey(uId)) {
            map['userName'] = studentMap[uId]?['name'];
            map['mobile'] = studentMap[uId]?['mobile'];
          }
        }

        if (map['seatNumber'] == null && map['seatId'] != null) {
          map['seatNumber'] = map['seatId'];
        }

        enriched.add(map);
      }

      if (!mounted) return;
      setState(() {
        _pendingSeats = enriched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // =============================================================
  // RELEASE / CANCEL BLOCKED SEAT ACTION
  // =============================================================

  Future<void> _releaseBlockedSeat(Map<String, dynamic> booking) async {
    final bookingId = (booking['bookingId'] ?? booking['id'] as num?)?.toInt();
    final seatNumber = (booking['seatNumber'] ?? booking['seatId'] ?? '-')
        .toString();
    final studentName =
        (booking['userName'] ??
                booking['name'] ??
                booking['studentName'] ??
                'Student')
            .toString();

    if (bookingId == null) {
      _showMessage('Booking ID is missing', isError: true);
      return;
    }

    // 1. Confirm dialog
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
                  Icons.lock_open_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Release Seat Hold?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to release Seat $seatNumber reserved by $studentName?\n\nThis will cancel the hold and make the seat available for other students immediately.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
                'Release Seat',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // 2. Show loading dialog
    _showLoadingDialog('Releasing seat hold...');

    try {
      final token = await SessionService.getToken();
      if (token == null || token.isEmpty) throw 'Session expired.';

      // Calls your OwnerService.removePendingBooking
      await OwnerService.removePendingBooking(token, widget.userId, bookingId);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      _showMessage('Seat $seatNumber has been released successfully.');
      await _loadPendingSeats(); // Refresh list immediately
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
                  color: Color(0xFF3B50DF),
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

  // =============================================================
  // DATE & TIME FORMATTERS
  // =============================================================

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr).toLocal();
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year;
      final hourInt = parsed.hour;
      final hour = hourInt > 12
          ? (hourInt - 12).toString().padLeft(2, '0')
          : (hourInt == 0 ? '12' : hourInt.toString().padLeft(2, '0'));
      final minute = parsed.minute.toString().padLeft(2, '0');
      final period = hourInt >= 12 ? 'PM' : 'AM';
      return '$day/$month/$year $hour:$minute $period';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year;
      return '$day/$month/$year';
    } catch (_) {
      return dateStr;
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    if (!isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Blocked Seats')),
        body: const Center(
          child: Text(
            'Access denied. Owner access only.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: AppDrawer(
        userId: widget.userId,
        name: widget.name,
        mobile: widget.mobile,
        selectedPage: 'Pending Seats',
        role: widget.role,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded, size: 26),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Blocked / Pending Seats',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadPendingSeats,
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF3B50DF)),
              )
            : _errorMessage != null
            ? _buildErrorState()
            : _pendingSeats.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                color: const Color(0xFF3B50DF),
                onRefresh: _loadPendingSeats,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  itemCount: _pendingSeats.length,
                  itemBuilder: (context, index) {
                    return _seatCard(_pendingSeats[index]);
                  },
                ),
              ),
      ),
    );
  }

  // =============================================================
  // SEAT CARD WITH RELEASE ACTION
  // =============================================================

  Widget _seatCard(Map<String, dynamic> item) {
    final seatNumber = (item['seatNumber'] ?? item['seatId'] ?? '-').toString();

    String studentName = 'Student';
    if (item['userName'] != null &&
        item['userName'].toString().trim().isNotEmpty) {
      studentName = item['userName'].toString().trim();
    } else if (item['studentName'] != null &&
        item['studentName'].toString().trim().isNotEmpty) {
      studentName = item['studentName'].toString().trim();
    } else if (item['name'] != null &&
        item['name'].toString().trim().isNotEmpty) {
      studentName = item['name'].toString().trim();
    }

    String mobileNumber = '-';
    if (item['mobile'] != null && item['mobile'].toString().trim().isNotEmpty) {
      mobileNumber = item['mobile'].toString().trim();
    } else if (item['studentMobile'] != null &&
        item['studentMobile'].toString().trim().isNotEmpty) {
      mobileNumber = item['studentMobile'].toString().trim();
    } else if (item['userMobile'] != null &&
        item['userMobile'].toString().trim().isNotEmpty) {
      mobileNumber = item['userMobile'].toString().trim();
    }

    final blockedDateTime = _formatDateTime(item['createdAt']?.toString());
    final startDate = _formatDate(item['startDate']?.toString());
    final endDate = _formatDate(item['endDate']?.toString());
    final deadline = _formatDateTime(item['paymentDeadline']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================================================
            // HEADER: SEAT NUMBER & HOLD BADGE
            // ===================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE4FF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_seat_rounded,
                        color: Color(0xFF3B50DF),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Seat $seatNumber',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3B50DF),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_clock_rounded,
                        color: Color(0xFFEF4444),
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'HOLD / PENDING',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ===================================================
            // STUDENT DETAILS
            // ===================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE2E8F0),
                    child: Text(
                      studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_android_rounded,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              mobileNumber != '-'
                                  ? mobileNumber
                                  : 'Mobile not available',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: mobileNumber != '-'
                                    ? const Color(0xFF334155)
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===================================================
            // DATES
            // ===================================================
            _infoTile(
              label: 'Blocked On (Date & Time)',
              value: blockedDateTime,
              icon: Icons.access_time_filled_rounded,
              iconColor: const Color(0xFF3B50DF),
            ),
            const SizedBox(height: 8),
            _infoTile(
              label: 'Booking Period',
              value: '$startDate to $endDate',
              icon: Icons.calendar_month_rounded,
              iconColor: const Color(0xFF10B981),
            ),

            if (deadline != '-') ...[
              const SizedBox(height: 8),
              _infoTile(
                label: 'Payment Deadline',
                value: deadline,
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFFEF4444),
              ),
            ],

            const SizedBox(height: 16),

            // ===================================================
            // OWNER ACTION: RELEASE SEAT BUTTON
            // ===================================================
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _releaseBlockedSeat(item),
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text(
                  'Release / Cancel Hold',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                  backgroundColor: const Color(0xFFFEF2F2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: const Color(0xFF3B50DF),
      onRefresh: _loadPendingSeats,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Container(
            height: 76,
            width: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_seat_rounded,
              size: 38,
              color: Color(0xFF3B50DF),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'No Blocked / Pending Seats',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'All seats are either active or freely available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load pending seats',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadPendingSeats,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B50DF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
