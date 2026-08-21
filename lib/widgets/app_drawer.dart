import 'package:flutter/material.dart';

import '../screens/dashboard_page.dart';
import '../screens/owner_dashboard_page.dart';
import '../screens/student_page.dart';
import '../screens/seat_booking_page.dart';
import '../screens/paid_students_page.dart';
import '../screens/payment_history_page.dart';
import '../screens/login_page.dart';
import '../services/session_service.dart';
import '../screens/owner_pending_payments_page.dart';
import '../screens/owner_pending_seats_page.dart';

class AppDrawer extends StatelessWidget {
  final int userId;
  final String name;
  final String mobile;
  final String selectedPage;
  final String role;

  const AppDrawer({
    super.key,
    required this.userId,
    required this.name,
    required this.mobile,
    required this.selectedPage,
    required this.role,
  });

  // =============================================================
  // CHECK OWNER
  // =============================================================

  bool get isOwner => role.trim().toUpperCase() == 'OWNER';

  // =============================================================
  // NAVIGATION HELPERS
  // =============================================================

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pop();

    if (selectedPage == 'Dashboard') return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) {
          if (isOwner) {
            return OwnerDashboardPage(
              userId: userId,
              name: name,
              mobile: mobile,
            );
          }

          return DashboardPage(userId: userId, name: name, mobile: mobile);
        },
      ),
      (route) => false,
    );
  }

  void _goToPendingPaymentRequests(BuildContext context) {
    Navigator.of(context).pop();

    if (selectedPage == 'Pending Payment Requests') return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OwnerPendingPaymentsPage(
          userId: userId,
          name: name,
          mobile: mobile,
          role: role,
        ),
      ),
      (route) => false,
    );
  }

  void _goToStudentPage(BuildContext context) {
    Navigator.of(context).pop();

    if (selectedPage == 'Student Profile') return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => StudentPage(userId: userId, name: name, mobile: mobile),
      ),
      (route) => false,
    );
  }

  void _goToSeatBooking(BuildContext context) {
    Navigator.of(context).pop();

    if (selectedPage == 'Seat Booking') return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            SeatBookingPage(userId: userId, name: name, mobile: mobile),
      ),
      (route) => false,
    );
  }

  void _goToPendingSeats(BuildContext context) {
    Navigator.of(context).pop();

    if (selectedPage == 'Pending Seats' || selectedPage == 'Waiting Seats') {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OwnerPendingSeatsPage(
          userId: userId,
          name: name,
          mobile: mobile,
          role: role,
        ),
      ),
      (route) => false,
    );
  }

  void _goToPaidStudents(BuildContext context) {
    Navigator.of(context).pop();

    if (selectedPage == 'Paid Students') return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PaidStudentsPage(
          userId: userId,
          name: name,
          mobile: mobile,
          role: role,
        ),
      ),
      (route) => false,
    );
  }

  void _goToPaymentHistory(BuildContext context) {
    Navigator.of(context).pop();

    if (selectedPage == 'Search Payment History') return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PaymentHistoryPage(
          userId: userId,
          name: name,
          mobile: mobile,
          role: role,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.of(context).pop();

    await SessionService.logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ===================================================
            // USER HEADER
            // ===================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4054C7), Color(0xFF6576D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      name.trim().isNotEmpty
                          ? name.trim()[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF4054C7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name.isNotEmpty ? name : 'User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mobile.isNotEmpty ? mobile : '-',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOwner
                              ? Icons.admin_panel_settings_outlined
                              : Icons.person_outline_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isOwner ? 'Owner' : 'Student',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ===================================================
            // SCROLLABLE NAVIGATION ITEMS
            // ===================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Dashboard
                  _drawerItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    selected: selectedPage == 'Dashboard',
                    onTap: () => _goToDashboard(context),
                  ),

                  // Owner Options
                  if (isOwner) ...[
                    _drawerItem(
                      context,
                      icon: Icons.pending_actions_rounded,
                      title: 'Pending Payment Requests',
                      selected: selectedPage == 'Pending Payment Requests',
                      onTap: () => _goToPendingPaymentRequests(context),
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.people_alt_rounded,
                      title: 'Paid Students',
                      selected: selectedPage == 'Paid Students',
                      onTap: () => _goToPaidStudents(context),
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.history_rounded,
                      title: 'Search Payment History',
                      selected: selectedPage == 'Search Payment History',
                      onTap: () => _goToPaymentHistory(context),
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.event_seat_rounded,
                      title: 'Pending Seats',
                      selected: selectedPage == 'Pending Seats',
                      onTap: () => _goToPendingSeats(context),
                    ),
                  ],

                  // Student Options
                  if (!isOwner) ...[
                    _drawerItem(
                      context,
                      icon: Icons.people_alt_rounded,
                      title: 'Student Profile',
                      selected: selectedPage == 'Student Profile',
                      onTap: () => _goToStudentPage(context),
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.event_seat_rounded,
                      title: 'Seat Booking',
                      selected: selectedPage == 'Seat Booking',
                      onTap: () => _goToSeatBooking(context),
                    ),
                  ],
                ],
              ),
            ),

            // ===================================================
            // FOOTER ITEMS (Settings, Logout, Version)
            // ===================================================
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 6),

            _drawerItem(
              context,
              icon: Icons.settings_rounded,
              title: 'Settings',
              selected: selectedPage == 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),

            _drawerItem(
              context,
              icon: Icons.logout_rounded,
              title: 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () => _logout(context),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Reading Room Management\nVersion 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // DRAWER ITEM
  // =============================================================

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF1FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ListTile(
            dense: true,
            leading: Icon(
              icon,
              color:
                  iconColor ??
                  (selected ? const Color(0xFF4054C7) : Colors.grey.shade700),
            ),
            title: Text(
              title,
              style: TextStyle(
                color:
                    textColor ??
                    (selected
                        ? const Color(0xFF4054C7)
                        : const Color(0xFF303746)),
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
