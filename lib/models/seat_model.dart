class Seat {
  final int id;
  final int seatNumber;
  final String status;

  Seat({required this.id, required this.seatNumber, required this.status});

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: _parseInt(json['id']),
      seatNumber: _parseInt(json['seatNumber']),
      status: json['status']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
