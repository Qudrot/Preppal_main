import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prepal2/data/models/inventory/product_model.dart';
import 'package:prepal2/presentation/providers/inventory_provider.dart';
import 'package:prepal2/core/constants/app_colors.dart';
import 'package:prepal2/presentation/widgets/shared_button.dart';
import 'package:prepal2/presentation/screens/sales/daily_sales_report_screen.dart';

class AddProductScreen extends StatefulWidget {
  final bool isOnboarding;
  const AddProductScreen({super.key, this.isOnboarding = false});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _thresholdController = TextEditingController(); // optional
  final _priceController = TextEditingController();

  bool _isSaving = false;
  bool _isSubmitLoading = false;

  ProductCategory _selectedCategory = ProductCategory.others;
  ProductUnit _selectedUnit = ProductUnit.pcs;

  // currencies used in dropdown; backend doesn't persist currency yet but
  // the UI allows selection for future use.
  final List<String> _currencies = ['NGN', 'USD'];
  String _selectedCurrency = 'NGN';

  DateTime _productionDate = DateTime.now();
  final _shelfLifeController = TextEditingController(text: '168'); // hours

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _priceController.dispose();
    _shelfLifeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _productionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFD32F2F),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _productionDate = picked;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _quantityController.clear();
    _thresholdController.clear();
    _priceController.clear();
    // Reset defaults
    setState(() {
      _selectedCategory = ProductCategory.others;
      _selectedUnit = ProductUnit.pcs;
      _productionDate = DateTime.now();
      _shelfLifeController.text = '168';
    });
  }

  Future<void> _handleSubmit({bool isSubmit = true}) async {
    print('AddProductScreen: handleSubmit tapped (isSubmit: $isSubmit)');

    if (!_formKey.currentState!.validate()) return;

    // ensure shelf life is non-negative integer
    final shelfLifeStr = _shelfLifeController.text.trim();
    final shelfLife = int.tryParse(shelfLifeStr) ?? -1;
    if (shelfLife < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shelf life must be zero or more hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isSubmit) {
      setState(() => _isSubmitLoading = true);
    } else {
      setState(() => _isSaving = true);
    }

    final product = ProductModel(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      productionDate: _productionDate,
      shelfLife: shelfLife,
      quantityAvailable: double.tryParse(_quantityController.text) ?? 0.0,
      price: double.tryParse(_priceController.text) ?? 0.0,
      shelf: 0,
      unit: _selectedUnit,
      currency: _selectedCurrency,
      lowStockThreshold: _thresholdController.text.isEmpty
          ? null
          : double.tryParse(_thresholdController.text),
    );

    print(
        'Adding product: ${product.name}, quantity ${product.quantityAvailable}, shelfLife ${product.shelfLife}');

    final success = await context.read<InventoryProvider>().addProduct(product);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isSubmitLoading = false;
      });
    }

    print('AddProductScreen: addProduct returned $success');

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      if (isSubmit) {
        if (widget.isOnboarding) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DailySalesReportScreen(
                isOnboarding: true,
              ),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      } else {
        // "Save" or "Add another" was clicked. Clear form for next entry.
        _clearForm();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<InventoryProvider>().errorMessage ??
              'Error adding product'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                if (widget.isOnboarding) ...[
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
                ],

                const Text(
                  'Inventory details',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // Product Name
                _buildField(
                  label: 'Product name',
                  hint: 'Whole milk',
                  controller: _nameController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Row: Product type | Production date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Product type',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<ProductCategory>(
                            value: _selectedCategory,
                            isExpanded: true,
                            decoration: _inputDecoration('Coffee', isFocused: false),
                            items: ProductCategory.values.map((cat) {
                              return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.name[0].toUpperCase() +
                                      cat.name.substring(1)));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DatePickerField(
                        label: 'Production date',
                        date: _productionDate,
                        onTap: _pickDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row: Quantity produced | Unit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Quantity produced',
                        hint: '50',
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Unit',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<ProductUnit>(
                            value: _selectedUnit,
                            isExpanded: true,
                            decoration: _inputDecoration('pcs', isFocused: false),
                            items: ProductUnit.values.map((u) {
                              return DropdownMenuItem(
                                  value: u, child: Text(u.name.toUpperCase()));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedUnit = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row: Price per unit | currency
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Price per unit',
                        hint: '500',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('currency',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            isExpanded: true,
                            decoration: _inputDecoration('NGN', isFocused: false),
                            items: _currencies
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCurrency = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row: Shelf life | unit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Shelf life',
                        hint: '168',
                        controller: _shelfLifeController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('unit',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: 'hour(s)',
                            isExpanded: true,
                            decoration: _inputDecoration('hour(s)', isFocused: false),
                            items: const [
                              DropdownMenuItem(
                                  value: 'hour(s)', child: Text('hour(s)'))
                            ],
                            onChanged: (val) {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Action Buttons
                if (widget.isOnboarding)
                  Column(
                    children: [
                      PrimaryButton(
                        text: 'Add another product',
                        type: ButtonType.secondary,
                        icon: Icons.add_circle_outline,
                        onPressed: () => _handleSubmit(isSubmit: false),
                        isLoading: _isSaving,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: 'Save',
                              type: ButtonType.secondary,
                              onPressed: () => _handleSubmit(isSubmit: false),
                              isLoading: _isSaving,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PrimaryButton(
                              text: 'Next',
                              type: ButtonType.primary,
                              onPressed: () => _handleSubmit(isSubmit: true),
                              isLoading: _isSubmitLoading,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      PrimaryButton(
                        text: 'Add another product',
                        type: ButtonType.secondary,
                        icon: Icons.add_circle_outline,
                        onPressed: () => _handleSubmit(isSubmit: false),
                        isLoading: _isSaving,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'Save product',
                        type: ButtonType.primary,
                        onPressed: () => _handleSubmit(isSubmit: true),
                        isLoading: _isSubmitLoading,
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
    TextInputType? keyboardType,
  }) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() {}),
      child: Builder(builder: (context) {
        final hasFocus = Focus.of(context).hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
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
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5)),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.black),
                const SizedBox(width: 8),
                Text(
                  '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
