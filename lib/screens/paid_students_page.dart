import 'package:flutter/material.dart';

import '../services/owner_service.dart';
import '../services/session_service.dart';
import '../widgets/app_drawer.dart';

class PaidStudentsPage extends StatefulWidget {
  final int userId;
  final String name;
  final String mobile;
  final String role;

  const PaidStudentsPage({
    super.key,
    required this.userId,
    required this.name,
    required this.mobile,
    required this.role,
  });

  @override
  State<PaidStudentsPage> createState() => _PaidStudentsPageState();
}

class _PaidStudentsPageState extends State<PaidStudentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _allStudents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =============================================================
  // LOAD PAID STUDENTS
  // =============================================================
  Future<void> _loadStudents() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await SessionService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Session expired. Please login again.';
        });
        return;
      }

      final dynamic rawResult = await OwnerService.getPaidStudents(
        token,
        ownerId: widget.userId,
      );

      List<dynamic> fetchedList = [];
      if (rawResult is List) {
        fetchedList = rawResult;
      } else if (rawResult is Map && rawResult['content'] is List) {
        fetchedList = rawResult['content'];
      }

      if (!mounted) return;

      setState(() {
        _allStudents = fetchedList;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('PAID STUDENTS ERROR: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load paid students.';
      });
    }
  }

  // =============================================================
  // FILTER HELPERS
  // =============================================================
  List<dynamic> get _onlineStudents => _allStudents.where((s) {
    final method = (s['paymentMethod'] ?? '').toString().toUpperCase();
    final type = (s['paymentType'] ?? '').toString().toUpperCase();
    return method == 'ONLINE' && type != 'CONCESSIONAL';
  }).toList();

  List<dynamic> get _cashStudents => _allStudents.where((s) {
    final method = (s['paymentMethod'] ?? '').toString().toUpperCase();
    return method == 'CASH';
  }).toList();

  List<dynamic> get _concessionStudents => _allStudents.where((s) {
    final type = (s['paymentType'] ?? '').toString().toUpperCase();
    return type == 'CONCESSIONAL' || type == 'CONCESSION';
  }).toList();

  // =============================================================
  // BUILD
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      drawer: AppDrawer(
        userId: widget.userId,
        name: widget.name,
        mobile: widget.mobile,
        selectedPage: 'Paid Students',
        role: widget.role,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 1,
        shadowColor: Colors.black12,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu_rounded, size: 27),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Paid Students',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadStudents,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
        // =======================================================
        // 4 FILTER TABS
        // =======================================================
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF4054C7),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF4054C7),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'All (${_allStudents.length})'),
            Tab(text: 'Online (${_onlineStudents.length})'),
            Tab(text: 'Cash (${_cashStudents.length})'),
            Tab(text: 'Concession (${_concessionStudents.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4054C7)),
            )
          : _error != null
          ? _errorView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStudentList(_allStudents, 'No paid students found'),
                _buildStudentList(
                  _onlineStudents,
                  'No online paid students found',
                ),
                _buildStudentList(_cashStudents, 'No cash paid students found'),
                _buildStudentList(
                  _concessionStudents,
                  'No concessional students found',
                ),
              ],
            ),
    );
  }

  // =============================================================
  // LIST BUILDER FOR TAB
  // =============================================================
  Widget _buildStudentList(List<dynamic> list, String emptyMessage) {
    if (list.isEmpty) {
      return _emptyView(emptyMessage);
    }

    return RefreshIndicator(
      color: const Color(0xFF4054C7),
      onRefresh: _loadStudents,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _studentCard(list[index]);
        },
      ),
    );
  }

  // =============================================================
  // STUDENT CARD WITH CATEGORY BADGES
  // =============================================================
  Widget _studentCard(dynamic student) {
    final String name =
        (student['userName'] ??
                student['studentName'] ??
                student['name'] ??
                'Unknown')
            .toString()
            .trim();

    final String mobile =
        (student['mobile'] ??
                student['studentMobile'] ??
                student['userMobile'] ??
                '-')
            .toString()
            .trim();

    final String userId = (student['userId'] ?? student['user_id'] ?? '-')
        .toString();
    final String bookingId = (student['bookingId'] ?? student['id'] ?? '-')
        .toString();
    final String seatNumber =
        (student['seatNumber'] ?? student['seatId'] ?? '-').toString();
    final String amount = (student['amount'] ?? '0').toString();

    final String paymentMethod = (student['paymentMethod'] ?? 'ONLINE')
        .toString()
        .toUpperCase();
    final String paymentType = (student['paymentType'] ?? 'FULL')
        .toString()
        .toUpperCase();

    final String startDate = _formatDate(student['startDate']?.toString());
    final String endDate = _formatDate(student['endDate']?.toString());
    final String paidAt = _formatDateTime(
      student['paidAt']?.toString() ?? student['createdAt']?.toString(),
    );

    final bool isCash = paymentMethod == 'CASH';
    final bool isConcession =
        paymentType == 'CONCESSIONAL' || paymentType == 'CONCESSION';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: isConcession
                    ? Colors.purple.shade50
                    : isCash
                    ? Colors.orange.shade50
                    : const Color(0xFFE8F8F2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: TextStyle(
                    color: isConcession
                        ? Colors.purple
                        : isCash
                        ? Colors.orange.shade800
                        : const Color(0xFF159570),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mobile,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Payment Method Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCash
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCash ? '💵 CASH' : '💳 ONLINE',
                      style: TextStyle(
                        color: isCash
                            ? Colors.orange.shade800
                            : Colors.blue.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Concession Badge
                  if (isConcession) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🎓 CONCESSION',
                        style: TextStyle(
                          color: Colors.purple.shade800,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 14),

          // User ID & Booking ID
          Row(
            children: [
              Expanded(
                child: _detailItem(
                  icon: Icons.person_outline_rounded,
                  label: 'User ID',
                  value: userId,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _detailItem(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Booking ID',
                  value: bookingId,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          // Seat Number & Amount
          Row(
            children: [
              Expanded(
                child: _detailItem(
                  icon: Icons.event_seat_rounded,
                  label: 'Seat Number',
                  value: 'Seat $seatNumber',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _detailItem(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Amount Paid',
                  value: '₹$amount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          // Validity From / Until
          Row(
            children: [
              Expanded(
                child: _detailItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'From',
                  value: startDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _detailItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Valid Until',
                  value: endDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          // Paid At
          _detailItem(
            icon: Icons.access_time_rounded,
            label: 'Paid At',
            value: paidAt,
          ),
        ],
      ),
    );
  }

  // =============================================================
  // DETAIL ITEM HELPER
  // =============================================================
  Widget _detailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF4054C7)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172033),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =============================================================
  // EMPTY & ERROR VIEWS
  // =============================================================
  Widget _emptyView(String message) {
    return RefreshIndicator(
      color: const Color(0xFF4054C7),
      onRefresh: _loadStudents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Icon(
            Icons.people_outline_rounded,
            size: 65,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              'No records in this category.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 55, color: Colors.red.shade300),
            const SizedBox(height: 15),
            const Text(
              'Unable to load paid students',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _error ?? 'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadStudents,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4054C7),
                foregroundColor: Colors.white,
                elevation: 0,
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

  // =============================================================
  // FORMATTERS
  // =============================================================
  String _formatDate(String? date) {
    if (date == null || date.trim().isEmpty) return '-';
    try {
      final parsed = DateTime.parse(date.trim());
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.trim().isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateTime.trim());
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} '
          '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTime;
    }
  }
}
