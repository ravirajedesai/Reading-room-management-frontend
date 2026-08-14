class Payment {
  final int id;
  final int bookingId;
  final int userId;
  final double amount;
  final String status;

  final String? paymentMethod;
  final String? transactionId;
  final String? razorpayOrderId;

  final String createdAt;
  final String? paidAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.transactionId,
    this.razorpayOrderId,
    required this.createdAt,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: _parseInt(json['id']),
      bookingId: _parseInt(json['bookingId']),
      userId: _parseInt(json['userId']),

      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,

      status: json['status']?.toString() ?? '',

      paymentMethod: json['paymentMethod']?.toString(),

      transactionId: json['transactionId']?.toString(),

      razorpayOrderId: json['razorpayOrderId']?.toString(),

      createdAt: json['createdAt']?.toString() ?? '',

      paidAt: json['paidAt']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
