import 'package:flutter/material.dart';

import '../services/student_service.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  late Future<List<dynamic>> students;

  @override
  void initState() {
    super.initState();

    students = StudentService.getAllStudents();
  }

  // ==========================================================
  // REFRESH STUDENTS
  // ==========================================================

  Future<void> refreshStudents() async {
    setState(() {
      students = StudentService.getAllStudents();
    });

    await students;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        title: const Text("Students"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      body: FutureBuilder<List<dynamic>>(
        future: students,

        builder: (context, snapshot) {
          // ====================================================
          // LOADING
          // ====================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ====================================================
          // ERROR
          // ====================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 55,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Failed to load students",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 18),

                    ElevatedButton.icon(
                      onPressed: refreshStudents,
                      icon: const Icon(Icons.refresh),
                      label: const Text("RETRY"),
                    ),
                  ],
                ),
              ),
            );
          }

          // ====================================================
          // DATA
          // ====================================================

          final data = snapshot.data ?? [];

          // ====================================================
          // EMPTY
          // ====================================================

          if (data.isEmpty) {
            return RefreshIndicator(
              onRefresh: refreshStudents,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                children: const [
                  SizedBox(height: 200),

                  Icon(Icons.people_outline, size: 60, color: Colors.indigo),

                  SizedBox(height: 15),

                  Center(
                    child: Text(
                      "No students registered",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // ====================================================
          // STUDENT LIST
          // ====================================================

          return RefreshIndicator(
            onRefresh: refreshStudents,

            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(15),

              itemCount: data.length,

              itemBuilder: (context, index) {
                final student = data[index];

                final user = student["users"] ?? {};

                final name = user["name"] ?? "Unknown";

                final mobile = user["mobile"] ?? "No mobile";

                final city = student["city"] ?? "";

                final address = student["address"] ?? "";

                return Card(
                  elevation: 3,

                  margin: const EdgeInsets.only(bottom: 12),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),

                    leading: const CircleAvatar(
                      radius: 28,

                      backgroundColor: Colors.indigo,

                      child: Icon(Icons.person, color: Colors.white),
                    ),

                    title: Text(
                      name.toString(),

                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            "Mobile: "
                            "${mobile.toString()}",
                          ),

                          const SizedBox(height: 3),

                          Text(
                            "City: "
                            "${city.toString()}",
                          ),

                          const SizedBox(height: 3),

                          Text(
                            "Address: "
                            "${address.toString()}",
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
