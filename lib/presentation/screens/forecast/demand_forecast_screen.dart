import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prepal2/presentation/providers/forecast_provider.dart';
import 'package:prepal2/presentation/providers/inventory_provider.dart';
import 'package:prepal2/presentation/providers/business_provider.dart';
import 'package:prepal2/core/constants/app_colors.dart';

class DemandForecastScreen extends StatefulWidget {
  const DemandForecastScreen({super.key});

  @override
  State<DemandForecastScreen> createState() => _DemandForecastScreenState();
}

class _DemandForecastScreenState extends State<DemandForecastScreen> {
  @override
  void initState() {
    super.initState();
    // Load forecast data when screen initializes
    Future.microtask(() {
      final business = context.read<BusinessProvider>().currentBusiness;
      final products = context.read<InventoryProvider>().allProducts;
      context.read<ForecastProvider>().loadForecastData(
            products: products,
            businessType: business?.businessType ?? 'Cafe',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ForecastProvider>(
      builder: (context, forecastProvider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: AppColors.secondary,
            elevation: 0,
            title: const Text('Demand Forecast',
                style: TextStyle(color: Colors.white)),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
          body: forecastProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                )
              : forecastProvider.status == ForecastStatus.error
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load forecast',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              forecastProvider.errorMessage ?? 'Unknown error',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                final business =
                                    context.read<BusinessProvider>().currentBusiness;
                                final products =
                                    context.read<InventoryProvider>().allProducts;
                                forecastProvider.loadForecastData(
                                  products: products,
                                  businessType:
                                      business?.businessType ?? 'Cafe',
                                );
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // ── Header section with chart ────────────────────────
                          Container(
                            color: AppColors.secondary,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '7-days Demand Forecast',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 220,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: forecastProvider
                                                .sevenDayForecast.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  'No forecast data available',
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13),
                                                ),
                                              )
                                            : BarChart(_buildBarChartData(
                                                forecastProvider.sevenDayForecast)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Legend
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _LegendItem(
                                        label: 'Actual Demand',
                                        color: AppColors.secondary),
                                    const SizedBox(width: 24),
                                    _LegendItem(
                                        label: 'Predicted Demand',
                                        color: AppColors.accent),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── Forecast Accuracy Card ───────────────────────────
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEF9A9A),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Forecast Accuracy',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Last 30 days',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      forecastProvider.forecastData == null
                                          ? '—'
                                          : '${(forecastProvider.forecastAccuracy * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.trending_up,
                                  color: AppColors.secondary,
                                  size: 48,
                                ),
                              ],
                            ),
                          ),

                          // ── AI Insight ───────────────────────────────────────
                          Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFCC80),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    forecastProvider.aiInsight,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Per-item forecasts ───────────────────────────────
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Demand forecast per item',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                forecastProvider.productForecasts.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 32),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.bar_chart_outlined,
                                                  size: 48,
                                                  color: Colors.grey[300]),
                                              const SizedBox(height: 12),
                                              Text(
                                                'No product forecasts available yet.\nAdd products and sales to enable AI forecasting.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: forecastProvider
                                            .productForecasts.length,
                                        itemBuilder: (context, index) {
                                          final product = forecastProvider
                                              .productForecasts[index];
                                          return _ProductForecastCard(
                                              product: product);
                                        },
                                      ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  // ── Bar Chart Configuration (fl_chart) ──────────────────────────
  BarChartData _buildBarChartData(List<Map<String, dynamic>> data) {
    double maxY = 1;

    for (var point in data) {
      final actual = (point['actual'] ?? 0).toDouble();
      final predicted = (point['predicted'] ?? 0).toDouble();
      if (actual > maxY) maxY = actual;
      if (predicted > maxY) maxY = predicted;
    }

    maxY = maxY * 1.2;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[index]['day'].toString(),
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 10),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade200,
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(data.length, (i) {
        final actual = (data[i]['actual'] ?? 0).toDouble();
        final predicted = (data[i]['predicted'] ?? 0).toDouble();
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: actual,
              color: AppColors.secondary,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: predicted,
              color: AppColors.accent,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }),
    );
  }
}

// ── Legend item ───────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }
}

// ── Product Forecast Card ─────────────────────────────────────────
class _ProductForecastCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductForecastCard({required this.product});

  @override
  Widget build(BuildContext context) {
    // Fields as stored by ForecastProvider
    final String name =
        product['productName'] as String? ?? 'Unknown Product';
    final List<dynamic> days =
        product['forecast_next_7_days'] as List<dynamic>? ?? [];

    // Use first-day and second-day predicted demand as today/tomorrow
    final double today = days.isNotEmpty
        ? ((days[0]['predicted_demand'] ?? days[0]['demand'] ?? 0) as num)
            .toDouble()
        : 0;
    final double tomorrow = days.length > 1
        ? ((days[1]['predicted_demand'] ?? days[1]['demand'] ?? 0) as num)
            .toDouble()
        : 0;

    final double changePercent =
        today > 0 ? ((tomorrow - today) / today * 100) : 0;
    final bool isIncreasing = changePercent >= 0;

    // Compute max for progress bars relative to the week
    final double maxDemand = days.fold<double>(0, (prev, d) {
      final v = ((d['predicted_demand'] ?? d['demand'] ?? 0) as num)
          .toDouble();
      return v > prev ? v : prev;
    });
    final double safeMax = maxDemand > 0 ? maxDemand : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and trend
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isIncreasing
                      ? const Color(0xFFC8E6C9)
                      : const Color(0xFFFFCDD2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${isIncreasing ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isIncreasing
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (days.isEmpty)
            const Text('No forecast data',
                style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            // Show today and tomorrow progress bars
            ...days.take(2).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value as Map<String, dynamic>;
              final label = i == 0 ? 'Today' : 'Tomorrow';
              final val = ((d['predicted_demand'] ?? d['demand'] ?? 0) as num)
                  .toDouble();
              final pct = val / safeMax;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                i == 0
                                    ? AppColors.secondary
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${val.toStringAsFixed(0)} units',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
