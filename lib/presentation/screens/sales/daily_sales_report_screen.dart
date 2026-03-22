import 'package:flutter/material.dart';
import 'package:prepal2/core/constants/app_colors.dart';
import 'package:prepal2/presentation/widgets/shared_button.dart';
import 'package:prepal2/presentation/providers/daily_sales_provider.dart';
import 'package:prepal2/presentation/providers/inventory_provider.dart';
import 'package:prepal2/presentation/screens/main_shell.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:prepal2/data/models/inventory/product_model.dart';

class DailySalesReportScreen extends StatefulWidget {
  const DailySalesReportScreen({super.key});

  @override
  State<DailySalesReportScreen> createState() => _DailySalesReportScreenState();
}

class _DailySalesReportScreenState extends State<DailySalesReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_SalesEntry> _salesEntries = [_SalesEntry()];

  bool _isSaving = false;
  bool _isSubmitLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<InventoryProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    for (final entry in _salesEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addProductRow() {
    setState(() {
      _salesEntries.add(_SalesEntry());
    });
  }

  void _removeProductRow(int index) {
    if (_salesEntries.length > 1) {
      setState(() {
        _salesEntries[index].dispose();
        _salesEntries.removeAt(index);
      });
    }
  }

  Future<void> _pickDate(_SalesEntry entry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.productionDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.secondary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        entry.productionDate = picked;
      });
    }
  }

  Future<void> _handleAction({required bool isSubmit}) async {
    // Basic validation
    for (final entry in _salesEntries) {
      if (entry.selectedProduct == null || entry.quantitySoldController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a product and enter quantity sold')),
        );
        return;
      }
    }

    setState(() {
      if (isSubmit) _isSubmitLoading = true;
      else _isSaving = true;
    });

    try {
      bool allSuccess = true;
      final entriesCopy = List<_SalesEntry>.from(_salesEntries);
      
      for (final entry in entriesCopy) {
        final qText = entry.quantitySoldController.text;
        final sText = entry.stockLeftController.text;
        
        if (entry.selectedProduct == null) continue;

        final saleData = {
          'inventoryId': entry.selectedProduct!.id,
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'quantitySold': double.tryParse(qText) ?? 0,
          'stockLeft': double.tryParse(sText) ?? 0,
        };

        final ok = await context.read<DailySalesProvider>().addSale(saleData);
        if (!ok) allSuccess = false;
      }

      if (mounted) {
        setState(() {
          _isSubmitLoading = false;
          _isSaving = false;
        });
        
        if (allSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sales report submitted successfully'),
              backgroundColor: AppColors.secondary,
            ),
          );
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainShell()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<DailySalesProvider>().errorMessage ??
                  'Failed to submit some sales entries'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitLoading = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: List.generate(
                    3,
                    (i) => Expanded(
                          child: Container(
                            height: 8,
                            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: i <= 2
                                  ? AppColors.secondary
                                  : AppColors.primary,
                            ),
                          ),
                        )),
              ),
              const SizedBox(height: 32),
              const Text(
                'Daily sales report',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _salesEntries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 32),
                      itemBuilder: (context, index) {
                        return _buildProductEntry(
                            context, _salesEntries[index], index);
                      },
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: 'Add another product',
                      type: ButtonType.secondary,
                      icon: Icons.add_circle_outline,
                      onPressed: _addProductRow,
                      backgroundColor: AppColors.secondary,
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'Save',
                            type: ButtonType.secondary,
                            onPressed: () => _handleAction(isSubmit: false),
                            isLoading: _isSaving,
                          ),
                        ),
                        const SizedBox(width: 60),
                        Expanded(
                          child: PrimaryButton(
                            text: 'Submit',
                            type: ButtonType.primary,
                            onPressed: () => _handleAction(isSubmit: true),
                            isLoading: _isSubmitLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductEntry(
      BuildContext context, _SalesEntry entry, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                const Text('Product name',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Consumer<InventoryProvider>(
                  builder: (context, inventory, _) {
                    final products = inventory.allProducts;
                    return DropdownButtonFormField<ProductModel>(
                      value: entry.selectedProduct,
                      isExpanded: true,
                      decoration: _inputDecoration('Select product', isFocused: false),
                      items: products.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            entry.selectedProduct = val;
                            entry.productType = val.category;
                            entry.unit = val.unit;
                          });
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

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
                            value: entry.productType,
                            isExpanded: true,
                            decoration: _inputDecoration('Select type', isFocused: false),
                            items: ProductCategory.values.map((cat) {
                              return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.name[0].toUpperCase() +
                                      cat.name.substring(1)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => entry.productType = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DatePickerField(
                        label: 'Production date',
                        date: entry.productionDate,
                        onTap: () => _pickDate(entry),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Quantity sold',
                        hint: '0',
                        controller: entry.quantitySoldController,
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
                            value: entry.unit,
                            isExpanded: true,
                            decoration: _inputDecoration('Select unit', isFocused: false),
                            items: ProductUnit.values.map((u) {
                              return DropdownMenuItem(
                                  value: u, child: Text(u.name.toUpperCase()));
                            }).toList(),
                            onChanged: (val) => setState(() => entry.unit = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        const SizedBox(height: 16),

        _buildField(
          label: 'Stock left',
          hint: '50',
          controller: entry.stockLeftController,
          keyboardType: TextInputType.number,
        ),

        if (_salesEntries.length > 1)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _removeProductRow(index),
              icon:
                  const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              label: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ),
      ],
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
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerField(
      {required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.black),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd-MM-yyyy').format(date ?? DateTime.now()),
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

class _SalesEntry {
  ProductModel? selectedProduct;
  ProductCategory productType = ProductCategory.others;
  DateTime? productionDate;
  ProductUnit? unit;
  final TextEditingController quantitySoldController = TextEditingController();
  final TextEditingController stockLeftController = TextEditingController();

  _SalesEntry() : productionDate = DateTime.now();

  void dispose() {
    quantitySoldController.dispose();
    stockLeftController.dispose();
  }
}
