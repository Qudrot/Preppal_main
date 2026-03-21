import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prepal2/core/constants/app_colors.dart';
import 'package:prepal2/presentation/widgets/shared_button.dart';
import 'package:prepal2/presentation/providers/inventory_provider.dart';
import 'package:prepal2/data/models/inventory/product_model.dart';

class DailySalesReportScreen extends StatefulWidget {
  const DailySalesReportScreen({super.key});

  @override
  State<DailySalesReportScreen> createState() => _DailySalesReportScreenState();
}

class _DailySalesReportScreenState extends State<DailySalesReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_SalesEntry> _salesEntries = [_SalesEntry()];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<InventoryProvider>().loadProducts();
    });
  }

  void _addProductRow() {
    setState(() {
      _salesEntries.add(_SalesEntry());
    });
  }

  void _removeProductRow(int index) {
    setState(() {
      _salesEntries.removeAt(index);
    });
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sales report saved successfully'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sales report submitted successfully'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Prepal',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: index < 3
                            ? AppColors.secondary
                            : AppColors.lightGray,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Center(
                child: Text(
                  'Daily sales report',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Consumer<InventoryProvider>(
                builder: (context, inv, child) {
                  if (inv.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
                  }
                  final products = inv.allProducts;
                  if (products.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Please add products to your inventory before creating a sales report.'),
                      ),
                    );
                  }

                  return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product entries
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _salesEntries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        return _buildProductEntry(
                          context,
                          _salesEntries[index],
                          index,
                          products,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Add another product button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _addProductRow,
                        icon: const Icon(Icons.add),
                        label: const Text('Add another product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD35A2A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Save and Submit buttons
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'Save',
                            type: ButtonType.tertiary,
                            onPressed: _handleSave,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PrimaryButton(
                            text: 'Submit',
                            onPressed: _handleSubmit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductEntry(
    BuildContext context,
    _SalesEntry entry,
    int index,
    List<ProductModel> products,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name
        const Text(
          'Product name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ProductModel>(
          value: entry.selectedProduct,
          decoration: InputDecoration(
            hintText: 'Select a product',
            filled: true,
            fillColor: const Color(0xFFE8DEF8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: products
              .map((product) => DropdownMenuItem(
                    value: product,
                    child: Text(product.name),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              entry.selectedProduct = value;
            });
          },
          validator: (value) => value == null ? 'Please select a product' : null,
        ),
        const SizedBox(height: 16),

        // Product type and Production date (Side by side)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: entry.selectedProduct != null 
                        ? entry.selectedProduct!.category.name.toUpperCase()
                        : '',
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: '-',
                      filled: true,
                      fillColor: const Color(0xFFEEEEEE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Production date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ValueKey('date_${entry.selectedProduct?.id}'),
                    initialValue: entry.selectedProduct != null
                        ? '${entry.selectedProduct!.productionDate.day.toString().padLeft(2, '0')}-${entry.selectedProduct!.productionDate.month.toString().padLeft(2, '0')}-${entry.selectedProduct!.productionDate.year}'
                        : '',
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: '-',
                      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                      filled: true,
                      fillColor: const Color(0xFFEEEEEE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quantity sold and Unit (Side by side)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quantity sold',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: entry.quantitySoldController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '24',
                      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                      filled: true,
                      fillColor: const Color(0xFFE8DEF8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: entry.selectedProduct != null
                        ? entry.selectedProduct!.unit.name.toUpperCase()
                        : '',
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: '-',
                      filled: true,
                      fillColor: const Color(0xFFEEEEEE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stock left
        const Text(
          'Current stock',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('stock_${entry.selectedProduct?.id}'),
          initialValue: entry.selectedProduct != null
              ? '${entry.selectedProduct!.quantityAvailable} ${entry.selectedProduct!.unit.name.toUpperCase()}'
              : '',
          readOnly: true,
          decoration: InputDecoration(
            hintText: '-',
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
            filled: true,
            fillColor: const Color(0xFFEEEEEE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        // Remove button if multiple entries
        if (_salesEntries.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton(
              onPressed: () => _removeProductRow(index),
              child: const Text(
                'Remove this item',
                style: TextStyle(color: Color(0xFFD32F2F)),
              ),
            ),
          ),
      ],
    );
  }
}

class _SalesEntry {
  ProductModel? selectedProduct;
  final TextEditingController quantitySoldController = TextEditingController();
}
