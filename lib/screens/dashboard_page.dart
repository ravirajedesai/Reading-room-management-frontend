import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';
import '../services/seat_service.dart';

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
  // DATA
  // =========================================================

  int _totalSeats = 0;
  int _availableSeats = 0;
  int _bookedSeats = 0;
  bool _hasCache = false;
  bool loadingSeats = true;
  String? seatError;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    loadSeatData();
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
      final stats = await SeatService().getSeatStats();

      if (!mounted) return;

      setState(() {
        _totalSeats = (stats['totalSeats'] as num).toInt();
        _availableSeats = (stats['availableSeats'] as num).toInt();
        _bookedSeats = (stats['bookedSeats'] as num).toInt();
        _hasCache = true;
        loadingSeats = false;
      });
    } catch (e) {
      debugPrint('DASHBOARD SEAT ERROR: $e');

      if (!mounted) return;

      setState(() {
        loadingSeats = false;
        if (!_hasCache) seatError = e.toString();
      });
    }
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
        centerTitle: false,

        title: const Text(
          'Reading Room',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF172033),
            ),
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
          onRefresh: loadSeatData,

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==============================================
                // WELCOME
                // ==============================================
                _welcomeSection(),

                const SizedBox(height: 28),

                // ==============================================
                // OVERVIEW TITLE
                // ==============================================
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

                // ==============================================
                // STATS / ERROR
                // ==============================================
                if (seatError != null) _errorCard() else _seatStatistics(),

                const SizedBox(height: 25),

                // ==============================================
                // INFORMATION CARD
                // ==============================================
                _informationCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // WELCOME SECTION
  // ===========================================================

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
          // ===================================================
          // AVATAR
          // ===================================================
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

          // ===================================================
          // USER DETAILS
          // ===================================================
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

  // ===========================================================
  // SEAT STATISTICS
  // ===========================================================

  Widget _seatStatistics() {
    if (loadingSeats) return _loadingCard();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;

        if (isSmallScreen) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.event_seat_rounded,
                      title: 'Total Seats',
                      value: _totalSeats.toString(),
                      description: 'Room capacity',
                      iconColor: const Color(0xFF4054C7),
                      backgroundColor: const Color(0xFFEFF1FF),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _statCard(
                      icon: Icons.check_circle_rounded,
                      title: 'Available',
                      value: _availableSeats.toString(),
                      description: 'Ready to book',
                      iconColor: const Color(0xFF159570),
                      backgroundColor: const Color(0xFFE8F8F2),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _statCard(
                icon: Icons.event_seat_rounded,
                title: 'Booked',
                value: _bookedSeats.toString(),
                description: 'Currently reserved',
                iconColor: Colors.orange,
                backgroundColor: const Color(0xFFFFF3E0),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.event_seat_rounded,
                title: 'Total Seats',
                value: _totalSeats.toString(),
                description: 'Room capacity',
                iconColor: const Color(0xFF4054C7),
                backgroundColor: const Color(0xFFEFF1FF),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _statCard(
                icon: Icons.check_circle_rounded,
                title: 'Available',
                value: _availableSeats.toString(),
                description: 'Ready to book',
                iconColor: const Color(0xFF159570),
                backgroundColor: const Color(0xFFE8F8F2),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _statCard(
                icon: Icons.event_seat_rounded,
                title: 'Booked',
                value: _bookedSeats.toString(),
                description: 'Currently reserved',
                iconColor: Colors.orange,
                backgroundColor: const Color(0xFFFFF3E0),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================
  // STAT CARD
  // ===========================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),

          const SizedBox(height: 15),

          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF30384D),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            description,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // LOADING CARD
  // ===========================================================

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF4054C7)),
      ),
    );
  }

  // ===========================================================
  // ERROR CARD
  // ===========================================================

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

  // ===========================================================
  // INFORMATION CARD
  // ===========================================================

  Widget _informationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF4054C7),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reading Room',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Check seat availability before making your reservation.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
