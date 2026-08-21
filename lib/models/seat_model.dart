class Seat {
  final int id;
  final int seatNumber;
  final String status;

  // Backend tells us whether this seat has a pending booking.
  final bool pending;

  // Backend tells us whether the pending booking belongs
  // to the currently logged-in user.
  final bool pendingByCurrentUser;

  Seat({
    required this.id,
    required this.seatNumber,
    required this.status,
    required this.pending,
    required this.pendingByCurrentUser,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: _parseInt(json['id']),
      seatNumber: _parseInt(json['seatNumber']),
      status: json['status']?.toString() ?? '',
      pending: json['pending'] == true,
      pendingByCurrentUser: json['pendingByCurrentUser'] == true,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // =========================================================
  // NORMALIZED STATUS
  // =========================================================

  String get normalizedStatus {
    return status.trim().toUpperCase();
  }

  // =========================================================
  // BOOKED
  // =========================================================

  bool get isBooked {
    return normalizedStatus == 'BOOKED';
  }

  // =========================================================
  // PENDING
  // =========================================================

  bool get isPending {
    return pending ||
        normalizedStatus == 'PENDING' ||
        normalizedStatus == 'HELD' ||
        normalizedStatus == 'TEMPORARILY_HELD';
  }

  // =========================================================
  // PENDING BY CURRENT USER
  // =========================================================

  bool get isMyPending {
    return isPending && pendingByCurrentUser;
  }

  // =========================================================
  // PENDING BY OTHER USER
  // =========================================================

  bool get isPendingByOtherUser {
    return isPending && !pendingByCurrentUser;
  }

  // =========================================================
  // AVAILABLE
  // =========================================================

  bool get isAvailable {
    return !isBooked && !isPending;
  }

  // =========================================================
  // SELECTABLE
  //
  // IMPORTANT:
  //
  // A seat pending for another user cannot be selected.
  //
  // A seat pending for the current user can be selected
  // if your UI wants the user to continue the existing booking.
  // =========================================================

  bool get isSelectable {
    if (isBooked) {
      return false;
    }

    if (isPendingByOtherUser) {
      return false;
    }

    return true;
  }

  // =========================================================
  // BACKWARD COMPATIBILITY
  // =========================================================

  bool isPendingForUser(int currentUserId) {
    return isMyPending;
  }

  bool isPendingForOtherUser(int currentUserId) {
    return isPendingByOtherUser;
  }

  bool isAvailableForUser(int currentUserId) {
    return isSelectable;
  }
}
