import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prepal2/presentation/providers/business_provider.dart';
import 'package:prepal2/presentation/widgets/shared_button.dart';
import 'package:prepal2/presentation/screens/inventory/add_product_screen.dart';
import 'package:prepal2/core/constants/app_colors.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _locationController = TextEditingController(); // renamed from contactAddress
  final _contactNumberController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isSaving = false;
  bool _isNextLoading = false;

  // API confirmed businessType values
  String _selectedBusinessType = 'Cafe';
  final List<String> _businessTypes = [
    'Cafe',
    'Restaurant',
    'Bakery',
    'Catering',
    'Food Truck',
    'Home Kitchen',
    'Others'
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _locationController.dispose();
    _contactNumberController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool navigateAfter = true}) async {
    if (!_formKey.currentState!.validate()) return;

    if (navigateAfter) {
      setState(() => _isNextLoading = true);
    } else {
      setState(() => _isSaving = true);
    }

    final success = await context.read<BusinessProvider>().registerBusiness(
          businessName: _businessNameController.text.trim(),
          businessType: _selectedBusinessType,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : 'Not provided',
          contactNumber: _contactNumberController.text.trim(),
          website: _websiteController.text.trim(),
        );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isNextLoading = false;
      });
    }

    if (success && mounted && navigateAfter) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddProductScreen()),
      );
    } else if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business details saved ✅'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Progress bar (3 steps total)
                Row(
                  children: List.generate(
                      3,
                      (i) => Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: i <= 1
                                    ? AppColors.secondary
                                    : AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                          )),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Business details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Business Name
                _buildField(
                  label: 'Business name',
                  hint: 'Deliciousness delight',
                  controller: _businessNameController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                  onChanged: (_) => provider.clearError(),
                ),
                const SizedBox(height: 24),

                // Contact Address
                _buildField(
                  label: 'Contact address',
                  hint: '25, Tomash money close, Mushin, Lagos.',
                  controller: _locationController,
                  onChanged: (_) => provider.clearError(),
                ),
                const SizedBox(height: 24),

                // Business Type & Contact Number row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Business type',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBusinessType,
                            isExpanded: true,
                            decoration: _inputDecoration('', isFocused: false),
                            items: _businessTypes
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedBusinessType = v);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        label: 'Contact number',
                        hint: '+123 456 7890',
                        controller: _contactNumberController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => provider.clearError(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Website
                _buildField(
                  label: 'Website',
                  hint: 'www.delciousness.ic',
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => provider.clearError(),
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: 'Save',
                        type: ButtonType.secondary, // Light green
                        onPressed: () => _submit(navigateAfter: false),
                        isLoading: _isSaving,
                      ),
                    ),
                    const SizedBox(width: 60), // Larger gap as per mockup
                    Expanded(
                      child: PrimaryButton(
                        text: 'Next',
                        type: ButtonType.primary, // Dark green
                        onPressed: () => _submit(navigateAfter: true),
                        isLoading: _isNextLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() {}),
      child: Builder(builder: (context) {
        final hasFocus = Focus.of(context).hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: onChanged,
              validator: validator,
              decoration: _inputDecoration(hint, isFocused: hasFocus),
            ),
          ],
        );
      }),
    );
  }

  InputDecoration _inputDecoration(String hint, {required bool isFocused}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.gray),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
