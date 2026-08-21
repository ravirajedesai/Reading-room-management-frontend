import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/booking_model.dart';
import '../models/payment_model.dart' as payment;
import '../services/payment_service.dart';
import '../screens/student_page.dart';

class PaymentPage extends StatefulWidget {
  final Booking booking;

  const PaymentPage({super.key, required this.booking});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentService _paymentService = PaymentService();
  final Razorpay _razorpay = Razorpay();

  // =========================================================
  // PAYMENT SELECTION
  // =========================================================

  payment.PaymentType _paymentType = payment.PaymentType.full;

  payment.PaymentMethod _paymentMethod = payment.PaymentMethod.online;

  // =========================================================
  // EXISTING PAYMENT
  // =========================================================

  payment.Payment? _payment;

  String? _razorpayKey;

  bool _loading = false;
  bool _checkingPayment = false;

  // =========================================================
  // BOOKING ID
  // =========================================================
  // =========================================================
  // BOOKING ID
  // =========================================================

  int get id {
    // Check both id and bookingId safely
    final bookingId = widget.booking.id ?? widget.booking.bookingId;

    if (bookingId == null) {
      throw Exception('Booking ID is missing.');
    }

    return bookingId;
  }

  // =========================================================
  // EXISTING PAYMENT CHECK
  // =========================================================

  bool get _hasExistingPayment => _payment != null;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadExistingPayment();
    _loadRazorpayKey();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // =========================================================
  // GO TO STUDENT DASHBOARD
  // =========================================================

  void _goToStudentDashboard() {
    if (!mounted) return;

    final userId = widget.booking.userId;

    if (userId == null) {
      _showError('Student user ID is missing.');
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => StudentPage(
          userId: userId,
          name: widget.booking.studentName ?? 'Student',
          mobile: widget.booking.studentMobile ?? '',
        ),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // LOAD RAZORPAY KEY
  // =========================================================

  Future<void> _loadRazorpayKey() async {
    try {
      final key = await _paymentService.getRazorpayKey();

      if (!mounted) return;

      setState(() {
        _razorpayKey = key;
      });
    } catch (e) {
      debugPrint('Failed to load Razorpay key: $e');
    }
  }

  // =========================================================
  // LOAD EXISTING PAYMENT
  // =========================================================

  Future<void> _loadExistingPayment() async {
    if (!mounted) return;

    setState(() {
      _checkingPayment = true;
    });

    try {
      final payment.Payment? existingPayment = await _paymentService
          .getPaymentByBooking(id);

      if (!mounted) return;

      // -------------------------------------------------------
      // NO PAYMENT FOUND
      // -------------------------------------------------------

      if (existingPayment == null) {
        setState(() {
          _payment = null;
        });

        return;
      }

      // -------------------------------------------------------
      // PAYMENT EXISTS
      // -------------------------------------------------------

      setState(() {
        _payment = existingPayment;

        if (existingPayment.paymentType != null) {
          _paymentType = existingPayment.paymentType!;
        }

        if (existingPayment.paymentMethod != null) {
          _paymentMethod = existingPayment.paymentMethod!;
        }
      });

      // -------------------------------------------------------
      // PAYMENT ALREADY SUCCESSFUL
      // -------------------------------------------------------

      if (existingPayment.status == payment.PaymentStatus.success) {
        return;
      }

      // -------------------------------------------------------
      // CONCESSIONAL + ONLINE + APPROVED
      // -------------------------------------------------------

      if (existingPayment.paymentType == payment.PaymentType.concessional &&
          existingPayment.paymentMethod == payment.PaymentMethod.online &&
          existingPayment.approvalStatus ==
              payment.PaymentApprovalStatus.approved &&
          existingPayment.status != payment.PaymentStatus.success) {
        _showMessage(
          'Your payment has been approved. '
          'Tap Pay Now to continue.',
        );
      }
    } catch (e) {
      debugPrint('No existing payment found: $e');

      if (!mounted) return;

      setState(() {
        _payment = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _checkingPayment = false;
        });
      }
    }
  }

  // =========================================================
  // CREATE NEW PAYMENT
  // =========================================================

  Future<void> _createPayment() async {
    if (_loading) return;

    // ---------------------------------------------------------
    // DO NOT CREATE ANOTHER PAYMENT
    // ---------------------------------------------------------

    if (_payment != null) {
      _showMessage('A payment request already exists for this booking.');
      return;
    }

    await _createPaymentFromSelection();
  }

  // =========================================================
  // CREATE PAYMENT FROM CURRENT SELECTION
  // =========================================================

  Future<void> _createPaymentFromSelection() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      final createdPayment = await _paymentService.createPayment(
        bookingId: id,
        paymentType: _paymentType.name.toUpperCase(),
        paymentMethod: _paymentMethod.name.toUpperCase(),
      );

      if (!mounted) return;

      setState(() {
        _payment = createdPayment;
      });

      // =======================================================
      // PAYMENT ALREADY SUCCESSFUL
      // =======================================================

      if (createdPayment.status == payment.PaymentStatus.success) {
        _showSuccess('Payment completed successfully.');

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        _goToStudentDashboard();

        return;
      }

      // =======================================================
      // FULL + ONLINE
      // =======================================================

      if (createdPayment.paymentType == payment.PaymentType.full &&
          createdPayment.paymentMethod == payment.PaymentMethod.online) {
        _openRazorpay(createdPayment);
        return;
      }

      // =======================================================
      // CONCESSIONAL + ONLINE
      // =======================================================

      if (createdPayment.paymentType == payment.PaymentType.concessional &&
          createdPayment.paymentMethod == payment.PaymentMethod.online) {
        _showApprovalDialog(createdPayment);
        return;
      }

      // =======================================================
      // CASH
      // =======================================================

      if (createdPayment.paymentMethod == payment.PaymentMethod.cash) {
        _showApprovalDialog(createdPayment);
        return;
      }
    } catch (e) {
      if (!mounted) return;

      _showError(_cleanException(e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =========================================================
  // CONTINUE EXISTING PAYMENT
  // =========================================================

  Future<void> _continueExistingPayment() async {
    if (_loading) return;

    final existingPayment = _payment;

    if (existingPayment == null) {
      _showError('Payment information is not available.');
      return;
    }

    if (existingPayment.paymentType == null ||
        existingPayment.paymentMethod == null) {
      _showError('Payment type or payment method is missing.');
      return;
    }

    // =======================================================
    // ALREADY SUCCESS
    // =======================================================

    if (existingPayment.status == payment.PaymentStatus.success) {
      _showSuccess('Payment has already been completed.');

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      _goToStudentDashboard();

      return;
    }

    // =======================================================
    // CONCESSIONAL + ONLINE + APPROVED
    // =======================================================

    if (existingPayment.paymentType == payment.PaymentType.concessional &&
        existingPayment.paymentMethod == payment.PaymentMethod.online &&
        existingPayment.approvalStatus ==
            payment.PaymentApprovalStatus.approved) {
      setState(() {
        _loading = true;
      });

      try {
        final updatedPayment = await _paymentService.createPayment(
          bookingId: id,
          paymentType: existingPayment.paymentType!.name.toUpperCase(),
          paymentMethod: existingPayment.paymentMethod!.name.toUpperCase(),
        );

        if (!mounted) return;

        setState(() {
          _payment = updatedPayment;
        });

        // -----------------------------------------------------
        // ALREADY SUCCESS
        // -----------------------------------------------------

        if (updatedPayment.status == payment.PaymentStatus.success) {
          _showSuccess('Payment has already been completed.');

          await Future.delayed(const Duration(milliseconds: 800));

          if (!mounted) return;

          _goToStudentDashboard();

          return;
        }

        // -----------------------------------------------------
        // RAZORPAY ORDER CHECK
        // -----------------------------------------------------

        if (updatedPayment.razorpayOrderId == null ||
            updatedPayment.razorpayOrderId!.isEmpty) {
          _showError('Razorpay order was not generated by the server.');
          return;
        }

        _openRazorpay(updatedPayment);
      } catch (e) {
        if (!mounted) return;

        _showError(_cleanException(e));
      } finally {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }

      return;
    }

    // =======================================================
    // FULL + ONLINE
    // =======================================================

    if (existingPayment.paymentType == payment.PaymentType.full &&
        existingPayment.paymentMethod == payment.PaymentMethod.online) {
      _openRazorpay(existingPayment);
      return;
    }

    // =======================================================
    // CASH
    // =======================================================

    if (existingPayment.paymentMethod == payment.PaymentMethod.cash) {
      _showMessage('Cash payment is waiting for owner approval.');
      return;
    }

    _showMessage('Payment status: ${existingPayment.statusText}');
  }

  // =========================================================
  // OPEN RAZORPAY
  // =========================================================

  void _openRazorpay(payment.Payment paymentData) {
    // ---------------------------------------------------------
    // ORDER ID
    // ---------------------------------------------------------

    final orderId = paymentData.razorpayOrderId;

    if (orderId == null || orderId.isEmpty) {
      _showError('Razorpay order ID was not generated by the server.');
      return;
    }

    // ---------------------------------------------------------
    // AMOUNT
    // ---------------------------------------------------------

    final amount = paymentData.amount;

    if (amount == null) {
      _showError('Payment amount is missing.');
      return;
    }

    // ---------------------------------------------------------
    // RAZORPAY KEY
    // ---------------------------------------------------------

    if (_razorpayKey == null || _razorpayKey!.isEmpty) {
      _showError(
        'Unable to load payment configuration. '
        'Please try again.',
      );
      return;
    }

    // ---------------------------------------------------------
    // RAZORPAY OPTIONS
    // ---------------------------------------------------------

    final options = {
      'key': _razorpayKey,

      // Razorpay expects amount in paise.
      'amount': (amount * 100).round(),

      'name': 'Study Room',

      'description': paymentData.paymentTypeText,

      'order_id': orderId,

      'theme': {'color': '#1976D2'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showError('Unable to open Razorpay: $e');
    }
  }

  // =========================================================
  // RAZORPAY SUCCESS
  // =========================================================

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('======================================');

    debugPrint('RAZORPAY PAYMENT SUCCESS');

    debugPrint('Payment ID: ${response.paymentId}');

    debugPrint('Order ID: ${response.orderId}');

    debugPrint('Signature: ${response.signature}');

    debugPrint('======================================');

    if (response.paymentId == null ||
        response.orderId == null ||
        response.signature == null) {
      _showError('Razorpay returned incomplete payment information.');
      return;
    }

    _verifyRazorpayPayment(
      paymentId: response.paymentId!,
      orderId: response.orderId!,
      signature: response.signature!,
    );
  }

  // =========================================================
  // VERIFY RAZORPAY PAYMENT
  // =========================================================

  Future<void> _verifyRazorpayPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final verifiedPayment = await _paymentService.verifyPayment(
        bookingId: id,
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      if (!mounted) return;

      setState(() {
        _payment = verifiedPayment;
      });

      // =======================================================
      // PAYMENT SUCCESS
      // =======================================================

      if (verifiedPayment.status == payment.PaymentStatus.success) {
        _showSuccess('Payment successful. Your seat is now active.');

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        // =====================================================
        // GO TO STUDENT PAGE
        // =====================================================

        _goToStudentDashboard();

        return;
      }

      // =======================================================
      // VERIFICATION FAILED
      // =======================================================

      _showError('Payment verification did not complete.');
    } catch (e) {
      if (!mounted) return;

      _showError(_cleanException(e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =========================================================
  // RAZORPAY ERROR
  // =========================================================

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('======================================');

    debugPrint('RAZORPAY PAYMENT ERROR');

    debugPrint('Code: ${response.code}');

    debugPrint('Message: ${response.message}');

    debugPrint('======================================');

    _showError(response.message ?? 'Payment was cancelled or failed.');
  }

  // =========================================================
  // EXTERNAL WALLET
  // =========================================================

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showMessage(
      'External wallet selected: '
      '${response.walletName ?? 'Unknown wallet'}',
    );
  }

  // =========================================================
  // APPROVAL DIALOG
  // =========================================================

  void _showApprovalDialog(payment.Payment paymentData) {
    String title;
    String message;

    // =======================================================
    // CASH
    // =======================================================

    if (paymentData.paymentMethod == payment.PaymentMethod.cash) {
      title = 'Waiting for Approval';

      message =
          'Your cash payment request has been '
          'submitted to the owner.\n\n'
          'Please wait for owner approval.';
    }
    // =======================================================
    // CONCESSIONAL ONLINE
    // =======================================================
    else {
      title = 'Waiting for Approval';

      message =
          'Your concessional payment request has '
          'been submitted to the owner.\n\n'
          'Once approved, you will be able to pay '
          'directly through Razorpay.';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // CHECK APPROVAL
  // =========================================================

  Future<void> _checkApproval() async {
    if (_checkingPayment) return;

    setState(() {
      _checkingPayment = true;
    });

    try {
      final payment.Payment? paymentData = await _paymentService
          .getPaymentByBooking(id);

      if (!mounted) return;

      // =======================================================
      // NO PAYMENT
      // =======================================================

      if (paymentData == null) {
        setState(() {
          _payment = null;
        });

        _showMessage('No payment request found.');

        return;
      }

      // =======================================================
      // SAVE PAYMENT
      // =======================================================

      setState(() {
        _payment = paymentData;

        if (paymentData.paymentType != null) {
          _paymentType = paymentData.paymentType!;
        }

        if (paymentData.paymentMethod != null) {
          _paymentMethod = paymentData.paymentMethod!;
        }
      });

      // =======================================================
      // SUCCESS
      // =======================================================

      if (paymentData.status == payment.PaymentStatus.success) {
        _showSuccess('Payment completed successfully.');

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        _goToStudentDashboard();

        return;
      }

      // =======================================================
      // REJECTED
      // =======================================================

      if (paymentData.approvalStatus ==
          payment.PaymentApprovalStatus.rejected) {
        _showError('Your payment request was rejected by the owner.');
        return;
      }

      // =======================================================
      // CONCESSIONAL + ONLINE + APPROVED
      // =======================================================

      if (paymentData.paymentType == payment.PaymentType.concessional &&
          paymentData.paymentMethod == payment.PaymentMethod.online &&
          paymentData.approvalStatus ==
              payment.PaymentApprovalStatus.approved) {
        _showMessage('Payment approved. Preparing Razorpay...');

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        await _continueExistingPayment();

        return;
      }

      // =======================================================
      // CASH + APPROVED
      // =======================================================

      if (paymentData.paymentMethod == payment.PaymentMethod.cash &&
          paymentData.approvalStatus ==
              payment.PaymentApprovalStatus.approved) {
        _showSuccess('Cash payment approved by the owner.');
        return;
      }

      // =======================================================
      // PENDING
      // =======================================================

      if (paymentData.approvalStatus == payment.PaymentApprovalStatus.pending) {
        _showMessage('Payment is still waiting for owner approval.');
        return;
      }

      // =======================================================
      // OTHER STATUS
      // =======================================================

      _showMessage('Payment status: ${paymentData.statusText}');
    } catch (e) {
      if (!mounted) return;

      _showError(_cleanException(e));
    } finally {
      if (mounted) {
        setState(() {
          _checkingPayment = false;
        });
      }
    }
  }

  // =========================================================
  // PAYMENT TYPE
  // =========================================================

  Widget _buildPaymentTypeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // -------------------------------------------------
            // FULL
            // -------------------------------------------------
            RadioListTile<payment.PaymentType>(
              title: const Text('Full Payment'),
              subtitle: const Text('Regular monthly fee'),
              value: payment.PaymentType.full,
              groupValue: _paymentType,
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _paymentType = value;
                      });
                    },
            ),

            // -------------------------------------------------
            // CONCESSIONAL
            // -------------------------------------------------
            RadioListTile<payment.PaymentType>(
              title: const Text('Concessional Payment'),
              subtitle: const Text('Requires owner approval'),
              value: payment.PaymentType.concessional,
              groupValue: _paymentType,
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _paymentType = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PAYMENT METHOD
  // =========================================================

  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // -------------------------------------------------
            // ONLINE
            // -------------------------------------------------
            RadioListTile<payment.PaymentMethod>(
              title: const Text('Online Payment'),
              subtitle: Text(
                _paymentType == payment.PaymentType.concessional
                    ? 'Requires owner approval first'
                    : 'Pay securely using Razorpay',
              ),
              value: payment.PaymentMethod.online,
              groupValue: _paymentMethod,
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _paymentMethod = value;
                      });
                    },
            ),

            // -------------------------------------------------
            // CASH
            // -------------------------------------------------
            RadioListTile<payment.PaymentMethod>(
              title: const Text('Cash Payment'),
              subtitle: const Text('Requires owner approval'),
              value: payment.PaymentMethod.cash,
              groupValue: _paymentMethod,
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _paymentMethod = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EXISTING PAYMENT
  // =========================================================

  Widget _buildExistingPayment() {
    final payment.Payment? currentPayment = _payment;

    if (currentPayment == null) {
      return const SizedBox.shrink();
    }

    final paymentData = currentPayment;

    final bool isSuccess = paymentData.status == payment.PaymentStatus.success;

    // ---------------------------------------------------------
    // CONCESSIONAL + ONLINE + APPROVED
    // ---------------------------------------------------------

    final bool isApprovedOnline =
        paymentData.paymentType == payment.PaymentType.concessional &&
        paymentData.paymentMethod == payment.PaymentMethod.online &&
        paymentData.approvalStatus == payment.PaymentApprovalStatus.approved &&
        !isSuccess;

    // ---------------------------------------------------------
    // CASH APPROVED
    // ---------------------------------------------------------

    final bool isApprovedCash =
        paymentData.paymentMethod == payment.PaymentMethod.cash &&
        paymentData.approvalStatus == payment.PaymentApprovalStatus.approved &&
        !isSuccess;

    // ---------------------------------------------------------
    // PENDING
    // ---------------------------------------------------------

    final bool isPending =
        paymentData.approvalStatus == payment.PaymentApprovalStatus.pending &&
        !isSuccess;

    // ---------------------------------------------------------
    // REJECTED
    // ---------------------------------------------------------

    final bool isRejected =
        paymentData.approvalStatus == payment.PaymentApprovalStatus.rejected;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // =================================================
            // AMOUNT
            // =================================================
            _infoRow(
              'Amount',
              paymentData.amount == null
                  ? 'N/A'
                  : '₹${paymentData.amount!.toStringAsFixed(2)}',
            ),

            // =================================================
            // TYPE
            // =================================================
            _infoRow('Type', paymentData.paymentTypeText),

            // =================================================
            // METHOD
            // =================================================
            _infoRow('Method', paymentData.paymentMethodText),

            // =================================================
            // STATUS
            // =================================================
            _infoRow('Status', paymentData.statusText),

            // =================================================
            // APPROVAL
            // =================================================
            _infoRow('Approval', paymentData.approvalStatusText),

            // =================================================
            // TRANSACTION ID
            // =================================================
            if (paymentData.transactionId != null)
              _infoRow('Transaction ID', paymentData.transactionId!),

            // =================================================
            // RAZORPAY ORDER
            // =================================================
            if (paymentData.razorpayOrderId != null)
              _infoRow('Razorpay Order', paymentData.razorpayOrderId!),

            const SizedBox(height: 12),

            // =================================================
            // SUCCESS
            // =================================================
            if (isSuccess)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Payment completed successfully.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // =================================================
            // APPROVED ONLINE
            // =================================================
            if (isApprovedOnline)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Payment approved by owner. '
                            'You can now pay directly.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _continueExistingPayment,
                      icon: const Icon(Icons.payment),
                      label: const Text('Pay Now'),
                    ),
                  ),
                ],
              ),

            // =================================================
            // APPROVED CASH
            // =================================================
            if (isApprovedCash)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_rounded, color: Colors.orange.shade800),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cash payment approved by owner. '
                        'Please complete the cash payment.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // =================================================
            // PENDING APPROVAL
            // =================================================
            if (isPending)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your payment request is waiting '
                            'for owner approval.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _checkingPayment ? null : _checkApproval,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _checkingPayment
                            ? 'Checking...'
                            : 'Check Approval Status',
                      ),
                    ),
                  ),
                ],
              ),

            // =================================================
            // REJECTED
            // =================================================
            if (isRejected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel_rounded, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Your payment request was rejected '
                        'by the owner.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Make Payment')),

      body: _checkingPayment && _payment == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // =========================================
                  // BOOKING INFORMATION
                  // =========================================
                  Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // =================================
                          // SEAT ICON
                          // =================================
                          Container(
                            height: 58,
                            width: 58,
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.event_seat_rounded,
                              size: 32,
                              color: Colors.indigo,
                            ),
                          ),

                          const SizedBox(width: 14),

                          // =================================
                          // SEAT INFORMATION
                          // =================================
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Selected Seat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                if (widget.booking.seatNumber != null)
                                  Text(
                                    'Seat ${widget.booking.seatNumber}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  )
                                else
                                  const Text(
                                    'Seat not assigned',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // =================================
                          // SEAT STATUS
                          // =================================
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'SELECTED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================================
                  // EXISTING PAYMENT
                  // =========================================
                  _buildExistingPayment(),

                  // =========================================
                  // NEW PAYMENT SELECTION
                  // =========================================
                  if (!_hasExistingPayment) ...[
                    const SizedBox(height: 16),

                    _buildPaymentTypeSection(),

                    const SizedBox(height: 12),

                    _buildPaymentMethodSection(),

                    const SizedBox(height: 20),

                    // =======================================
                    // CREATE PAYMENT
                    // =======================================
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _createPayment,
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _paymentMethod == payment.PaymentMethod.online
                                    ? 'Continue to Payment'
                                    : 'Submit Cash Request',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =======================================
                    // PAYMENT INFORMATION
                    // =======================================
                    Card(
                      color: Colors.grey.shade100,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Information',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            SizedBox(height: 8),

                            Text(
                              '• Full + Online: Pay immediately using Razorpay.\n'
                              '• Full + Cash: Owner approval is required.\n'
                              '• Concessional + Online: Owner approval is required first.\n'
                              '• Concessional + Cash: Owner approval is required.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // =========================================================
  // SUCCESS MESSAGE
  // =========================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // =========================================================
  // NORMAL MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // =========================================================
  // CLEAN EXCEPTION
  // =========================================================

  String _cleanException(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }

    return text;
  }
}
