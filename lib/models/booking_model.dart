class Booking {
  final int id;
  final int userId;
  final int seatId;
  final String startDate;
  final String endDate;
  final String status;

  Booking({
    required this.id,
    required this.userId,
    required this.seatId,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),

      userId: json['userId'] is int
          ? json['userId']
          : int.parse(json['userId'].toString()),

      seatId: json['seatId'] is int
          ? json['seatId']
          : int.parse(json['seatId'].toString()),

      startDate: json['startDate']?.toString() ?? '',

      endDate: json['endDate']?.toString() ?? '',

      status: json['status']?.toString() ?? '',
    );
  }
}
