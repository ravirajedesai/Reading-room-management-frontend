import 'package:flutter/material.dart';
import '../services/library_service.dart';

class CreateLibraryPage extends StatefulWidget {
  const CreateLibraryPage({super.key});

  @override
  State<CreateLibraryPage> createState() => _CreateLibraryPageState();
}

class _CreateLibraryPageState extends State<CreateLibraryPage> {
  final _formKey = GlobalKey<FormState>();

  String libraryName = '';
  String address = '';
  String contactNumber = '';
  int seatCapacity = 50;
  double fullFee = 1000.0;
  double concessionalFee = 700.0;
  String razorpayKeyId = '';
  String razorpayKeySecret = '';

  bool _obscureSecret = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      await LibraryService.createLibrary({
        "libraryName": libraryName.trim(),
        "address": address.trim(),
        "contactNumber": contactNumber.trim(),
        "seatCapacity": seatCapacity,
        "fullFee": fullFee,
        "concessionalFee": concessionalFee,
        "razorpayKeyId": razorpayKeyId.trim(),
        "razorpayKeySecret": razorpayKeySecret.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Library created successfully! You can now assign an owner.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Onboard New Library',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        elevation: 0,
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.indigo),
                  const SizedBox(height: 16),
                  Text(
                    'Setting up library & generating seats...',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade800, Colors.indigo.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_business_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create New Branch',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Automated seat allocation & payment gateway setup',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Section 1: Library Info
                    _buildSectionCard(
                      title: '1. Library Information',
                      icon: Icons.local_library_outlined,
                      iconColor: Colors.blue.shade700,
                      children: [
                        _buildTextField(
                          label: 'Library / Branch Name',
                          hint: 'e.g. Pune Study Center',
                          icon: Icons.business,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Library name is required' : null,
                          onSaved: (v) => libraryName = v ?? '',
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Complete Address',
                          hint: 'e.g. 3rd Floor, Deccan Gymkhana, Pune',
                          icon: Icons.location_on_outlined,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                          onSaved: (v) => address = v ?? '',
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Public Contact Number',
                          hint: 'e.g. 9876543210',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              (v == null || v.trim().length < 10) ? 'Valid 10-digit number required' : null,
                          onSaved: (v) => contactNumber = v ?? '',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 2: Seat Capacity & Pricing
                    _buildSectionCard(
                      title: '2. Capacity & Pricing',
                      icon: Icons.chair_alt_outlined,
                      iconColor: Colors.teal.shade700,
                      children: [
                        _buildTextField(
                          label: 'Total Seat Capacity',
                          hint: 'e.g. 50, 100',
                          icon: Icons.event_seat,
                          keyboardType: TextInputType.number,
                          initialValue: '50',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) return 'Must be greater than 0';
                            return null;
                          },
                          onSaved: (v) => seatCapacity = int.parse(v!),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Full Monthly Fee (₹)',
                                hint: '1000',
                                icon: Icons.currency_rupee,
                                keyboardType: TextInputType.number,
                                initialValue: '1000',
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                                onSaved: (v) => fullFee = double.parse(v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                label: 'Concessional Fee (₹)',
                                hint: '700',
                                icon: Icons.discount_outlined,
                                keyboardType: TextInputType.number,
                                initialValue: '700',
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                                onSaved: (v) => concessionalFee = double.parse(v!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Razorpay Payment Gateway
                    _buildSectionCard(
                      title: '3. Razorpay Payment Gateway',
                      icon: Icons.payment_outlined,
                      iconColor: Colors.deepPurple.shade700,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Student payments for this branch will deposit directly into this Razorpay account.',
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildTextField(
                          label: 'Razorpay Key ID',
                          hint: 'rzp_live_... or rzp_test_...',
                          icon: Icons.vpn_key_outlined,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Razorpay Key ID is required' : null,
                          onSaved: (v) => razorpayKeyId = v ?? '',
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Razorpay Key Secret',
                          hint: 'Private Secret Key',
                          icon: Icons.lock_outline,
                          obscureText: _obscureSecret,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureSecret ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureSecret = !_obscureSecret;
                              });
                            },
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Key Secret is required' : null,
                          onSaved: (v) => razorpayKeySecret = v ?? '',
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_circle_outline, size: 22),
                        label: const Text(
                          'CONFIRM & CREATE LIBRARY',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade800,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onSaved: onSaved,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.indigo.shade600, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo.shade700, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 1.8),
        ),
      ),
    );
  }
}