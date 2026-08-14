import 'package:flutter/material.dart';

import '../models/seat_model.dart';
import '../models/booking_model.dart';
import '../services/seat_service.dart';
import '../services/booking_service.dart';
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
  final SeatService seatService = SeatService();
  final BookingService bookingService = BookingService();

  List<Seat> seats = [];

  int? selectedSeat;

  bool isLoading = true;
  bool isBooking = false;

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
      final List<Seat> result = await seatService.getAllSeats();

      if (!mounted) return;

      setState(() {
        seats = result;
        isLoading = false;
      });
    } catch (e) {
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
  // BOOKED COUNT
  // ============================================================

  int get bookedSeats {
    return seats.where((seat) => seat.status.toUpperCase() == "BOOKED").length;
  }

  // ============================================================
  // AVAILABLE COUNT
  // ============================================================

  int get availableSeats {
    return seats
        .where((seat) => seat.status.toUpperCase() == "AVAILABLE")
        .length;
  }

  // ============================================================
  // SELECT SEAT
  // ============================================================

  void selectSeat(Seat seat) {
    if (seat.status.toUpperCase() == "BOOKED") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This seat is already booked.")),
      );

      return;
    }

    setState(() {
      selectedSeat = seat.seatNumber;
    });
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

    final Seat? selectedSeatObject = seats.cast<Seat?>().firstWhere(
      (seat) => seat?.seatNumber == selectedSeat,
      orElse: () => null,
    );

    if (selectedSeatObject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Selected seat not found.")));

      return;
    }

    // Prevent booking already booked seat.
    if (selectedSeatObject.status.toUpperCase() == "BOOKED") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This seat is already booked.")),
      );

      await loadSeats();
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Confirm Seat Booking",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Do you want to book Seat $selectedSeat?\n\n"
            "The seat will be booked only after successful payment.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
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
  // CREATE BOOKING
  // ============================================================

  Future<void> createBooking() async {
    if (selectedSeat == null) {
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      final Seat? selectedSeatObject = seats.cast<Seat?>().firstWhere(
        (seat) => seat?.seatNumber == selectedSeat,
        orElse: () => null,
      );

      if (selectedSeatObject == null) {
        throw Exception("Selected seat not found.");
      }

      // Create PENDING booking
      final Booking booking = await bookingService.holdSeat(
        userId: widget.userId,
        seatId: selectedSeatObject.id,
      );

      if (!mounted) return;

      setState(() {
        isBooking = false;
      });

      // ========================================================
      // OPEN PAYMENT PAGE
      // ========================================================

      final dynamic paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return PaymentPage(
              userId: widget.userId,
              name: widget.name,
              mobile: widget.mobile,
              booking: booking,
            );
          },
        ),
      );

      // ========================================================
      // PAYMENT SUCCESS
      // ========================================================

      if (paymentResult == true) {
        await loadSeats();

        if (!mounted) return;

        setState(() {
          selectedSeat = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment successful. Seat booked successfully."),
            backgroundColor: Colors.green,
          ),
        );

        // ======================================================
        // GO TO DASHBOARD
        // ======================================================

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
      } else {
        // ======================================================
        // PAYMENT CANCELLED / FAILED
        // ======================================================

        await loadSeats();

        if (!mounted) return;

        setState(() {
          selectedSeat = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment cancelled or failed."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isBooking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to create booking: $e"),
          backgroundColor: Colors.red,
        ),
      );

      await loadSeats();
    }
  }
  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshSeats() async {
    setState(() {
      selectedSeat = null;
    });

    await loadSeats();
  }

  // ============================================================
  // ADVANCED SUMMARY CARD
  // ============================================================

  Widget _advancedSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADVANCED LEGEND
  // ============================================================

  Widget _advancedLegend({required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
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
    required bool selected,
  }) {
    return GestureDetector(
      onTap: booked || isBooking
          ? null
          : () {
              selectSeat(seat);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: booked
              ? Colors.red.shade50
              : selected
              ? Colors.indigo
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            width: selected ? 2 : 1,
            color: booked
                ? Colors.red.shade300
                : selected
                ? Colors.indigo
                : Colors.green.shade300,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                booked
                    ? Icons.lock_rounded
                    : selected
                    ? Icons.check_circle_rounded
                    : Icons.event_seat_rounded,
                size: 13,
                color: booked
                    ? Colors.red
                    : selected
                    ? Colors.white
                    : Colors.green,
              ),

              const SizedBox(height: 1),

              Text(
                "${seat.seatNumber}",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 1),

              Text(
                booked
                    ? "Booked"
                    : selected
                    ? "Selected"
                    : "Available",
                style: TextStyle(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w500,
                  color: booked
                      ? Colors.red
                      : selected
                      ? Colors.white
                      : Colors.green,
                ),
              ),
            ],
          ),
        ),
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
      drawer: AppDrawer(
        userId: widget.userId,
        name: widget.name,
        mobile: widget.mobile,
        selectedPage: "Seat Booking",
      ),
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;

            // Desktop = 10
            // Tablet  = 6
            // Mobile  = 4
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
                    // HERO HEADER
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
                    // SUMMARY
                    // =================================================
                    Row(
                      children: [
                        Expanded(
                          child: _advancedSummaryCard(
                            icon: Icons.event_seat_rounded,
                            title: "Available Seats",
                            value: availableSeats.toString(),
                            subtitle: "Ready to book",
                            iconColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _advancedSummaryCard(
                            icon: Icons.lock_rounded,
                            title: "Booked Seats",
                            value: bookedSeats.toString(),
                            subtitle: "Currently reserved",
                            iconColor: Colors.red,
                          ),
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
                        const Column(
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
                              "Available seats are shown in green",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          _advancedLegend(
                            color: Colors.green,
                            text: "Available",
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
                        padding: const EdgeInsets.all(8),
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                                childAspectRatio: 1.0,
                              ),
                          itemBuilder: (context, index) {
                            final Seat seat = seats[index];

                            final bool booked =
                                seat.status.toUpperCase() == "BOOKED";

                            final bool selected =
                                selectedSeat == seat.seatNumber;

                            return _seatCard(
                              seat: seat,
                              booked: booked,
                              selected: selected,
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                                childAspectRatio: 1.0,
                              ),
                          itemBuilder: (context, index) {
                            final Seat seat = seats[index];

                            final bool booked =
                                seat.status.toUpperCase() == "BOOKED";

                            final bool selected =
                                selectedSeat == seat.seatNumber;

                            return _seatCard(
                              seat: seat,
                              booked: booked,
                              selected: selected,
                            );
                          },
                        ),
                      ),

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
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Selected Seat",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          "Ready for booking",
                                          style: TextStyle(
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
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedSeat == null
                                        ? "Select a Seat"
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
                    // RAZORPAY SECURITY
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
