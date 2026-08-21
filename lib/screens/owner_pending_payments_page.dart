import 'package:flutter/material.dart';

import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../widgets/app_drawer.dart';

class OwnerPendingPaymentsPage extends StatefulWidget {
  final int userId;
  final String name;
  final String mobile;
  final String role;

  const OwnerPendingPaymentsPage({
    super.key,
    required this.userId,
    required this.name,
    required this.mobile,
    required this.role,
  });

  @override
  State<OwnerPendingPaymentsPage> createState() =>
      _OwnerPendingPaymentsPageState();
}

class _OwnerPendingPaymentsPageState extends State<OwnerPendingPaymentsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PaymentService _paymentService = PaymentService();

  List<Payment> _payments = [];
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

    _loadPendingPayments();
  }

  Future<void> _loadPendingPayments() async {
    if (!isOwner) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final payments = await _paymentService.getPendingPaymentRequests();

      if (!mounted) return;

      setState(() {
        _payments = payments;
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

  Future<void> _approvePayment(Payment payment) async {
    final paymentId = payment.id;
    if (paymentId == null) {
      _showMessage('Payment request ID is missing.', isError: true);
      return;
    }

    final studentName = payment.studentName?.trim().isNotEmpty == true
        ? payment.studentName!.trim()
        : 'Student';

    final seatNumber = payment.seatNumber?.trim().isNotEmpty == true
        ? payment.seatNumber!.trim()
        : '-';

    final confirmed = await _showConfirmationDialog(
      title: 'Approve Request?',
      message:
          'Approve the seat request from $studentName for Seat $seatNumber?',
      confirmText: 'Approve',
    );

    if (!confirmed) return;

    _showLoadingDialog('Approving request...');

    try {
      await _paymentService.approvePayment(paymentId: paymentId);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage('Payment request approved successfully.');
      await _loadPendingPayments();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage(_cleanError(e), isError: true);
    }
  }

  Future<void> _rejectPayment(Payment payment) async {
    final paymentId = payment.id;
    if (paymentId == null) {
      _showMessage('Payment request ID is missing.', isError: true);
      return;
    }

    final studentName = payment.studentName?.trim().isNotEmpty == true
        ? payment.studentName!.trim()
        : 'Student';

    final seatNumber = payment.seatNumber?.trim().isNotEmpty == true
        ? payment.seatNumber!.trim()
        : '-';

    final confirmed = await _showConfirmationDialog(
      title: 'Reject Request?',
      message:
          'Reject the seat request from $studentName for Seat $seatNumber?',
      confirmText: 'Reject',
      isDanger: true,
    );

    if (!confirmed) return;

    _showLoadingDialog('Rejecting request...');

    try {
      await _paymentService.rejectPayment(paymentId: paymentId);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage('Payment request rejected.');
      await _loadPendingPayments();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage(_cleanError(e), isError: true);
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDanger
                    ? Colors.red
                    : const Color(0xFF4054C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Row(
            children: [
              const SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 18),
              Expanded(child: Text(message)),
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
          backgroundColor: isError ? Colors.red : Colors.green,
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

  Widget _paymentCard(Payment payment) {
    final studentName = payment.studentName?.trim().isNotEmpty == true
        ? payment.studentName!.trim()
        : 'Unknown Student';

    final seatNumber = payment.seatNumber?.trim().isNotEmpty == true
        ? payment.seatNumber!.trim()
        : '-';

    final amount = payment.amount;
    final isPending = payment.approvalStatus == PaymentApprovalStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF4054C7),
                    size: 27,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payment request',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(payment),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF1FF), Color(0xFFF6F7FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFDDE1FF)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4054C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_seat_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seat Requested',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Seat $seatNumber',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172033),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: Color(0xFF4054C7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    icon: Icons.currency_rupee_rounded,
                    title: 'Amount',
                    value: amount == null
                        ? '-'
                        : '₹${amount.toStringAsFixed(0)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _detailItem(
                    icon: Icons.category_outlined,
                    title: 'Type',
                    value: payment.paymentTypeText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Method',
                    value: payment.paymentMethodText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _detailItem(
                    icon: Icons.access_time_rounded,
                    title: 'Requested',
                    value: payment.createdAt == null
                        ? '-'
                        : _formatDate(payment.createdAt!),
                  ),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectPayment(payment),
                      icon: const Icon(Icons.close_rounded, size: 19),
                      label: const Text(
                        'Reject',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approvePayment(payment),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 19,
                      ),
                      label: const Text(
                        'Approve',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4054C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF4054C7)),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
      ),
    );
  }

  Widget _statusBadge(Payment payment) {
    Color background;
    Color foreground;
    String text;

    switch (payment.approvalStatus) {
      case PaymentApprovalStatus.pending:
        background = Colors.orange.shade50;
        foreground = Colors.orange.shade800;
        text = 'PENDING';
        break;
      case PaymentApprovalStatus.approved:
        background = Colors.green.shade50;
        foreground = Colors.green.shade800;
        text = 'APPROVED';
        break;
      case PaymentApprovalStatus.rejected:
        background = Colors.red.shade50;
        foreground = Colors.red.shade800;
        text = 'REJECTED';
        break;
      default:
        background = Colors.grey.shade100;
        foreground = Colors.grey.shade700;
        text = payment.approvalStatusText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Widget _emptyState() {
    return RefreshIndicator(
      color: const Color(0xFF4054C7),
      onRefresh: _loadPendingPayments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.24),
          Container(
            height: 82,
            width: 82,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF1FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 42,
              color: Color(0xFF4054C7),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'No Pending Payment Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'New student payment requests\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load payment requests',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadPendingPayments,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4054C7),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Requests')),
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
      backgroundColor: const Color(0xFFF6F7FB),
      drawer: AppDrawer(
        userId: widget.userId,
        name: widget.name,
        mobile: widget.mobile,
        selectedPage: 'Pending Payment Requests',
        role: widget.role,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded, size: 27),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text(
          'Pending Payment Requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadPendingPayments,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4054C7)),
            )
          : _errorMessage != null
          ? _errorState()
          : _payments.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              color: const Color(0xFF4054C7),
              onRefresh: _loadPendingPayments,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                itemCount: _payments.length,
                itemBuilder: (context, index) {
                  return _paymentCard(_payments[index]);
                },
              ),
            ),
    );
  }
}
