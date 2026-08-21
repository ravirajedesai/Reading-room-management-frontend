enum PaymentStatus { created, pending, success, failed, refunded }

enum PaymentMethod { online, cash }

enum PaymentApprovalStatus { notRequired, pending, approved, rejected }

enum PaymentType { full, concessional }

class Payment {
  // =========================================================
  // BASIC PAYMENT DETAILS
  // =========================================================

  final int? id;
  final int? userId;
  final int? bookingId;
  final double? amount;

  // =========================================================
  // STUDENT / BOOKING DETAILS
  // =========================================================

  final String? studentName;
  final String? seatNumber;

  // =========================================================
  // PAYMENT STATUS
  // =========================================================

  final PaymentStatus? status;
  final PaymentMethod? paymentMethod;
  final PaymentApprovalStatus? approvalStatus;
  final PaymentType? paymentType;

  // =========================================================
  // PAYMENT IDENTIFIERS
  // =========================================================

  final String? transactionId;
  final String? razorpayOrderId;

  // =========================================================
  // DATE / TIME
  // =========================================================

  final DateTime? paidAt;
  final DateTime? createdAt;

  // =========================================================
  // CONSTRUCTOR
  // =========================================================

  const Payment({
    this.id,
    this.userId,
    this.bookingId,
    this.amount,
    this.studentName,
    this.seatNumber,
    this.status,
    this.paymentMethod,
    this.approvalStatus,
    this.paymentType,
    this.transactionId,
    this.razorpayOrderId,
    this.paidAt,
    this.createdAt,
  });

  // =========================================================
  // FROM JSON
  // =========================================================

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: _parseInt(json['id']),
      userId: _parseInt(json['userId'] ?? json['user_id']),
      bookingId: _parseInt(json['bookingId'] ?? json['booking_id']),
      amount: _parseDouble(json['amount']),

      studentName: _parseString(
        json['studentName'] ?? json['student_name'] ?? json['name'],
      ),

      seatNumber: _parseString(json['seatNumber'] ?? json['seat_number']),

      status: _parsePaymentStatus(
        json['status'] ?? json['paymentStatus'] ?? json['payment_status'],
      ),

      paymentMethod: _parsePaymentMethod(
        json['paymentMethod'] ?? json['payment_method'],
      ),

      approvalStatus: _parseApprovalStatus(
        json['approvalStatus'] ?? json['approval_status'],
      ),

      paymentType: _parsePaymentType(
        json['paymentType'] ?? json['payment_type'],
      ),

      transactionId: _parseString(
        json['transactionId'] ?? json['transaction_id'],
      ),

      razorpayOrderId: _parseString(
        json['razorpayOrderId'] ?? json['razorpay_order_id'],
      ),

      paidAt: _parseDate(json['paidAt'] ?? json['paid_at']),

      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  // =========================================================
  // STRING
  // =========================================================

  static String? _parseString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  // =========================================================
  // INT
  // =========================================================

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  // =========================================================
  // DOUBLE
  // =========================================================

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  // =========================================================
  // DATE
  // =========================================================

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return DateTime.tryParse(text);
  }

  // =========================================================
  // PAYMENT STATUS
  // =========================================================

  static PaymentStatus? _parsePaymentStatus(dynamic value) {
    if (value == null) {
      return null;
    }

    switch (value.toString().trim().toUpperCase()) {
      case 'CREATED':
        return PaymentStatus.created;

      case 'PENDING':
        return PaymentStatus.pending;

      case 'SUCCESS':
        return PaymentStatus.success;

      case 'FAILED':
        return PaymentStatus.failed;

      case 'REFUNDED':
        return PaymentStatus.refunded;

      default:
        return null;
    }
  }

  // =========================================================
  // PAYMENT METHOD
  // =========================================================

  static PaymentMethod? _parsePaymentMethod(dynamic value) {
    if (value == null) {
      return null;
    }

    switch (value.toString().trim().toUpperCase()) {
      case 'ONLINE':
        return PaymentMethod.online;

      case 'CASH':
        return PaymentMethod.cash;

      default:
        return null;
    }
  }

  // =========================================================
  // APPROVAL STATUS
  // =========================================================

  static PaymentApprovalStatus? _parseApprovalStatus(dynamic value) {
    if (value == null) {
      return null;
    }

    switch (value.toString().trim().toUpperCase()) {
      case 'NOT_REQUIRED':
      case 'NOTREQUIRED':
      case 'NOT-REQUIRED':
        return PaymentApprovalStatus.notRequired;

      case 'PENDING':
        return PaymentApprovalStatus.pending;

      case 'APPROVED':
        return PaymentApprovalStatus.approved;

      case 'REJECTED':
        return PaymentApprovalStatus.rejected;

      default:
        return null;
    }
  }

  // =========================================================
  // PAYMENT TYPE
  // =========================================================

  static PaymentType? _parsePaymentType(dynamic value) {
    if (value == null) {
      return null;
    }

    switch (value.toString().trim().toUpperCase()) {
      case 'FULL':
        return PaymentType.full;

      case 'CONCESSIONAL':
        return PaymentType.concessional;

      default:
        return null;
    }
  }

  // =========================================================
  // DISPLAY
  // =========================================================

  String get statusText {
    switch (status) {
      case PaymentStatus.created:
        return 'Created';

      case PaymentStatus.pending:
        return 'Pending';

      case PaymentStatus.success:
        return 'Successful';

      case PaymentStatus.failed:
        return 'Failed';

      case PaymentStatus.refunded:
        return 'Refunded';

      default:
        return 'Not Available';
    }
  }

  String get paymentMethodText {
    switch (paymentMethod) {
      case PaymentMethod.online:
        return 'Online';

      case PaymentMethod.cash:
        return 'Cash';

      default:
        return 'Not Available';
    }
  }

  String get approvalStatusText {
    switch (approvalStatus) {
      case PaymentApprovalStatus.notRequired:
        return 'Not Required';

      case PaymentApprovalStatus.pending:
        return 'Pending Approval';

      case PaymentApprovalStatus.approved:
        return 'Approved';

      case PaymentApprovalStatus.rejected:
        return 'Rejected';

      default:
        return 'Not Available';
    }
  }

  String get paymentTypeText {
    switch (paymentType) {
      case PaymentType.full:
        return 'Full Payment';

      case PaymentType.concessional:
        return 'Concessional';

      default:
        return 'Not Available';
    }
  }

  // =========================================================
  // NOTIFICATION HELPERS
  // =========================================================

  bool get isAcceptedNotification {
    return approvalStatus == PaymentApprovalStatus.approved;
  }

  bool get isRejectedNotification {
    return approvalStatus == PaymentApprovalStatus.rejected;
  }

  bool get isPaymentNotification {
    return isAcceptedNotification || isRejectedNotification;
  }

  String get notificationTitle {
    if (isAcceptedNotification) {
      return 'Payment Accepted';
    }

    if (isRejectedNotification) {
      return 'Payment Rejected';
    }

    return 'Payment Update';
  }

  String get notificationMessage {
    final seat = seatNumber ?? 'your selected seat';

    if (isAcceptedNotification) {
      return 'Your payment for Seat $seat has been accepted.';
    }

    if (isRejectedNotification) {
      return 'Your payment request for Seat $seat has been rejected by the owner.';
    }

    return 'There is an update regarding your payment.';
  }
}
