import 'package:flutter/material.dart';

import '../services/student_service.dart';

class SearchStudentPage extends StatefulWidget {
  const SearchStudentPage({super.key});

  @override
  State<SearchStudentPage> createState() => _SearchStudentPageState();
}

class _SearchStudentPageState extends State<SearchStudentPage> {
  final TextEditingController mobileController = TextEditingController();

  Map<String, dynamic>? student;

  bool loading = false;

  String? error;

  // ==========================================================
  // SEARCH STUDENT
  // ==========================================================

  Future<void> searchStudent() async {
    final mobile = mobileController.text.trim();

    if (mobile.isEmpty) {
      setState(() {
        error = "Please enter mobile number";
        student = null;
      });

      return;
    }

    setState(() {
      loading = true;
      error = null;
      student = null;
    });

    try {
      final result = await StudentService.getStudentByMobile(mobile);

      if (!mounted) return;

      setState(() {
        student = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = "Student not found";
        student = null;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        title: const Text(
          "Search Student",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        backgroundColor: Colors.indigo,

        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ==================================================
            // SEARCH FIELD
            // ==================================================
            TextField(
              controller: mobileController,

              keyboardType: TextInputType.phone,

              maxLength: 10,

              onSubmitted: (_) {
                if (!loading) {
                  searchStudent();
                }
              },

              decoration: InputDecoration(
                labelText: "Mobile Number",

                hintText: "Enter 10 digit mobile number",

                prefixIcon: const Icon(Icons.phone),

                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: loading ? null : searchStudent,
                ),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // SEARCH BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,

              height: 50,

              child: ElevatedButton.icon(
                onPressed: loading ? null : searchStudent,

                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),

                label: Text(loading ? "SEARCHING..." : "SEARCH STUDENT"),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ERROR
            // ==================================================
            if (error != null)
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.red.shade50,

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: Colors.red.shade200),
                ),

                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ==================================================
            // STUDENT
            // ==================================================
            if (student != null) _studentCard(student!),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // STUDENT CARD
  // ==========================================================

  Widget _studentCard(Map<String, dynamic> student) {
    final user = student["users"] ?? {};

    final name = user["name"] ?? "Unknown";

    final mobile = user["mobile"] ?? "Unknown";

    final city = student["city"] ?? "";

    final address = student["address"] ?? "";

    return Card(
      elevation: 4,

      margin: const EdgeInsets.only(top: 20),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // PROFILE
            // ==================================================
            const Center(
              child: CircleAvatar(
                radius: 35,

                backgroundColor: Colors.indigo,

                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),

            const SizedBox(height: 15),

            Center(
              child: Text(
                name.toString(),

                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Center(
              child: Text(
                mobile.toString(),

                style: const TextStyle(color: Colors.grey),
              ),
            ),

            const Divider(height: 30),

            // ==================================================
            // MOBILE
            // ==================================================
            _infoRow(
              icon: Icons.phone,
              title: "Mobile",
              value: mobile.toString(),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // CITY
            // ==================================================
            _infoRow(
              icon: Icons.location_city,
              title: "City",
              value: city.toString(),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // ADDRESS
            // ==================================================
            _infoRow(
              icon: Icons.home,
              title: "Address",
              value: address.toString(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // INFO ROW
  // ==========================================================

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          padding: const EdgeInsets.all(9),

          decoration: BoxDecoration(
            color: Colors.indigo.shade50,

            borderRadius: BorderRadius.circular(9),
          ),

          child: Icon(icon, color: Colors.indigo, size: 20),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 2),

              Text(
                value.isEmpty ? "Not available" : value,

                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
