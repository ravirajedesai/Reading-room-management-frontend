import 'package:flutter/material.dart';

import '../models/seat_model.dart';
import '../models/booking_model.dart';
import '../services/seat_service.dart';
import '../services/booking_service.dart';
import '../services/student_service.dart';

import 'payment_page.dart';
import 'dashboard_page.dart';
import '../widgets/app_drawer.dart';

class SeatBookingPage extends StatefulWidget {
  final int userId;
  final String name;
  final String mobile;

  const SeatBookingPage({
    super.key,
    required this.userId,
    required this.name,
    required this.mobile,
  });

  @override
  State<SeatBookingPage> createState() => _SeatBookingPageState();
}

class _SeatBookingPageState extends State<SeatBookingPage> {
  // ============================================================
  // SERVICES
  // ============================================================

  final SeatService seatService = SeatService();
  final BookingService bookingService = BookingService();

  // ============================================================
  // STATE
  // ============================================================

  List<Seat> seats = [];

  int? selectedSeat;

  bool isLoading = true;
  bool isBooking = false;

  // ============================================================
  // TEMPORARILY UNAVAILABLE SEATS
  //
  // Used only when another student grabs a seat between
  // refreshes and backend returns 409.
  // ============================================================

  final Set<int> temporarilyUnavailableSeats = {};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadSeats();
  }

  // ============================================================
  // LOAD SEATS
  // ============================================================

  Future<void> loadSeats() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      debugPrint("========================================");
      debugPrint("GET ALL SEATS");
      debugPrint("USER ID: ${widget.userId}");
      debugPrint("========================================");

      final List<Seat> result = await seatService.getAllSeats();

      debugPrint("SEATS RECEIVED: ${result.length}");

      for (final Seat seat in result) {
        if (_isPendingStatus(_seatStatus(seat))) {
          debugPrint(
            "SEAT ${seat.seatNumber}: "
            "PENDING=${seat.isPending} "
            "MY_PENDING=${seat.pendingByCurrentUser}",
          );
        }
      }

      if (!mounted) return;

      final Set<int> backendUnavailable = {};

      for (final Seat seat in result) {
        final String status = _seatStatus(seat);

        if (_isBookedStatus(status) || _isPendingStatus(status)) {
          backendUnavailable.add(seat.seatNumber);
        }
      }

      setState(() {
        seats = result;

        temporarilyUnavailableSeats.removeWhere(
          (seatNumber) => !backendUnavailable.contains(seatNumber),
        );

        isLoading = false;
      });
    } catch (e) {
      debugPrint("GET ALL SEATS ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load seats: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // NORMALIZE STATUS
  // ============================================================

  String _seatStatus(Seat seat) {
    return seat.status.trim().toUpperCase();
  }

  // ============================================================
  // BOOKED STATUS
  // ============================================================

  bool _isBookedStatus(String status) {
    final String normalized = status.trim().toUpperCase();

    return normalized == 'BOOKED' ||
        normalized == 'RESERVED' ||
        normalized == 'OCCUPIED' ||
        normalized == 'ACTIVE';
  }

  // ============================================================
  // PENDING STATUS
  // ============================================================

  bool _isPendingStatus(String status) {
    final String normalized = status.trim().toUpperCase();

    return normalized == 'PENDING' ||
        normalized == 'HELD' ||
        normalized == 'ON_HOLD' ||
        normalized == 'ON HOLD' ||
        normalized == 'HOLD' ||
        normalized == 'TEMPORARILY_HELD' ||
        normalized == 'TEMPORARILY HELD' ||
        normalized == 'TEMPORARY_HOLD' ||
        normalized == 'TEMPORARY HOLD' ||
        normalized == 'PAYMENT_PENDING';
  }

  // ============================================================
  // BOOKED
  // ============================================================

  bool _isBooked(Seat seat) {
    return _isBookedStatus(_seatStatus(seat));
  }

  // ============================================================
  // MY PENDING
  //
  // IMPORTANT:
  //
  // Backend returns:
  //
  // pending = true
  // pendingByCurrentUser = true
  //
  // Therefore this seat belongs to current student.
  // ============================================================

  bool _isMyPending(Seat seat) {
    final String status = _seatStatus(seat);

    final bool result = _isPendingStatus(status) && seat.pendingByCurrentUser;

    return result;
  }

  // ============================================================
  // PENDING BY OTHER USER
  // ============================================================

  bool _isPendingByOtherUser(Seat seat) {
    final String status = _seatStatus(seat);

    return _isPendingStatus(status) && !seat.pendingByCurrentUser;
  }

  // ============================================================
  // PENDING FOR UI
  //
  // IMPORTANT:
  //
  // My own pending seat is NOT considered blocked.
  //
  // Another student's pending seat IS considered blocked.
  // ============================================================

  bool _isPending(Seat seat) {
    final String status = _seatStatus(seat);

    // ----------------------------------------------------------
    // Pending from another student
    // ----------------------------------------------------------

    if (_isPendingStatus(status)) {
      return !seat.pendingByCurrentUser;
    }

    // ----------------------------------------------------------
    // Local temporary lock
    // ----------------------------------------------------------

    if (!_isBookedStatus(status) &&
        temporarilyUnavailableSeats.contains(seat.seatNumber)) {
      return true;
    }

    return false;
  }

  // ============================================================
  // AVAILABLE
  // ============================================================

  bool _isAvailable(Seat seat) {
    if (_isBooked(seat)) {
      return false;
    }

    // My pending seat is NOT available for a NEW booking.
    // It is handled separately as "Pay Now".
    if (_isMyPending(seat)) {
      return false;
    }

    if (_isPendingByOtherUser(seat)) {
      return false;
    }

    if (temporarilyUnavailableSeats.contains(seat.seatNumber)) {
      return false;
    }

    return _seatStatus(seat) == 'AVAILABLE';
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int get bookedSeats {
    return seats.where((Seat seat) => _isBooked(seat)).length;
  }

  int get pendingSeats {
    return seats.where((Seat seat) => _isPending(seat)).length;
  }

  int get availableSeats {
    return seats.where((Seat seat) => _isAvailable(seat)).length;
  }

  // ============================================================
  // SELECT SEAT
  // ============================================================

  void selectSeat(Seat seat) {
    if (isBooking) {
      return;
    }

    // ==========================================================
    // BOOKED
    // ==========================================================

    if (_isBooked(seat)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Seat ${seat.seatNumber} is already booked."),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // ==========================================================
    // MY PENDING
    //
    // IMPORTANT:
    //
    // This MUST be checked before normal pending.
    //
    // This allows the student who already owns the pending
    // booking to continue to payment.
    // ==========================================================

    if (_isMyPending(seat)) {
      debugPrint("========================================");
      debugPrint("MY PENDING SEAT SELECTED");
      debugPrint("USER ID: ${widget.userId}");
      debugPrint("SEAT ID: ${seat.id}");
      debugPrint("SEAT NUMBER: ${seat.seatNumber}");
      debugPrint("========================================");

      setState(() {
        selectedSeat = seat.seatNumber;
      });

      return;
    }

    // ==========================================================
    // OTHER STUDENT PENDING
    // ==========================================================

    if (_isPendingByOtherUser(seat)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Seat ${seat.seatNumber} is temporarily held by another student.",
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );

      return;
    }

    // ==========================================================
    // AVAILABLE
    // ==========================================================

    if (!_isAvailable(seat)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Seat ${seat.seatNumber} is currently unavailable."),
        ),
      );

      return;
    }

    setState(() {
      selectedSeat = seat.seatNumber;
    });
  }

  // ============================================================
  // FIND SELECTED SEAT
  // ============================================================

  Seat? _findSelectedSeat() {
    if (selectedSeat == null) {
      return null;
    }

    for (final Seat seat in seats) {
      if (seat.seatNumber == selectedSeat) {
        return seat;
      }
    }

    return null;
  }

  // ============================================================
  // GET EXISTING PENDING BOOKING
  //
  // This is used when:
  //
  // Seat = PENDING
  // pendingByCurrentUser = true
  //
  // We DO NOT call holdSeat().
  // We retrieve the existing booking instead.
  // ============================================================

  Future<Booking> _getExistingPendingBooking() async {
    debugPrint("========================================");
    debugPrint("GET EXISTING PENDING BOOKING");
    debugPrint("USER ID: ${widget.userId}");
    debugPrint("========================================");

    final Map<String, dynamic>? response = await StudentService.getMyBooking(
      widget.userId,
    );

    debugPrint("MY BOOKING RESPONSE: $response");

    if (response == null || response.isEmpty) {
      throw Exception(
        "Your pending booking was not found. Please refresh and try again.",
      );
    }

    // ----------------------------------------------------------
    // IMPORTANT:
    //
    // Backend returns the booking identifier as `id`.
    // Booking model also uses `id`.
    // Do NOT convert it to `bookingId`.
    // ----------------------------------------------------------

    final Map<String, dynamic> normalized = Map<String, dynamic>.from(response);

    // ----------------------------------------------------------
    // Also normalize status names if necessary.
    // ----------------------------------------------------------

    if (normalized['bookingStatus'] == null && normalized['status'] != null) {
      normalized['bookingStatus'] = normalized['status'];
    }

    // ----------------------------------------------------------
    // Verify booking belongs to current user when backend
    // returns userId.
    // ----------------------------------------------------------

    final dynamic responseUserId = normalized['userId'];

    if (responseUserId != null) {
      final int? parsedUserId = int.tryParse(responseUserId.toString());

      if (parsedUserId != null && parsedUserId != widget.userId) {
        throw Exception("The pending booking belongs to another student.");
      }
    }

    // ----------------------------------------------------------
    // Verify booking ID.
    // Booking model uses `id`.
    // ----------------------------------------------------------

    if (normalized['id'] == null) {
      throw Exception("Booking ID was not returned by the server.");
    }

    final Booking booking = Booking.fromJson(normalized);

    if (booking.id == null) {
      throw Exception("Booking ID was not returned by the server.");
    }

    debugPrint("========================================");
    debugPrint("EXISTING BOOKING FOUND");
    debugPrint("BOOKING ID: ${booking.id}");
    debugPrint("USER ID: ${booking.userId}");
    debugPrint("SEAT ID: ${booking.seatId}");
    debugPrint("SEAT NUMBER: ${booking.seatNumber}");
    debugPrint("STATUS: ${booking.bookingStatus}");
    debugPrint("========================================");

    return booking;
  }

  // ============================================================
  // CONTINUE EXISTING BOOKING
  // ============================================================

  Future<void> continueExistingBooking() async {
    if (isBooking) {
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      final Seat? selectedSeatObject = _findSelectedSeat();

      if (selectedSeatObject == null) {
        throw Exception("Selected seat not found.");
      }

      // ----------------------------------------------------------
      // Safety check
      // ----------------------------------------------------------

      if (!_isMyPending(selectedSeatObject)) {
        throw Exception("This seat is no longer your pending seat.");
      }

      debugPrint("========================================");
      debugPrint("CONTINUE EXISTING BOOKING");
      debugPrint("USER ID: ${widget.userId}");
      debugPrint("SEAT ID: ${selectedSeatObject.id}");
      debugPrint("SEAT NUMBER: ${selectedSeatObject.seatNumber}");
      debugPrint("========================================");

      // ----------------------------------------------------------
      // GET EXISTING BOOKING
      // ----------------------------------------------------------

      final Booking booking = await _getExistingPendingBooking();

      // ----------------------------------------------------------
      // Verify seat belongs to selected seat where possible.
      // ----------------------------------------------------------

      if (booking.seatId != null && booking.seatId != selectedSeatObject.id) {
        throw Exception(
          "The existing pending booking does not belong to "
          "the selected seat.",
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isBooking = false;
      });

      // ----------------------------------------------------------
      // GO DIRECTLY TO PAYMENT
      // ----------------------------------------------------------

      debugPrint("========================================");
      debugPrint("OPEN PAYMENT FOR EXISTING BOOKING");
      debugPrint("BOOKING ID: ${booking.id}");
      debugPrint("========================================");

      final dynamic paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentPage(booking: booking)),
      );

      // ----------------------------------------------------------
      // PAYMENT SUCCESS
      // ----------------------------------------------------------

      if (paymentResult == true) {
        await loadSeats();

        if (!mounted) {
          return;
        }

        setState(() {
          selectedSeat = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment successful. Seat booked successfully."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              userId: widget.userId,
              name: widget.name,
              mobile: widget.mobile,
            ),
          ),
          (route) => false,
        );

        return;
      }

      // ----------------------------------------------------------
      // PAYMENT NOT COMPLETED
      //
      // DO NOT cancel the booking.
      //
      // It remains pending so the same student can come back
      // and continue payment.
      // ----------------------------------------------------------

      await loadSeats();

      if (!mounted) {
        return;
      }

      setState(() {
        selectedSeat = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Payment was not completed. Your seat remains "
            "reserved for you until the booking expires.",
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint("CONTINUE EXISTING BOOKING ERROR: $e");

      if (!mounted) {
        return;
      }

      setState(() {
        isBooking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to continue payment: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

      await loadSeats();
    }
  }

  // ============================================================
  // START BOOKING
  // ============================================================

  Future<void> startBooking() async {
    if (selectedSeat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a seat first.")),
      );

      return;
    }

    if (isBooking) {
      return;
    }

    final Seat? selectedSeatObject = _findSelectedSeat();

    if (selectedSeatObject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Selected seat not found.")));

      return;
    }

    // ==========================================================
    // BOOKED
    // ==========================================================

    if (_isBooked(selectedSeatObject)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This seat is already booked.")),
      );

      await loadSeats();

      return;
    }

    // ==========================================================
    // MY PENDING
    //
    // IMPORTANT:
    //
    // DO NOT create another booking.
    //
    // Continue with existing booking/payment.
    // ==========================================================

    if (_isMyPending(selectedSeatObject)) {
      await continueExistingBooking();
      return;
    }

    // ==========================================================
    // OTHER STUDENT PENDING
    // ==========================================================

    if (_isPendingByOtherUser(selectedSeatObject)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Seat ${selectedSeatObject.seatNumber} is temporarily "
            "held by another student.",
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );

      setState(() {
        selectedSeat = null;
      });

      return;
    }

    // ==========================================================
    // AVAILABLE CHECK
    // ==========================================================

    if (!_isAvailable(selectedSeatObject)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Seat ${selectedSeatObject.seatNumber} is currently unavailable.",
          ),
        ),
      );

      await loadSeats();

      return;
    }

    // ==========================================================
    // CONFIRM NEW BOOKING
    // ==========================================================

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Confirm Seat Booking",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Do you want to reserve Seat "
                "${selectedSeatObject.seatNumber}?",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade800,
                      size: 26,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        "Important\n\n"
                        "This seat will be temporarily held for you "
                        "while you complete the payment process.\n\n"
                        "You must complete the payment within 5 days "
                        "to keep this seat reserved. If the payment is "
                        "not completed within 5 days, the temporary hold "
                        "may expire and the seat can become available "
                        "for other students.",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await createBooking();
  }

  // ============================================================
  // CREATE NEW BOOKING
  //
  // ONLY USED FOR AVAILABLE SEATS.
  //
  // NEVER USED FOR MY PENDING SEAT.
  // ============================================================

  Future<void> createBooking() async {
    if (selectedSeat == null || isBooking) {
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      final Seat? selectedSeatObject = _findSelectedSeat();

      if (selectedSeatObject == null) {
        throw Exception("Selected seat not found.");
      }

      // ========================================================
      // FINAL BOOKED CHECK
      // ========================================================

      if (_isBooked(selectedSeatObject)) {
        throw Exception(
          "Seat ${selectedSeatObject.seatNumber} is already booked.",
        );
      }

      // ========================================================
      // FINAL MY PENDING CHECK
      //
      // Never create duplicate booking.
      // ========================================================

      if (_isMyPending(selectedSeatObject)) {
        setState(() {
          isBooking = false;
        });

        await continueExistingBooking();

        return;
      }

      // ========================================================
      // FINAL OTHER USER PENDING CHECK
      // ========================================================

      if (_isPendingByOtherUser(selectedSeatObject)) {
        throw Exception(
          "Seat ${selectedSeatObject.seatNumber} is temporarily "
          "held by another student.",
        );
      }

      // ========================================================
      // FINAL AVAILABLE CHECK
      // ========================================================

      if (!_isAvailable(selectedSeatObject)) {
        throw Exception(
          "Seat ${selectedSeatObject.seatNumber} is currently unavailable.",
        );
      }

      // ========================================================
      // HOLD SEAT
      // ========================================================

      debugPrint("========================================");
      debugPrint("HOLD SEAT REQUEST");
      debugPrint("USER ID: ${widget.userId}");
      debugPrint("SEAT ID: ${selectedSeatObject.id}");
      debugPrint("SEAT NUMBER: ${selectedSeatObject.seatNumber}");
      debugPrint("========================================");

      final Map<String, dynamic> response = await bookingService.holdSeat(
        selectedSeatObject.id,
      );

      debugPrint("========================================");
      debugPrint("HOLD SEAT STATUS: SUCCESS");
      debugPrint("HOLD SEAT BODY: $response");
      debugPrint("========================================");

      // ========================================================
      // NORMALIZE BOOKING RESPONSE
      //
      // Backend returns booking identifier as `id`.
      // Booking model also uses `id`.
      // Do NOT create/use `bookingId`.
      // ========================================================

      final Map<String, dynamic> normalized = Map<String, dynamic>.from(
        response,
      );

      if (normalized['bookingStatus'] == null && normalized['status'] != null) {
        normalized['bookingStatus'] = normalized['status'];
      }

      // ========================================================
      // CONVERT RESPONSE
      // ========================================================

      final Booking booking = Booking.fromJson(normalized);

      // ========================================================
      // VALIDATE BOOKING ID
      // ========================================================

      if (booking.id == null) {
        throw Exception("Booking ID was not returned by the server.");
      }

      debugPrint("========================================");
      debugPrint("BOOKING CREATED");
      debugPrint("BOOKING ID: ${booking.id}");
      debugPrint("USER ID: ${booking.userId}");
      debugPrint("SEAT ID: ${booking.seatId}");
      debugPrint("STATUS: ${booking.bookingStatus}");
      debugPrint("========================================");

      if (!mounted) {
        return;
      }

      setState(() {
        isBooking = false;
      });

      // ========================================================
      // PAYMENT PAGE
      // ========================================================

      final dynamic paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentPage(booking: booking)),
      );

      // ========================================================
      // PAYMENT SUCCESS
      // ========================================================

      if (paymentResult == true) {
        await loadSeats();

        if (!mounted) {
          return;
        }

        setState(() {
          selectedSeat = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment successful. Seat booked successfully."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              userId: widget.userId,
              name: widget.name,
              mobile: widget.mobile,
            ),
          ),
          (route) => false,
        );

        return;
      }

      // ========================================================
      // PAYMENT NOT COMPLETED
      //
      // IMPORTANT:
      //
      // DO NOT release/cancel the booking.
      //
      // The student can return later and continue payment.
      // ========================================================

      await loadSeats();

      if (!mounted) {
        return;
      }

      setState(() {
        selectedSeat = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Payment was not completed. The seat remains "
            "temporarily held until the booking expires "
            "or is cancelled.",
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint("CREATE BOOKING ERROR: $e");

      if (!mounted) {
        return;
      }

      setState(() {
        isBooking = false;
      });

      final String errorMessage = e.toString();

      // ========================================================
      // 409 / ALREADY BOOKED / TEMPORARILY HELD
      // ========================================================

      if (errorMessage.toUpperCase().contains("TEMPORARILY HELD") ||
          errorMessage.toUpperCase().contains("ALREADY_BOOKED_SEAT") ||
          errorMessage.contains("409")) {
        final int? failedSeat = selectedSeat;

        if (failedSeat != null) {
          temporarilyUnavailableSeats.add(failedSeat);
        }

        setState(() {
          selectedSeat = null;
        });

        await loadSeats();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failedSeat != null
                  ? "Seat $failedSeat was just held by another student."
                  : "This seat was just held by another student.",
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );

        return;
      }

      // ========================================================
      // NORMAL ERROR
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to create booking: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

      await loadSeats();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshSeats() async {
    if (!mounted) {
      return;
    }

    setState(() {
      selectedSeat = null;
    });

    await loadSeats();
  }

  // ============================================================
  // COMPACT SEAT SUMMARY
  // ============================================================

  Widget _advancedSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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

  // ============================================================
  // LEGEND
  // ============================================================

  Widget _advancedLegend({required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ============================================================
  // SEAT CARD
  // ============================================================

  Widget _seatCard({
    required Seat seat,
    required bool booked,
    required bool pending,
    required bool myPending,
    required bool selected,
  }) {
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    Color textColor;

    IconData icon;
    String statusText;

    // ==========================================================
    // BOOKED
    // ==========================================================

    if (booked) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      iconColor = Colors.red;
      textColor = Colors.red.shade800;
      icon = Icons.lock_rounded;
      statusText = "Booked";
    }
    // ==========================================================
    // MY PENDING
    //
    // SPECIAL UI
    // ==========================================================
    else if (myPending) {
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade600;
      iconColor = Colors.orange.shade800;
      textColor = Colors.orange.shade900;
      icon = Icons.payment_rounded;
      statusText = "Pay Now";
    }
    // ==========================================================
    // OTHER PENDING
    // ==========================================================
    else if (pending) {
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade400;
      iconColor = Colors.orange.shade800;
      textColor = Colors.orange.shade800;
      icon = Icons.hourglass_top_rounded;
      statusText = "Pending";
    }
    // ==========================================================
    // SELECTED
    // ==========================================================
    else if (selected) {
      backgroundColor = Colors.indigo;
      borderColor = Colors.indigo;
      iconColor = Colors.white;
      textColor = Colors.white;
      icon = Icons.check_circle_rounded;
      statusText = "Selected";
    }
    // ==========================================================
    // AVAILABLE
    // ==========================================================
    else {
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      iconColor = Colors.green.shade700;
      textColor = Colors.black87;
      icon = Icons.event_seat_rounded;
      statusText = "Available";
    }

    // ==========================================================
    // DISABLED
    //
    // MY PENDING IS NOT DISABLED.
    // ==========================================================

    final bool disabled = booked || (pending && !myPending) || isBooking;

    return GestureDetector(
      onTap: disabled
          ? null
          : () {
              selectSeat(seat);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: selected || myPending ? 2 : 1,
            color: borderColor,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(height: 2),
              Text(
                "${seat.seatNumber}",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEAT GRID
  // ============================================================

  Widget _buildSeatGrid({required int crossAxisCount}) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: seats.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final Seat seat = seats[index];

          final bool booked = _isBooked(seat);

          final bool myPending = _isMyPending(seat);

          final bool pending = _isPendingByOtherUser(seat);

          final bool selected = selectedSeat == seat.seatNumber;

          return _seatCard(
            seat: seat,
            booked: booked,
            pending: pending,
            myPending: myPending,
            selected: selected,
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),

      // ========================================================
      // DRAWER
      // ========================================================
      drawer: AppDrawer(
        userId: widget.userId,
        name: widget.name,
        mobile: widget.mobile,
        selectedPage: 'Seat Booking',
        role: 'STUDENT',
      ),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Library Management",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              "Seat Reservation",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh seats",
            onPressed: isLoading ? null : refreshSeats,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;

            final int crossAxisCount = width >= 1200
                ? 20
                : width >= 900
                ? 20
                : width >= 600
                ? 8
                : 5;

            final double horizontalPadding = width >= 1000 ? 28 : 16;

            return RefreshIndicator(
              onRefresh: refreshSeats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // HERO
                    // =================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xff3949ab), Color(0xff5c6bc0)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.20),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 58,
                            width: 58,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.event_seat_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Book Your Seat",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Choose your preferred seat and continue to secure your place.",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // =================================================
                    // COMPACT HORIZONTAL SUMMARY
                    //
                    // Always shown in one line:
                    // Available | Pending | Booked
                    // =================================================
                    Row(
                      children: [
                        _advancedSummaryCard(
                          icon: Icons.event_seat_rounded,
                          title: "Available",
                          value: availableSeats.toString(),
                          subtitle: "Ready to book",
                          iconColor: Colors.green,
                        ),

                        const SizedBox(width: 8),

                        _advancedSummaryCard(
                          icon: Icons.hourglass_top_rounded,
                          title: "Pending",
                          value: pendingSeats.toString(),
                          subtitle: "Held",
                          iconColor: Colors.orange,
                        ),

                        const SizedBox(width: 8),

                        _advancedSummaryCard(
                          icon: Icons.lock_rounded,
                          title: "Booked",
                          value: bookedSeats.toString(),
                          subtitle: "Reserved",
                          iconColor: Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // =================================================
                    // TITLE
                    // =================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Choose Your Seat",
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff202124),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Your pending seat shows as Pay Now",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "${seats.length} Seats",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // =================================================
                    // LEGEND
                    // =================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          _advancedLegend(
                            color: Colors.green,
                            text: "Available",
                          ),
                          _advancedLegend(
                            color: Colors.orange,
                            text: "Pending / Pay Now",
                          ),
                          _advancedLegend(color: Colors.red, text: "Booked"),
                          _advancedLegend(
                            color: Colors.indigo,
                            text: "Selected",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // SEAT GRID
                    // =================================================
                    if (isLoading)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(60),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    else if (seats.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_seat_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "No seats available",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      _buildSeatGrid(crossAxisCount: crossAxisCount),

                    const SizedBox(height: 22),

                    // =================================================
                    // SELECTED SEAT
                    // =================================================
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: selectedSeat == null
                          ? const SizedBox.shrink()
                          : Container(
                              key: ValueKey(selectedSeat),
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.indigo.withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 44,
                                    width: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.indigo,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Selected Seat",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _isMyPending(
                                                _findSelectedSeat() ??
                                                    Seat(
                                                      id: 0,
                                                      seatNumber: selectedSeat!,
                                                      status: '',
                                                      pending: false,
                                                      pendingByCurrentUser:
                                                          false,
                                                    ),
                                              )
                                              ? "Existing booking - ready for payment"
                                              : "Ready for booking",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Text(
                                    "$selectedSeat",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 14),

                    // =================================================
                    // PAYMENT BUTTON
                    // =================================================
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: selectedSeat == null || isBooking
                            ? null
                            : startBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isBooking
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 21,
                                    width: 21,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Processing...",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isMyPending(
                                          _findSelectedSeat() ??
                                              Seat(
                                                id: 0,
                                                seatNumber: selectedSeat ?? 0,
                                                status: '',
                                                pending: false,
                                                pendingByCurrentUser: false,
                                              ),
                                        )
                                        ? Icons.payment_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedSeat == null
                                        ? "Select a Seat"
                                        : _isMyPending(_findSelectedSeat()!)
                                        ? "Continue Payment"
                                        : "Continue to Payment",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 19,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =================================================
                    // RAZORPAY
                    // =================================================
                    if (selectedSeat != null)
                      const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Secure payment powered by Razorpay",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
