import 'package:flutter/material.dart';
import '../services/library_service.dart';

class CreateLibraryPage extends StatefulWidget {
  @override
  _CreateLibraryPageState createState() => _CreateLibraryPageState();
}

class _CreateLibraryPageState extends State<CreateLibraryPage> {
  final _formKey = GlobalKey<FormState>();
  
  String libraryName = '';
  String address = '';
  String contactNumber = '';
  String ownerName = '';
  String ownerMobile = '';
  String ownerPassword = '';
  int seatCapacity = 50;
  double fullFee = 1000.0;
  double concessionalFee = 700.0;

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      await LibraryService.createLibrary({
        "libraryName": libraryName,
        "address": address,
        "contactNumber": contactNumber,
        "ownerName": ownerName,
        "ownerMobile": ownerMobile,
        "ownerPassword": ownerPassword,
        "seatCapacity": seatCapacity,
        "fullFee": fullFee,
        "concessionalFee": concessionalFee,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Library created successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create New Library')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Library Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Library Name', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => libraryName = v!,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => address = v!,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => contactNumber = v!,
                    ),
                    SizedBox(height: 20),
                    Text('Fee & Capacity Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Seat Capacity', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            initialValue: '50',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            onSaved: (v) => seatCapacity = int.parse(v!),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Full Fee (₹)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            initialValue: '1000',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            onSaved: (v) => fullFee = double.parse(v!),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Concessional Fee (₹)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            initialValue: '700',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            onSaved: (v) => concessionalFee = double.parse(v!),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text('Owner Credentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => ownerName = v!,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Owner Mobile', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => ownerMobile = v!,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Owner Password', border: OutlineInputBorder()),
                      obscureText: true,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      onSaved: (v) => ownerPassword = v!,
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text('Create Library', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
