import 'package:flutter/material.dart';
import '../models/library_model.dart';
import '../services/library_service.dart';
import '../services/session_service.dart';
import 'dashboard_page.dart';
import 'join_library_page.dart';
import 'login_page.dart';

class LibrarySelectionPage extends StatefulWidget {
  @override
  _LibrarySelectionPageState createState() => _LibrarySelectionPageState();
}

class _LibrarySelectionPageState extends State<LibrarySelectionPage> {
  bool _isLoading = true;
  List<LibraryModel> _libraries = [];

  @override
  void initState() {
    super.initState();
    _fetchLibraries();
  }

  Future<void> _fetchLibraries() async {
    try {
      final libraries = await LibraryService.getMyLibraries();
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
          SnackBar(content: Text('Error loading libraries: $e')),
        );
      }
    }
  }

  Future<void> _selectLibrary(LibraryModel library) async {
    await SessionService.saveActiveLibrary(
      id: library.id,
      name: library.name,
      address: library.address,
      code: library.libraryCode,
    );
    final userId = await SessionService.getUserId();
    final name = await SessionService.getName();
    final mobile = await SessionService.getMobile();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardPage(
        userId: userId ?? 0,
        name: name ?? '',
        mobile: mobile ?? '',
      )),
    );
  }

  Future<void> _logout() async {
    await SessionService.logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
        title: Text('Select Library'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _libraries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('You have not joined any libraries yet.'),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => JoinLibraryPage()),
                          );
                        },
                        child: Text('Join a Library'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _libraries.length,
                  itemBuilder: (context, index) {
                    final library = _libraries[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(library.name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(library.address),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () => _selectLibrary(library),
                      ),
                    );
                  },
                ),
      floatingActionButton: _libraries.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JoinLibraryPage()),
                );
              },
              icon: Icon(Icons.qr_code_scanner),
              label: Text('Join Another'),
            )
          : null,
    );
  }
}

