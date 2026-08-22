import 'package:flutter/material.dart';

import '../services/owner_service.dart';
import '../services/session_service.dart';
import '../widgets/app_drawer.dart';

class PaymentHistoryPage extends StatefulWidget {
  // =============================================================
  // USER DETAILS
  // =============================================================

  final int userId;
  final String name;
  final String mobile;
  final String role;

  const PaymentHistoryPage({
    super.key,
    required this.userId,
    required this.name,
    required this.mobile,
    required this.role,
  });

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  // =============================================================
  // CONTROLLER
  // =============================================================

  final TextEditingController _mobileController = TextEditingController();

  // =============================================================
  // DATA
  // =============================================================

  List<dynamic> _history = [];

  bool _loading = false;
  bool _searched = false;

  String? _error;

  String _searchedName = '';
  String _searchedMobile = '';

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    // Do not automatically search.
    // Owner can enter any student's mobile number.
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  // =============================================================
  // SEARCH PAYMENT HISTORY
  // =============================================================

  Future<void> _search() async {
    final mobile = _mobileController.text.trim();

    // -----------------------------------------------------------
    // VALIDATION
    // -----------------------------------------------------------

    if (mobile.isEmpty || mobile.length != 10) {
      setState(() {
        _error = 'Please enter a valid 10-digit mobile number.';
        _history = [];
        _searched = false;
        _searchedName = '';
        _searchedMobile = '';
      });

      return;
    }

    // -----------------------------------------------------------
    // HIDE KEYBOARD
    // -----------------------------------------------------------

    FocusScope.of(context).unfocus();

    // -----------------------------------------------------------
    // START LOADING
    // -----------------------------------------------------------

    setState(() {
      _loading = true;
      _error = null;

      _history = [];

      _searched = false;

      _searchedName = '';
      _searchedMobile = mobile;
    });

    try {
      // ---------------------------------------------------------
      // GET SESSION TOKEN
      // ---------------------------------------------------------

      final token = await SessionService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _error = 'Session expired. Please login again.';
        });

        return;
      }

      // ---------------------------------------------------------
      // API CALL
      // ---------------------------------------------------------

      final result = await OwnerService.getUserPaymentHistory(token, mobile);

      if (!mounted) return;

      // ---------------------------------------------------------
      // CONVERT RESULT
      // ---------------------------------------------------------

      final List<dynamic> history = List<dynamic>.from(result);

      // ---------------------------------------------------------
      // GET STUDENT NAME
      // ---------------------------------------------------------

      String searchedName = 'Unknown';

      if (history.isNotEmpty) {
        final firstItem = history.first;

        if (firstItem is Map) {
          searchedName = firstItem['name']?.toString().trim().isNotEmpty == true
              ? firstItem['name'].toString()
              : 'Unknown';
        }
      }

      // ---------------------------------------------------------
      // SUCCESS
      // ---------------------------------------------------------

      setState(() {
        _history = history;

        _loading = false;

        _searched = true;

        _searchedName = searchedName;

        _searchedMobile = mobile;

        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;

        _searched = true;

        _history = [];

        _searchedName = '';

        _searchedMobile = mobile;

        _error = 'No payment history found for this number.';
      });
    }
  }

  // =============================================================
  // CLEAR SEARCH
  // =============================================================

  void _clearSearch() {
    _mobileController.clear();

    FocusScope.of(context).unfocus();

    setState(() {
      _history = [];

      _searched = false;

      _loading = false;

      _error = null;

      _searchedName = '';

      _searchedMobile = '';
    });
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // =========================================================
      // DRAWER
      // =========================================================
      drawer: AppDrawer(
        userId: widget.userId,
        name: widget.name,
        mobile: widget.mobile,
        selectedPage: 'Search Payment History',
        role: widget.role,
      ),

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        centerTitle: false,

        // -------------------------------------------------------
        // MENU BUTTON
        // -------------------------------------------------------
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded, size: 27),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),

        // -------------------------------------------------------
        // TITLE
        // -------------------------------------------------------
        title: const Text(
          'Search Payment History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),

        // -------------------------------------------------------
        // CLEAR BUTTON
        // -------------------------------------------------------
        actions: [
          if (_searched || _mobileController.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: _loading ? null : _clearSearch,
              icon: const Icon(Icons.clear_rounded),
            ),
          const SizedBox(width: 4),
        ],
      ),

      // =========================================================
      // BODY
      // =========================================================
      body: SafeArea(
        child: Column(
          children: [
            _searchSection(),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SEARCH SECTION
  // =============================================================

  Widget _searchSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------------------------------------
          // TITLE
          // -----------------------------------------------------
          const Text(
            'Search Student',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 5),

          // -----------------------------------------------------
          // DESCRIPTION
          // -----------------------------------------------------
          Text(
            'Enter the student mobile number to view complete payment history.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 14),

          // -----------------------------------------------------
          // INPUT + SEARCH BUTTON
          // -----------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  enabled: !_loading,
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() {
                        _error = null;
                      });
                    }
                  },
                  onSubmitted: (_) {
                    if (!_loading) {
                      _search();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter mobile number',
                    counterText: '',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF6F7FB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF4054C7),
                        width: 1.2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // -------------------------------------------------
              // SEARCH BUTTON
              // -------------------------------------------------
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4054C7),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF9AA3D5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    elevation: 0,
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

          // -----------------------------------------------------
          // ERROR
          // -----------------------------------------------------
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =============================================================
  // RESULTS
  // =============================================================

  Widget _buildResults() {
    if (!_searched) {
      return _placeholderState();
    }

    if (_history.isEmpty) {
      return _emptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF4054C7),
      onRefresh: _search,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        itemCount: _history.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _studentSummary();
          }

          return _historyCard(_history[index - 1]);
        },
      ),
    );
  }

  // =============================================================
  // STUDENT SUMMARY
  // =============================================================

  Widget _studentSummary() {
    double total = 0;

    for (final item in _history) {
      if (item is Map) {
        total += double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4054C7), Color(0xFF6575D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.20),
            child: Text(
              _searchedName.isNotEmpty ? _searchedName[0].toUpperCase() : 'S',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _searchedName.isNotEmpty ? _searchedName : 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _searchedMobile,
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
              const SizedBox(height: 3),
              Text(
                '${_history.length} payment${_history.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================
  // PAYMENT CARD
  // =============================================================

  Widget _historyCard(dynamic item) {
    if (item is! Map) {
      return const SizedBox.shrink();
    }

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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Booking #$bookingId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFFE8F8F2)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSuccess ? 'PAID' : paymentStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? const Color(0xFF159570) : Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Divider(color: Colors.grey.shade100, height: 1),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _detailItem(
                  icon: Icons.event_seat_rounded,
                  label: 'Seat',
                  value: 'Seat $seatId',
                ),
              ),
              Expanded(
                child: _detailItem(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Amount',
                  value: '₹$amount',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _detailItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'From',
                  value: startDate,
                ),
              ),
              Expanded(
                child: _detailItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Valid Until',
                  value: endDate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _detailItem(
                  icon: Icons.payment_rounded,
                  label: 'Method',
                  value: paymentMethod,
                ),
              ),
              Expanded(
                child: _detailItem(
                  icon: Icons.access_time_rounded,
                  label: 'Paid At',
                  value: paidAt,
                ),
              ),
            ],
          ),

          if (transactionId != '-' && transactionId.isNotEmpty) ...[
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.tag_rounded,
                  size: 15,
                  color: Color(0xFF4054C7),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction ID',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        transactionId,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // =============================================================
  // DETAIL ITEM
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
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
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
  // PLACEHOLDER
  // =============================================================

  Widget _placeholderState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF1FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 34,
                color: Color(0xFF4054C7),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Search a student',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Enter a 10-digit mobile number above\n'
              'to view payment history.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // EMPTY STATE
  // =============================================================

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 34,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No payment history found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'No payment records were found\n'
              'for $_searchedMobile.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Search Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4054C7),
                side: const BorderSide(color: Color(0xFF4054C7)),
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
  // FORMAT DATE
  // =============================================================

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return '-';
    }

    try {
      final parts = date.split('-');

      if (parts.length != 3) {
        return date;
      }

      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return date;
    }
  }

  // =============================================================
  // FORMAT DATE TIME
  // =============================================================

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    try {
      final dt = DateTime.parse(value);

      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }
}
