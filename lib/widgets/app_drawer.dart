import 'package:flutter/material.dart';

import '../screens/dashboard_page.dart';
import '../screens/owner_dashboard_page.dart'; // ✅ added
import '../screens/student_page.dart';
import '../screens/seat_booking_page.dart';
import '../screens/login_page.dart';
import '../services/session_service.dart'; // ✅ added

class AppDrawer extends StatelessWidget {
  final int userId;
  final String name;
  final String mobile;
  final String selectedPage;
  final String role; // ✅ added

  const AppDrawer({
    super.key,
    required this.userId,
    required this.name,
    required this.mobile,
    required this.selectedPage,
    required this.role, // ✅ added
  });

  // =============================================================
  // NAVIGATE TO DASHBOARD
  // =============================================================

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pop();

    if (selectedPage == "Dashboard") return;

    // ✅ Route to correct dashboard based on role
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => role.toUpperCase() == 'OWNER'
            ? OwnerDashboardPage(userId: userId, name: name, mobile: mobile)
            : DashboardPage(userId: userId, name: name, mobile: mobile),
      ),
      (route) => false,
    );
  }

  // =============================================================
  // NAVIGATE TO STUDENT PAGE
  // =============================================================

  void _goToStudentPage(BuildContext context) {
    Navigator.of(context).pop();

    if (selectedPage == "Student Management") return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => StudentPage(userId: userId, name: name, mobile: mobile),
      ),
      (route) => false,
    );
  }

  // =============================================================
  // NAVIGATE TO SEAT BOOKING
  // =============================================================

  void _goToSeatBooking(BuildContext context) {
    Navigator.of(context).pop();

    if (selectedPage == "Seat Booking") return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            SeatBookingPage(userId: userId, name: name, mobile: mobile),
      ),
      (route) => false,
    );
  }

  // =============================================================
  // LOGOUT
  // =============================================================

  void _logout(BuildContext context) async {
    Navigator.of(context).pop();

    await SessionService.logout(); // ✅ clear session on logout

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
    final isOwner = role.toUpperCase() == 'OWNER';

    return Drawer(
      backgroundColor: Colors.white,

      child: SafeArea(
        child: Column(
          children: [
            // =====================================================
            // HEADER
            // =====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 25),

              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4054C7), Color(0xFF6576D8)],
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 25,
                        color: Color(0xFF4054C7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    name.isNotEmpty ? name : 'User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    mobile,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),

                  const SizedBox(height: 6),

                  // ✅ Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOwner ? 'Owner' : 'Student',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // =====================================================
            // DASHBOARD
            // =====================================================
            _drawerItem(
              context,
              icon: Icons.dashboard_rounded,
              title: 'Dashboard',
              selected: selectedPage == 'Dashboard',
              onTap: () => _goToDashboard(context),
            ),

            // =====================================================
            // STUDENT MANAGEMENT — owner only
            // =====================================================
            if (!isOwner)
              _drawerItem(
                context,
                icon: Icons.people_alt_rounded,
                title: 'Student Management',
                selected: selectedPage == 'Student Management',
                onTap: () => _goToStudentPage(context),
              ),

            // =====================================================
            // SEAT BOOKING — student only
            // =====================================================
            if (!isOwner)
              _drawerItem(
                context,
                icon: Icons.event_seat_rounded,
                title: 'Seat Booking',
                selected: selectedPage == 'Seat Booking',
                onTap: () => _goToSeatBooking(context),
              ),

            const Divider(height: 30, indent: 20, endIndent: 20),

            // =====================================================
            // SETTINGS
            // =====================================================
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

            // =====================================================
            // LOGOUT
            // =====================================================
            _drawerItem(
              context,
              icon: Icons.logout_rounded,
              title: 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () => _logout(context),
            ),

            const Spacer(),

            // =====================================================
            // VERSION
            // =====================================================
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Reading Room Management\nVersion 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
                (selected ? const Color(0xFF4054C7) : const Color(0xFF303746)),
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),

        onTap: onTap,
      ),
    );
  }
}
