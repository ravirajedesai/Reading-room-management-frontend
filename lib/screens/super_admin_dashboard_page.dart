import 'package:flutter/material.dart';
import '../models/library_model.dart';
import '../services/library_service.dart';
import '../services/session_service.dart';
import 'login_page.dart';
import 'create_library_page.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  @override
  _SuperAdminDashboardPageState createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  bool _isLoading = true;
  List<LibraryModel> _libraries = [];

  @override
  void initState() {
    super.initState();
    _fetchLibraries();
  }

  Future<void> _fetchLibraries() async {
    try {
      final libraries = await LibraryService.getAllLibrariesForAdmin();
      if (mounted) {
        setState(() {
          _libraries = libraries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _logout() async {
    await SessionService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _libraries.length,
              itemBuilder: (context, index) {
                final library = _libraries[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(library.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Code: ${library.libraryCode} | Address: ${library.address}'),
                    leading: CircleAvatar(child: Icon(Icons.local_library)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateLibraryPage()),
          );
          if (result == true) {
            setState(() {
              _isLoading = true;
            });
            _fetchLibraries();
          }
        },
        icon: Icon(Icons.add),
        label: Text('Create Library'),
      ),
    );
  }
}
