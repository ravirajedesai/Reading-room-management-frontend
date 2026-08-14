import 'package:flutter/material.dart';

import '../services/student_service.dart';

class AddStudentPage extends StatefulWidget {
  final int userId;

  const AddStudentPage({super.key, required this.userId});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final TextEditingController cityController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  bool loading = false;

  // ==========================================================
  // ADD STUDENT
  // ==========================================================

  Future<void> addStudent() async {
    final city = cityController.text.trim();

    final address = addressController.text.trim();

    // ========================================================
    // VALIDATION
    // ========================================================

    if (city.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter city and address")),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // ======================================================
      // CALL BACKEND
      // ======================================================

      await StudentService.addStudent(
        userId: widget.userId,
        city: city,
        address: address,
      );

      if (!mounted) return;

      // ======================================================
      // SUCCESS
      // ======================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Student added successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // Return to previous page.
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add student: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
    cityController.dispose();

    addressController.dispose();

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
          "Add Student",
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
            const SizedBox(height: 20),

            // ==================================================
            // HEADER
            // ==================================================
            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.indigo.shade50,

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.person_add,
                size: 50,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Student Details",
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            const Text(
              "Complete your profile before booking a seat",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // CITY
            // ==================================================
            TextField(
              controller: cityController,

              textCapitalization: TextCapitalization.words,

              decoration: InputDecoration(
                labelText: "City",

                hintText: "Enter city",

                prefixIcon: const Icon(Icons.location_city),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // ADDRESS
            // ==================================================
            TextField(
              controller: addressController,

              maxLines: 3,

              textCapitalization: TextCapitalization.sentences,

              decoration: InputDecoration(
                labelText: "Address",

                hintText: "Enter complete address",

                prefixIcon: const Icon(Icons.home),

                alignLabelWithHint: true,

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // ADD STUDENT BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,

              height: 52,

              child: ElevatedButton(
                onPressed: loading ? null : addStudent,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,

                  foregroundColor: Colors.white,

                  disabledBackgroundColor: Colors.grey.shade300,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "ADD STUDENT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
