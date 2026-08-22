import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';
import '../services/owner_service.dart';
import '../services/session_service.dart';

import '../screens/paid_students_page.dart';
import '../screens/owner_pending_payments_page.dart';
import '../screens/owner_pending_seats_page.dart';
import '../models/seat_model.dart';
import '../services/seat_service.dart';
import '../services/library_service.dart';

class OwnerDashboardPage extends StatefulWidget {
  final int userId;
  final String name;
  final String mobile;

  const OwnerDashboardPage({
    super.key,
    required this.userId,
    required this.name,
    required this.mobile,
  });

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  // Total capacity of the reading room
  static const int totalSeatCapacity = 100;

  int _totalPaidStudents = 0;
  double _totalMonthCollection = 0.0;
  double _cashCollection = 0.0;
  int _pendingPaymentRequests = 0;
  int _pendingSeats = 0;

  List<Seat> _seats = [];
  bool _loadingSeats = false;
  String _seatFilter = 'ALL';

  bool loadingDashboard = true;
  bool _hasCache = false;
  String? dashboardError;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    if (!_hasCache) {
      if (!mounted) return;
      setState(() {
        loadingDashboard = true;
        dashboardError = null;
      });
    }

    try {
      final token = await SessionService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          loadingDashboard = false;
          dashboardError = 'Session expired. Please login again.';
        });
        return;
      }

      // Ensure active library is set for this Owner
      var activeLibId = await SessionService.getActiveLibraryId();
      if (activeLibId == null) {
        try {
          final myLibs = await LibraryService.getMyLibraries();
          if (myLibs.isNotEmpty) {
            activeLibId = myLibs.first.id;
            await SessionService.saveActiveLibraryId(activeLibId);
          }
        } catch (e) {
          debugPrint('OWNER ACTIVE LIB FETCH ERROR: $e');
        }
      }

      // Execute all 4 API calls concurrently in PARALLEL for maximum speed
      final results = await Future.wait([
        OwnerService.getDashboardStats(token).catchError((e) {
          debugPrint('DASHBOARD STATS ERROR: $e');
          return <String, dynamic>{};
        }),
        OwnerService.getPendingPaymentRequests(token, widget.userId).catchError((e) {
          debugPrint('PENDING PAYMENTS ERROR: $e');
          return <dynamic>[];
        }),
        OwnerService.getPendingBookings(token, widget.userId).catchError((e) {
          debugPrint('PENDING SEATS ERROR: $e');
          return <dynamic>[];
        }),
        SeatService().getAllSeats().catchError((e) {
          debugPrint('SEATS LOAD ERROR: $e');
          return <Seat>[];
        }),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final pendingPayments = results[1] as List<dynamic>;
      final pendingBookings = results[2] as List<dynamic>;
      final seats = results[3] as List<Seat>;

      if (stats.isNotEmpty) {
        _totalPaidStudents = (stats['totalPaidStudents'] as num?)?.toInt() ?? 0;
        _totalMonthCollection =
            (stats['totalMonthCollection'] as num?)?.toDouble() ?? 0.0;
        _cashCollection = (stats['cashCollection'] as num?)?.toDouble() ?? 0.0;
      }

      _pendingPaymentRequests = pendingPayments.length;
      _pendingSeats = pendingBookings.length;
      if (seats.isNotEmpty) {
        _seats = seats;
      }

      if (!mounted) return;
      setState(() {
        _hasCache = true;
        loadingDashboard = false;
        dashboardError = null;
      });
    } catch (e) {
      debugPrint('OWNER DASHBOARD ERROR: $e');
      if (!mounted) return;
      setState(() {
        loadingDashboard = false;
        if (!_hasCache) {
          dashboardError = 'Unable to load dashboard.';
        }
      });
    }
  }

  void _openPaidStudents() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaidStudentsPage(
          userId: widget.userId,
          name: widget.name,
          mobile: widget.mobile,
          role: 'OWNER',
        ),
      ),
    );
  }



  Future<void> _openPendingPaymentRequests() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerPendingPaymentsPage(
          userId: widget.userId,
          name: widget.name,
          mobile: widget.mobile,
          role: 'OWNER',
        ),
      ),
    );
    await loadDashboard();
  }

  Future<void> _openPendingSeats() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerPendingSeatsPage(
          userId: widget.userId,
          name: widget.name,
          mobile: widget.mobile,
          role: 'OWNER',
        ),
      ),
    );
    await loadDashboard();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: AppDrawer(
        userId: widget.userId,
        name: widget.name,
        mobile: widget.mobile,
        selectedPage: 'Dashboard',
        role: 'OWNER',
      ),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF3B50DF),
          onRefresh: loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting
                _buildHeader(),
                const SizedBox(height: 16),

                // Error / Loading / Content State
                if (dashboardError != null)
                  _buildErrorCard()
                else if (loadingDashboard && !_hasCache)
                  _buildLoadingCard()
                else ...[
                  // Hero Revenue Card
                  _buildRevenueHeroCard(),
                  const SizedBox(height: 14),

                  // Booked Seats Card
                  _buildBookedSeatsCard(),
                  const SizedBox(height: 20),

                  // Operational Section Header
                  const Text(
                    'Operational Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Equal Height Metrics Grid
                  _buildMetricsGrid(),
                  const SizedBox(height: 24),

                  // LIVE SEAT STRUCTURE & OCCUPANCY MAP
                  _buildSeatStructureSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // APP BAR
  // ===========================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        tooltip: 'Menu',
        icon: const Icon(Icons.menu_rounded, size: 26),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      titleSpacing: 0,
      title: const Text(
        'Reading Room',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        // Notification Pill
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                tooltip: 'Pending Requests',
                onPressed: () {
                  if (_pendingPaymentRequests > 0) {
                    _openPendingPaymentRequests();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No pending payment requests'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF334155),
                  size: 22,
                ),
              ),
            ),
            if (_pendingPaymentRequests > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$_pendingPaymentRequests',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // User Avatar
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              widget.name.trim().isNotEmpty
                  ? widget.name.trim()[0].toUpperCase()
                  : 'O',
              style: const TextStyle(
                color: Color(0xFF3B50DF),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // HEADER
  // ===========================================================

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.name.isNotEmpty ? widget.name : 'Owner'} 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Here is your library performance summary',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDE4FF)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 13, color: Color(0xFF3B50DF)),
              SizedBox(width: 4),
              Text(
                'Owner',
                style: TextStyle(
                  color: Color(0xFF3B50DF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // HERO REVENUE CARD
  // ===========================================================

  Widget _buildRevenueHeroCard() {
    final double onlineCollection = (_totalMonthCollection - _cashCollection)
        .clamp(0.0, double.infinity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3EC4), Color(0xFF4358E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B50DF).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Monthly Collection',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'This Month',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '₹${_totalMonthCollection.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: Color(0xFFFBBF24),
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cash',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '₹${_cashCollection.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_rounded,
                        color: Color(0xFF34D399),
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Digital / UPI',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '₹${onlineCollection.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // BOOKED SEATS CARD (REPLACES ROOM OCCUPANCY)
  // ===========================================================

  Widget _buildBookedSeatsCard() {
    final double bookedRatio = (_totalPaidStudents / totalSeatCapacity).clamp(
      0.0,
      1.0,
    );
    final int availableSeats = (totalSeatCapacity - _totalPaidStudents).clamp(
      0,
      totalSeatCapacity,
    );

    return InkWell(
      onTap: _openPaidStudents,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_seat_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booked Seats',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$_totalPaidStudents out of $totalSeatCapacity booked',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$_totalPaidStudents / $totalSeatCapacity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: bookedRatio,
                minHeight: 7,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '● $_totalPaidStudents Booked',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
                Text(
                  '● $availableSeats Available',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // METRICS GRID (INTRINSIC HEIGHT ALIGNED)
  // ===========================================================

  Widget _buildMetricsGrid() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pending Payments Card
          Expanded(
            child: _buildActionableCard(
              title: 'Payment Requests',
              subtitle: _pendingPaymentRequests > 0
                  ? 'Action Required'
                  : 'All cleared',
              count: '$_pendingPaymentRequests',
              icon: Icons.pending_actions_rounded,
              accentColor: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFFFBEB),
              hasUrgency: _pendingPaymentRequests > 0,
              onTap: _openPendingPaymentRequests,
            ),
          ),
          const SizedBox(width: 12),

          // Pending Seats Card
          Expanded(
            child: _buildActionableCard(
              title: 'Pending Seats',
              subtitle: _pendingSeats > 0 ? 'Seats on hold' : 'No hold seats',
              count: '$_pendingSeats',
              icon: Icons.hourglass_top_rounded,
              accentColor: const Color(0xFFEF4444),
              bgColor: const Color(0xFFFEF2F2),
              hasUrgency: _pendingSeats > 0,
              onTap: _openPendingSeats,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableCard({
    required String title,
    required String subtitle,
    required String count,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required bool hasUrgency,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasUrgency
                  ? accentColor.withOpacity(0.5)
                  : const Color(0xFFE2E8F0),
              width: hasUrgency ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: hasUrgency
                    ? accentColor.withOpacity(0.08)
                    : Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  if (hasUrgency)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'REVIEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: hasUrgency ? accentColor : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // LIVE SEAT STRUCTURE & OCCUPANCY MAP
  // ===========================================================

  Widget _buildSeatStructureSection() {
    final availableCount = _seats.where((s) => s.isAvailable).length;
    final bookedCount = _seats.where((s) => s.isBooked).length;
    final pendingCount = _seats.where((s) => s.isPending).length;

    List<Seat> filteredSeats = _seats;
    if (_seatFilter == 'AVAILABLE') {
      filteredSeats = _seats.where((s) => s.isAvailable).toList();
    } else if (_seatFilter == 'BOOKED') {
      filteredSeats = _seats.where((s) => s.isBooked).toList();
    } else if (_seatFilter == 'PENDING') {
      filteredSeats = _seats.where((s) => s.isPending).toList();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Refresh Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Color(0xFF3B50DF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Seat Structure',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Visual room layout & occupancy',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF3B50DF)),
                tooltip: 'Refresh Seats',
                onPressed: () async {
                  setState(() => _loadingSeats = true);
                  try {
                    final seats = await SeatService().getAllSeats();
                    if (mounted) setState(() => _seats = seats);
                  } catch (e) {
                    debugPrint('Refresh error: $e');
                  } finally {
                    if (mounted) setState(() => _loadingSeats = false);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Status Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Available', const Color(0xFF10B981), availableCount),
                _buildLegendItem('Booked', const Color(0xFFEF4444), bookedCount),
                _buildLegendItem('On Hold', const Color(0xFFF59E0B), pendingCount),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All (${_seats.length})', 'ALL'),
                const SizedBox(width: 8),
                _buildFilterChip('Available ($availableCount)', 'AVAILABLE'),
                const SizedBox(width: 8),
                _buildFilterChip('Booked ($bookedCount)', 'BOOKED'),
                const SizedBox(width: 8),
                _buildFilterChip('Hold ($pendingCount)', 'PENDING'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grid View
          if (_loadingSeats)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3B50DF)),
              ),
            )
          else if (filteredSeats.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: Text(
                'No seats found in this filter.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSeats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final seat = filteredSeats[index];
                return _buildSeatTile(seat);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $count',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _seatFilter == value;
    return InkWell(
      onTap: () => setState(() => _seatFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B50DF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSeatTile(Seat seat) {
    Color borderColor;
    Color bgColor;
    Color textColor;
    IconData icon;

    if (seat.isBooked) {
      borderColor = const Color(0xFFFCA5A5);
      bgColor = const Color(0xFFFEF2F2);
      textColor = const Color(0xFFDC2626);
      icon = Icons.lock_outline_rounded;
    } else if (seat.isPending) {
      borderColor = const Color(0xFFFDE68A);
      bgColor = const Color(0xFFFFFBEB);
      textColor = const Color(0xFFD97706);
      icon = Icons.hourglass_empty_rounded;
    } else {
      borderColor = const Color(0xFFA7F3D0);
      bgColor = const Color(0xFFF0FDF4);
      textColor = const Color(0xFF059669);
      icon = Icons.event_seat_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(height: 2),
          Text(
            '${seat.seatNumber}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // LOADING STATE
  // ===========================================================

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF3B50DF), strokeWidth: 3),
          SizedBox(height: 14),
          Text(
            'Syncing dashboard data...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // ERROR STATE
  // ===========================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFEF4444),
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load dashboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dashboardError ?? 'Please check your internet connection.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: loadDashboard,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B50DF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
