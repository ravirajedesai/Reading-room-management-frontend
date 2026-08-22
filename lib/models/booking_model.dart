import 'payment_model.dart';

enum BookingStatus { pending, active, expired, cancelled }

class Booking {
  final int? id;
  final int? userId;

  // =========================================================
  // STUDENT
  // =========================================================

  final String? studentName;
  final String? studentMobile;

  // =========================================================
  // SEAT
  // =========================================================

  final int? seatId;
  final int? seatNumber;

  // =========================================================
  // DATES
  // =========================================================

  final DateTime? startDate;
  final DateTime? endDate;

  final BookingStatus? bookingStatus;

  // =========================================================
  // PAYMENT
  // =========================================================

  final int? paymentId;
  final double? amount;

  final PaymentStatus? paymentStatus;
  final PaymentMethod? paymentMethod;
  final PaymentApprovalStatus? approvalStatus;
  final PaymentType? paymentType;

  final String? transactionId;
  final DateTime? paidAt;

  int? get bookingId => id;
  // =========================================================
  // CONSTRUCTOR
  // =========================================================

  const Booking({
    this.id,
    this.userId,
    this.studentName,
    this.studentMobile,
    this.seatId,
    this.seatNumber,
    this.startDate,
    this.endDate,
    this.bookingStatus,
    this.paymentId,
    this.amount,
    this.paymentStatus,
    this.paymentMethod,
    this.approvalStatus,
    this.paymentType,
    this.transactionId,
    this.paidAt,
  });

  // =========================================================
  // FROM JSON
  // =========================================================

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['bookingId'] ?? json['id'] ?? json['booking_id'],

      userId: _parseInt(json['userId'] ?? json['user_id']),

      studentName: _parseString(
        json['studentName'] ?? json['student_name'] ?? json['userName'] ?? json['username'] ?? json['name'],
      ),

      studentMobile: _parseString(
        json['studentMobile'] ??
            json['student_mobile'] ??
            json['mobile'] ??
            json['mobileNumber'],
      ),

      seatId: _parseInt(json['seatId'] ?? json['seat_id']),

      seatNumber: _parseInt(json['seatNumber'] ?? json['seat_number']),

      startDate: _parseDate(json['startDate'] ?? json['start_date']),

      endDate: _parseDate(json['endDate'] ?? json['end_date']),

      bookingStatus: _parseBookingStatus(
        json['bookingStatus'] ?? json['booking_status'],
      ),

      paymentId: _parseInt(json['paymentId'] ?? json['payment_id']),

      amount: _parseDouble(json['amount']),

      paymentStatus: _parsePaymentStatus(
        json['paymentStatus'] ?? json['payment_status'],
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

      paidAt: _parseDate(json['paidAt'] ?? json['paid_at']),
    );
  }

  // =========================================================
  // PARSERS
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

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

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
  // BOOKING STATUS
  // =========================================================

  static BookingStatus? _parseBookingStatus(dynamic value) {
    if (value == null) {
      return null;
    }

    switch (value.toString().trim().toUpperCase()) {
      case 'PENDING':
        return BookingStatus.pending;

      case 'ACTIVE':
        return BookingStatus.active;

      case 'EXPIRED':
        return BookingStatus.expired;

      case 'CANCELLED':
      case 'CANCELED':
        return BookingStatus.cancelled;

      default:
        return null;
    }
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
  // APPROVAL
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

  String get bookingStatusText {
    switch (bookingStatus) {
      case BookingStatus.pending:
        return 'Pending';

      case BookingStatus.active:
        return 'Active';

      case BookingStatus.expired:
        return 'Expired';

      case BookingStatus.cancelled:
        return 'Cancelled';

      default:
        return 'Not Available';
    }
  }

  String get paymentTypeText {
    switch (paymentType) {
      case PaymentType.full:
        return 'Full';

      case PaymentType.concessional:
        return 'Concessional';

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

  String get paymentStatusText {
    switch (paymentStatus) {
      case PaymentStatus.created:
        return 'Created';

      case PaymentStatus.pending:
        return 'Pending';

      case PaymentStatus.success:
        return 'Success';

      case PaymentStatus.failed:
        return 'Failed';

      case PaymentStatus.refunded:
        return 'Refunded';

      default:
        return 'Not Available';
    }
  }

  String get approvalStatusText {
    switch (approvalStatus) {
      case PaymentApprovalStatus.pending:
        return 'Pending';

      case PaymentApprovalStatus.approved:
        return 'Approved';

      case PaymentApprovalStatus.rejected:
        return 'Rejected';

      case PaymentApprovalStatus.notRequired:
        return 'Not Required';

      default:
        return 'Not Available';
    }
  }
}
