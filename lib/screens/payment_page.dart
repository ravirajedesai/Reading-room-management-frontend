import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/booking_model.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../widgets/app_drawer.dart';
import 'student_page.dart';

class PaymentPage extends StatefulWidget {
  final int userId;
  final String name;
  final String mobile;
  final Booking booking;

  const PaymentPage({
    super.key,
    required this.userId,
    required this.name,
    required this.mobile,
    required this.booking,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentService paymentService = PaymentService();

  late Razorpay razorpay;

  bool loading = false;

  Payment? payment;

  // =========================================================
  // MONTHLY FEE
  // =========================================================

  static const double monthlyFee = 10.0;

  // =========================================================
  // RAZORPAY TEST KEY ID
  // =========================================================
  //
  // IMPORTANT:
  // Only use the KEY ID here.
  //
  // NEVER put Razorpay KEY SECRET inside Flutter.
  //
  // Example:
  // rzp_test_xxxxxxxxxxxxx
  // =========================================================

  static const String razorpayKeyId = 'rzp_test_TOyevuHqvMI5Xk';

  @override
  void initState() {
    super.initState();

    razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    debugPrint('RAZORPAY INITIALIZED');
  }

  @override
  void dispose() {
    razorpay.clear();
    super.dispose();
  }

  // =========================================================
  // CREATE PAYMENT
  // =========================================================

  Future<void> createPayment() async {
    if (loading) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      debugPrint('========================================');
      debugPrint('STARTING PAYMENT');
      debugPrint('User ID: ${widget.userId}');
      debugPrint('Booking ID: ${widget.booking.id}');
      debugPrint('Seat ID: ${widget.booking.seatId}');
      debugPrint('========================================');

      // -----------------------------------------------------
      // CREATE RAZORPAY ORDER THROUGH SPRING BOOT
      // -----------------------------------------------------

      final Payment result = await paymentService.createPayment(
        userId: widget.userId,
        bookingId: widget.booking.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        payment = result;
      });

      debugPrint('========================================');
      debugPrint('PAYMENT CREATED SUCCESSFULLY');
      debugPrint('Payment ID: ${result.id}');
      debugPrint('Razorpay Order ID: ${result.razorpayOrderId}');
      debugPrint('Payment Amount: ${result.amount}');
      debugPrint('Payment Status: ${result.status}');
      debugPrint('========================================');

      // =====================================================
      // VALIDATE RAZORPAY KEY
      // =====================================================

      if (razorpayKeyId.isEmpty) {
        throw Exception(
          'Razorpay Key ID is empty. Please configure the test key.',
        );
      }

      if (!razorpayKeyId.startsWith('rzp_test_')) {
        throw Exception('Invalid Razorpay TEST Key ID.');
      }

      // =====================================================
      // GET ORDER ID
      // =====================================================

      final String? orderId = result.razorpayOrderId;

      if (orderId == null || orderId.trim().isEmpty) {
        throw Exception('Razorpay Order ID was not received from the server.');
      }

      // =====================================================
      // VALIDATE AMOUNT
      // =====================================================

      final double amount = result.amount;

      if (amount <= 0) {
        throw Exception('Invalid payment amount received from server: $amount');
      }

      // =====================================================
      // RAZORPAY AMOUNT
      // =====================================================
      //
      // Assuming Payment.amount from your backend is in RUPEES.
      //
      // Example:
      //
      // ₹10 = 1000 paise
      // ₹100 = 10000 paise
      //
      // If your backend Payment.amount is already in paise,
      // DO NOT multiply by 100 here.
      // =====================================================

      final int amountInPaise = (amount * 100).round();

      if (amountInPaise <= 0) {
        throw Exception('Invalid Razorpay amount: $amountInPaise paise');
      }

      debugPrint('========================================');
      debugPrint('RAZORPAY CHECKOUT DETAILS');
      debugPrint('Key: $razorpayKeyId');
      debugPrint('Order ID: $orderId');
      debugPrint('Amount: ₹$amount');
      debugPrint('Amount in Paise: $amountInPaise');
      debugPrint('Currency: INR');
      debugPrint('Mobile: ${widget.mobile}');
      debugPrint('========================================');

      // =====================================================
      // RAZORPAY OPTIONS
      // =====================================================

      final Map<String, dynamic> options = {
        'key': razorpayKeyId,
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'Reading Room Management',
        'description': 'Monthly Seat Reservation',
        'order_id': orderId,

        'prefill': {'contact': widget.mobile, 'name': widget.name},

        'theme': {'color': '#4054C7'},

        'modal': {'confirm_close': true},
      };

      debugPrint('========================================');
      debugPrint('RAZORPAY OPTIONS');
      debugPrint(options.toString());
      debugPrint('========================================');

      // =====================================================
      // OPEN RAZORPAY
      // =====================================================

      debugPrint('CALLING razorpay.open()');

      razorpay.open(options);

      debugPrint('RAZORPAY OPEN CALLED SUCCESSFULLY');
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('RAZORPAY START ERROR');
      debugPrint('ERROR TYPE: ${e.runtimeType}');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE:');
      debugPrint(stackTrace.toString());
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      final String message = e
          .toString()
          .replaceFirst('Exception: ', '')
          .trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'Unable to start Razorpay payment.' : message,
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // =========================================================
  // PAYMENT SUCCESS
  // =========================================================

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('========================================');
    debugPrint('RAZORPAY PAYMENT SUCCESS');
    debugPrint('Payment ID: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');
    debugPrint('========================================');

    if (!mounted) {
      return;
    }

    try {
      // =====================================================
      // VALIDATE RESPONSE
      // =====================================================

      final String? paymentId = response.paymentId;
      final String? orderId = response.orderId;
      final String? signature = response.signature;

      if (paymentId == null || paymentId.trim().isEmpty) {
        throw Exception('Razorpay Payment ID was not received.');
      }

      if (orderId == null || orderId.trim().isEmpty) {
        throw Exception('Razorpay Order ID was not received.');
      }

      if (signature == null || signature.trim().isEmpty) {
        throw Exception('Razorpay Signature was not received.');
      }

      setState(() {
        loading = true;
      });

      // =====================================================
      // VERIFY PAYMENT WITH SPRING BOOT
      // =====================================================

      debugPrint('========================================');
      debugPrint('VERIFYING PAYMENT WITH BACKEND');
      debugPrint('Payment ID: $paymentId');
      debugPrint('Order ID: $orderId');
      debugPrint('Booking ID: ${widget.booking.id}');
      debugPrint('========================================');

      final Payment verifiedPayment = await paymentService.verifyPayment(
        userId: widget.userId,
        bookingId: widget.booking.id,
        razorpayPaymentId: paymentId,
        razorpayOrderId: orderId,
        razorpaySignature: signature,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        payment = verifiedPayment;
      });

      debugPrint('========================================');
      debugPrint('PAYMENT VERIFIED SUCCESSFULLY');
      debugPrint('Payment Status: ${verifiedPayment.status}');
      debugPrint('========================================');

      // =====================================================
      // SUCCESS MESSAGE
      // =====================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Seat booked successfully.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) {
        return;
      }

      // =====================================================
      // RETURN TO PREVIOUS PAGE
      // =====================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => StudentPage(
            name: widget.name,
            mobile: widget.mobile,
            userId: widget.userId,
          ),
        ),
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('PAYMENT VERIFICATION ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE:');
      debugPrint(stackTrace.toString());
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      final String message = e
          .toString()
          .replaceFirst('Exception: ', '')
          .trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Payment verification failed.'
                : 'Payment verification failed: $message',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // =========================================================
  // PAYMENT ERROR
  // =========================================================

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('========================================');
    debugPrint('RAZORPAY PAYMENT FAILED');
    debugPrint('Code: ${response.code}');
    debugPrint('Message: ${response.message}');
    debugPrint('========================================');

    if (!mounted) {
      return;
    }

    final String message = response.message?.trim().isNotEmpty == true
        ? response.message!
        : 'Razorpay payment failed.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // =========================================================
  // EXTERNAL WALLET
  // =========================================================

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('========================================');
    debugPrint('EXTERNAL WALLET');
    debugPrint('Wallet: ${response.walletName}');
    debugPrint('========================================');

    if (!mounted) {
      return;
    }

    final String walletName = response.walletName?.trim().isNotEmpty == true
        ? response.walletName!
        : 'External Wallet';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: $walletName')),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      drawer: AppDrawer(
        userId: widget.userId,
        name: widget.name,
        mobile: widget.mobile,
        selectedPage: 'Seat Booking',
      ),

      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // =================================================
              // ICON
              // =================================================
              Container(
                height: 85,
                width: 85,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF1FF),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 45,
                  color: Color(0xFF4054C7),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // TITLE
              // =================================================
              const Text(
                'Complete Your Payment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Confirm your seat reservation',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 30),

              // =================================================
              // BOOKING DETAILS
              // =================================================
              _bookingDetails(),

              const SizedBox(height: 20),

              // =================================================
              // PAYMENT DETAILS
              // =================================================
              _paymentDetails(),

              const SizedBox(height: 30),

              // =================================================
              // PAY BUTTON
              // =================================================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : createPayment,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4054C7),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: loading
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'PAY ₹${monthlyFee.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              // =================================================
              // PAYMENT STATUS
              // =================================================
              if (payment != null) _paymentStatus(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BOOKING DETAILS
  // =========================================================

  Widget _bookingDetails() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 18),

          _detailRow(Icons.event_seat, 'Seat', 'Seat ${widget.booking.seatId}'),

          _detailRow(
            Icons.calendar_today,
            'Start Date',
            widget.booking.startDate,
          ),

          _detailRow(Icons.event, 'End Date', widget.booking.endDate),

          _detailRow(
            Icons.info_outline,
            'Booking Status',
            widget.booking.status,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PAYMENT DETAILS
  // =========================================================

  Widget _paymentDetails() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 18),

          _detailRow(
            Icons.currency_rupee,
            'Monthly Fee',
            '₹${monthlyFee.toStringAsFixed(2)}',
          ),

          const Divider(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              Text(
                '₹${monthlyFee.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4054C7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PAYMENT STATUS
  // =========================================================

  Widget _paymentStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions, color: Colors.orange.shade700),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Payment status: ${payment!.status}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // =========================================================
  // DETAIL ROW
  // =========================================================

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4054C7)),

          const SizedBox(width: 12),

          Expanded(
            child: Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
