import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';
import '../services/owner_service.dart';
import '../services/session_service.dart';

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
  // =========================================================
  // DATA
  // =========================================================

  int _totalPaidStudents = 0;
  double _totalMonthCollection = 0;
  bool _hasCache = false;
  bool loadingDashboard = true;
  String? dashboardError;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  // =========================================================
  // LOAD DASHBOARD
  // =========================================================

  Future<void> loadDashboard() async {
    if (!_hasCache) {
      if (mounted) {
        setState(() {
          loadingDashboard = true;
          dashboardError = null;
        });
      }
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

      final stats = await OwnerService.getDashboardStats(token);

      if (!mounted) return;

      setState(() {
        _totalPaidStudents = (stats['totalPaidStudents'] as num).toInt();
        _totalMonthCollection = (stats['totalMonthCollection'] as num)
            .toDouble();
        _hasCache = true;
        loadingDashboard = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingDashboard = false;
        if (!_hasCache) dashboardError = e.toString();
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
        role: 'OWNER',
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
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'O',
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
          onRefresh: loadDashboard,

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
                  'Overview',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Current reading room statistics',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 16),

                // ==============================================
                // STATS
                // ==============================================
                if (dashboardError != null)
                  _errorCard()
                else
                  _ownerStatistics(),

                const SizedBox(height: 25),

                // ==============================================
                // MANAGEMENT TITLE
                // ==============================================
                const Text(
                  'Management',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),

                const SizedBox(height: 16),

                // ==============================================
                // SEARCH STUDENT BUTTON
                // ==============================================
                _featureButton(
                  icon: Icons.search_rounded,
                  title: 'Search Paid Student History',
                  subtitle: 'Search payment history by mobile number',
                  iconColor: const Color(0xFF4054C7),
                  backgroundColor: const Color(0xFFEFF1FF),
                  onTap: () => _showSearchStudent(),
                ),

                const SizedBox(height: 25),

                // ==============================================
                // INFO CARD
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
        : 'O';

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
          // DETAILS
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
                  widget.name.isNotEmpty ? widget.name : 'Owner',
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
                      Icons.admin_panel_settings_outlined,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Owner',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
  // OWNER STATISTICS
  // ===========================================================

  Widget _ownerStatistics() {
    if (loadingDashboard) return _loadingCard();

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
                      icon: Icons.verified_user_rounded,
                      title: 'Paid Students',
                      value: _totalPaidStudents.toString(),
                      description: 'Active this month',
                      iconColor: const Color(0xFF159570),
                      backgroundColor: const Color(0xFFE8F8F2),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _statCard(
                      icon: Icons.currency_rupee_rounded,
                      title: 'This Month',
                      value: '₹${_totalMonthCollection.toStringAsFixed(0)}',
                      description: 'Total collection',
                      iconColor: const Color(0xFF4054C7),
                      backgroundColor: const Color(0xFFEFF1FF),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.verified_user_rounded,
                title: 'Paid Students',
                value: _totalPaidStudents.toString(),
                description: 'Active this month',
                iconColor: const Color(0xFF159570),
                backgroundColor: const Color(0xFFE8F8F2),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _statCard(
                icon: Icons.currency_rupee_rounded,
                title: 'This Month',
                value: '₹${_totalMonthCollection.toStringAsFixed(0)}',
                description: 'Total collection',
                iconColor: const Color(0xFF4054C7),
                backgroundColor: const Color(0xFFEFF1FF),
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
  // FEATURE BUTTON
  // ===========================================================

  Widget _featureButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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

        child: Row(
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

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
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
            'Unable to load dashboard',
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
            onPressed: loadDashboard,
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
                  'Manage students, track payments, and monitor seat bookings.',
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

  // ===========================================================
  // SHOW SEARCH STUDENT BOTTOM SHEET
  // ===========================================================

  void _showSearchStudent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SearchStudentSheet(),
    );
  }
}

// =============================================================
// SEARCH STUDENT BOTTOM SHEET
// =============================================================

class _SearchStudentSheet extends StatefulWidget {
  const _SearchStudentSheet();

  @override
  State<_SearchStudentSheet> createState() => _SearchStudentSheetState();
}

class _SearchStudentSheetState extends State<_SearchStudentSheet> {
  final TextEditingController _mobileController = TextEditingController();

  List<dynamic> _history = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;
  String _searchedName = '';

  Future<void> _search() async {
    final mobile = _mobileController.text.trim();

    if (mobile.isEmpty || mobile.length != 10) {
      setState(() {
        _error = 'Please enter a valid 10-digit mobile number.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _history = [];
      _searched = false;
      _searchedName = '';
    });

    try {
      final token = await SessionService.getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Session expired. Please login again.';
          _loading = false;
        });
        return;
      }

      final result = await OwnerService.getUserPaymentHistory(token, mobile);

      setState(() {
        _history = result;
        _loading = false;
        _searched = true;
        if (result.isNotEmpty) {
          _searchedName = result[0]['name']?.toString() ?? '';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'No payment history found for this number.';
        _searched = true;
      });
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),

          child: Column(
            children: [
              // ===============================================
              // HANDLE
              // ===============================================
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ===============================================
              // HEADER
              // ===============================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF1FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF4054C7),
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172033),
                            ),
                          ),
                          Text(
                            'Search by mobile number',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ===============================================
              // SEARCH BOX
              // ===============================================
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: InputDecoration(
                          hintText: 'Enter mobile number',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4054C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                ),
              ),

              // ===============================================
              // ERROR
              // ===============================================
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),

              // ===============================================
              // RESULTS
              // ===============================================
              Expanded(
                child: _searched
                    ? _history.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _history.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _studentSummaryHeader();
                                }
                                return _historyCard(_history[index - 1]);
                              },
                            )
                    : _placeholderState(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _studentSummaryHeader() {
    if (_history.isEmpty) return const SizedBox();

    final first = _history[0];
    final name = first['name']?.toString() ?? 'Unknown';
    final mobile = first['mobile']?.toString() ?? '-';

    double total = 0;
    for (final h in _history) {
      total += double.tryParse(h['amount']?.toString() ?? '0') ?? 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4054C7), Color(0xFF6575D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  mobile,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Text(
                'Total paid',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyCard(dynamic item) {
    final bookingId = item['bookingId']?.toString() ?? '-';
    final seatId = item['seatId']?.toString() ?? '-';
    final amount = item['amount']?.toString() ?? '0';
    final paymentMethod = item['paymentMethod']?.toString() ?? '-';
    final transactionId = item['transactionId']?.toString() ?? '-';
    final paymentStatus = item['paymentStatus']?.toString() ?? '-';
    final startDate = _formatDate(item['startDate']?.toString());
    final endDate = _formatDate(item['endDate']?.toString());
    final paidAt = _formatDateTime(item['paidAt']?.toString());

    final isSuccess = paymentStatus.toUpperCase() == 'SUCCESS';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BOOKING HEADER
          Row(
            children: [
              Text(
                'Booking #$bookingId',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFFE8F8F2)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSuccess ? 'Paid' : paymentStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSuccess ? const Color(0xFF159570) : Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),

          // DETAILS
          Row(
            children: [
              Expanded(
                child: _detailItem(
                  label: 'Seat',
                  value: 'Seat $seatId',
                  icon: Icons.event_seat_rounded,
                ),
              ),
              Expanded(
                child: _detailItem(
                  label: 'Amount',
                  value: '₹$amount',
                  icon: Icons.currency_rupee_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _detailItem(
                  label: 'From',
                  value: startDate,
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              Expanded(
                child: _detailItem(
                  label: 'To',
                  value: endDate,
                  icon: Icons.calendar_month_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _detailItem(
                  label: 'Method',
                  value: paymentMethod,
                  icon: Icons.payment_rounded,
                ),
              ),
              Expanded(
                child: _detailItem(
                  label: 'Paid At',
                  value: paidAt,
                  icon: Icons.access_time_rounded,
                ),
              ),
            ],
          ),

          if (transactionId != '-' && transactionId.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.tag_rounded,
                  size: 14,
                  color: Color(0xFF4054C7),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction ID',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      transactionId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF172033),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF4054C7)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172033),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeholderState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Search a student',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Enter a 10-digit mobile number above.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No payment history found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'This student has no payment records.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final parts = dateStr.split('-');
      if (parts.length < 3) return dateStr;
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTimeStr;
    }
  }
}
