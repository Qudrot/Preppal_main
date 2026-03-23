import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prepal2/data/models/inventory/product_model.dart';
import 'package:prepal2/presentation/providers/inventory_provider.dart';
import 'package:prepal2/presentation/screens/inventory/add_product_screen.dart';
import 'package:prepal2/presentation/screens/inventory/product_detail_screen.dart';
import 'package:prepal2/presentation/screens/sales/daily_sales_report_screen.dart';


class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        title: const Text('Inventory Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        actions: [
          // Filter by category
          PopupMenuButton<ProductCategory?>(
            icon: const Icon(Icons.filter_list),
            onSelected: inventory.setCategory,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Categories'),
              ),
              ...ProductCategory.values.map(
                (cat) => PopupMenuItem(
                  value: cat,
                  child: Text(
                    cat.name[0].toUpperCase() +
                        cat.name.substring(1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: inventory.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
            ),
          ),
          
          // ── Summary Chips ────────────────────────────────
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildSummaryCard('Total', inventory.totalProducts.toString(), Colors.blue),
                _buildSummaryCard('Low Stock', inventory.lowStockProducts.length.toString(), Colors.orange),
                _buildSummaryCard('Out of Stock', inventory.outOfStockProducts.length.toString(), Colors.red),
                _buildSummaryCard('Optimal', inventory.optimalProducts.length.toString(), Colors.green),
              ],
            ),
          ),

          // ── Product List ──────────────────────────────────
          Expanded(
            child: (inventory.isLoading && inventory.filteredProducts.isEmpty)
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD32F2F),
                    ),
                  )
                : inventory.filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No products found',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed:
                                  inventory.clearFilters,
                              child:
                                  const Text('Clear filters'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                        itemCount: inventory
                            .filteredProducts.length,
                        itemBuilder:
                            (context, index) {
                          final product =
                              inventory.filteredProducts[
                                  index];

                          return _ProductCard(
                            product: product,
                            onTap: () =>
                                Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(
                                  product: product,
                                ),
                              ),
                            ),
                            onDelete: () async {
                              final confirm =
                                  await _showDeleteDialog(
                                      context);
                              if (confirm == true) {
                                await inventory
                                    .deleteProduct(
                                        product.id);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),

      // Add product FAB
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () =>
            Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AddProductScreen(),
          ),
        ),
        backgroundColor:
            const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog(
      BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
            'Are you sure you want to remove this product?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Product Card ───────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final qty = product.quantityAvailable;
    final maxQty = product.effectiveThreshold * 3;
    final fillFraction = (qty / (maxQty > 0 ? maxQty : 1)).clamp(0.0, 1.0);
    
    // Status text & color
    String statusText = 'Optimal';
    Color statusColor = Colors.green;
    if (qty <= 0) {
      statusText = 'Out of Stock';
      statusColor = Colors.red;
    } else if (product.isLowStock) {
      statusText = 'Low Stock';
      statusColor = Colors.orange;
    } else if (qty > product.effectiveThreshold * 3) {
      statusText = 'Over Stock';
      statusColor = Colors.blue;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.category.name[0].toUpperCase()}${product.category.name.substring(1)} • $qty ${product.unit.name}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        // Stock Indicator Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Stock Level', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                Text('${qty.toStringAsFixed(0)} / ${product.effectiveThreshold.toStringAsFixed(0)} Min', 
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: fillFraction,
                                backgroundColor: Colors.grey.shade200,
                                color: statusColor,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Price and Date info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${product.currency} ${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFD32F2F)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prod: ${product.productionDate.day}/${product.productionDate.month}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: onDelete,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(top: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom Action CTA
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailySalesReportScreen(initialProduct: product),
                    ),
                  );
                },
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_shopping_cart, size: 16, color: Color(0xFF1B6B50)),
                      SizedBox(width: 8),
                      Text(
                        'Add daily sales',
                        style: TextStyle(
                          color: Color(0xFF1B6B50),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
