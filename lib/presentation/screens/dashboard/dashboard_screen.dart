import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prepal2/presentation/providers/forecast_provider.dart';
import 'package:prepal2/presentation/providers/auth_provider.dart';
import 'package:prepal2/presentation/providers/business_provider.dart';
import 'package:prepal2/presentation/providers/dashboard_provider.dart';
import 'package:prepal2/presentation/providers/inventory_provider.dart';
import 'package:prepal2/presentation/providers/daily_sales_provider.dart';
import 'package:prepal2/presentation/screens/sales/daily_sales_report_screen.dart';
import 'package:prepal2/presentation/screens/forecast/demand_forecast_screen.dart';
import 'package:prepal2/presentation/screens/splash/splash_screen.dart';
import 'package:prepal2/core/constants/app_colors.dart';
import 'package:prepal2/presentation/widgets/shared_button.dart';
import 'package:prepal2/presentation/screens/auth/business_details_screen.dart';

// Changed to StatefulWidget so we can call loadSales() on init
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    // Load real sales data from API when dashboard first opens
    Future.microtask(() async {
      if (!mounted) return;
      final business = context.read<BusinessProvider>().currentBusiness;
      final dashboard = context.read<DashboardProvider>();
      // Sync inventory products for alert/recommendation computations
      dashboard.syncInventory(context.read<InventoryProvider>().allProducts);
      // Fetch today's sales from API if business exists
      if (business != null && business.id.isNotEmpty) {
        await dashboard.loadSales(business.id);
        if (mounted) {
          await context.read<ForecastProvider>().loadForecastData(
            products: context.read<InventoryProvider>().allProducts,
            businessType: business.businessType,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    final business = businessProvider.currentBusiness;
    final inventory = context.watch<InventoryProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final forecast = context.watch<ForecastProvider>();

    if (businessProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }

    if (!businessProvider.hasBusiness) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 24),
                const Text(
                  'No Business Found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'It looks like you haven\'t set up your business yet. Let\'s get you started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Set Up Business',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BusinessDetailsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _DashboardHeader(
                      businessName: business?.businessName ?? 'Business',
                      wasteReduction: dashboard.wasteReductionPercent,
                      highRisk: dashboard.highRiskCount,
                      mediumRisk: dashboard.mediumRiskCount,
                      lowRisk: dashboard.lowRiskCount,
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Stats Row
                          _StatsRow(inventory: inventory),
                          const SizedBox(height: 16),

                          //Today's Demand Forecast
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '7-day demand forecast',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              GestureDetector(
                                onTap: forecast.productForecasts.isEmpty ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DemandForecastScreen(),
                                    ),
                                  );
                                },
                                child: forecast.productForecasts.isEmpty
                                    ? const SizedBox.shrink()
                                    : Text(
                                        'View all (${forecast.productForecasts.length})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    const Text('Predicted Sales', overflow: TextOverflow.ellipsis),
                                    _buildLegendItem(label: 'Predicted Sales', color: AppColors.secondary),
                                    _buildLegendItem(label: 'Actual Sales', color: const Color(0xFFFFC107)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: forecast.productForecasts.isEmpty
                                      ? const SizedBox.shrink()
                                      : GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const DemandForecastScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'View all (${forecast.productForecasts.length})',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.red[400],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 180,
                                  child: forecast.sevenDayForecast.isEmpty
                                      ? const Center(child: Text('No forecast data available', style: TextStyle(color: Colors.grey, fontSize: 13)))
                                      : LineChart(_buildForecastChartData(forecast.sevenDayForecast)),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          //Daily Alert Section 
                          _buildSectionHeader(
                            title: 'Daily Alert',
                            actionText: 'View all (${dashboard.dailyAlerts.length})',
                          ),
                          const SizedBox(height: 8),
                          if (dashboard.dailyAlerts.isEmpty)
                            _buildEmptyCard('✅ No alerts today!')
                          else
                            ...dashboard.dailyAlerts.map((alert) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildAlertCard(
                                    title: alert.productName,
                                    subtitle: alert.message,
                                    severity: alert.severity,
                                  ),
                                )),

                          const SizedBox(height: 16),

                          // Smart Recommendation Section
                          _buildSectionHeader(
                            title: 'Smart Recommendation',
                            actionText: 'View all (${dashboard.smartRecommendations.length})',
                          ),
                          const SizedBox(height: 8),
                          if (dashboard.smartRecommendations.isEmpty)
                            _buildEmptyCard('✅ All stock levels look good!')
                          else
                            ...dashboard.smartRecommendations.map((rec) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildRecommendationCard(
                                    title: rec.productName,
                                    subtitle: rec.message,
                                  ),
                                )),

                          const SizedBox(height: 16),

                          // //Today's Sales Summary
                          // _buildSalesSummaryCard(dashboard),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.pie_chart_outline,
                      title: 'Today\'s report\nand insights',
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => const DailySalesReportScreen(),
                        //   ),
                        // );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.access_time,
                      title: 'Input today\'s\nsales',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailySalesReportScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Line Chart Configuration (fl_chart) ──────────────────────────
  LineChartData _buildForecastChartData(List<Map<String, dynamic>> data) {
    List<FlSpot> actualSpots = [];
    List<FlSpot> predictedSpots = [];
    double maxX = (data.length - 1).toDouble();
    double maxY = 1;

    for (int i = 0; i < data.length; i++) {
      final actual = (data[i]['actual'] ?? 0).toDouble();
      final predicted = (data[i]['predicted'] ?? 0).toDouble();
      if (actual > maxY) maxY = actual;
      if (predicted > maxY) maxY = predicted;

      actualSpots.add(FlSpot(i.toDouble(), actual));
      predictedSpots.add(FlSpot(i.toDouble(), predicted));
    }
    
    // Add 10% padding to maxY
    maxY = maxY * 1.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index]['day'].toString(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false), // Hide left titles to match mockup
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        // Actual Sales Line
        LineChartBarData(
          spots: actualSpots,
          isCurved: true,
          color: const Color(0xFFFFC107),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: actualSpots.length == 1),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFFFFC107).withOpacity(0.1),
          ),
        ),
        // Predicted Sales Line
        LineChartBarData(
          spots: predictedSpots,
          isCurved: true,
          color: AppColors.secondary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: predictedSpots.length == 1),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.secondary.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: onTap,
          child: Text(actionText,
              style: TextStyle(fontSize: 10, color: Colors.red[400], fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLegendItem({required String label, required Color color}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(radius: 5, backgroundColor: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87)),
    ]);
  }

  // UPDATED: now accepts severity string instead of bool
  Widget _buildAlertCard({
    required String title,
    required String subtitle,
    required String severity,
  }) {
    final isHigh = severity == 'High';
    final isMedium = severity == 'Medium';
    final bg = isHigh ? Colors.red[50]! : isMedium ? Colors.orange[50]! : Colors.yellow[50]!;
    final border = isHigh ? Colors.red[100]! : isMedium ? Colors.orange[100]! : Colors.yellow[100]!;
    final color = isHigh ? Colors.red : isMedium ? Colors.orange : Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isHigh ? Colors.red[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(severity,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: real sales card
  // Widget _buildSalesSummaryCard(DashboardProvider dashboard) {
  //   return GestureDetector(
  //     onTap: () => Navigator.push(context,
  //         MaterialPageRoute(builder: (_) => const DailySalesReportScreen())),
  //     child: Container(
  //       width: double.infinity,
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(12),
  //         boxShadow: [
  //           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
  //         ],
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text('Today Sales',
  //               style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
  //           const SizedBox(height: 8),
  //           dashboard.isLoadingSales
  //               ? const SizedBox(height: 28, child: CircularProgressIndicator(strokeWidth: 2))
  //               : Text(
  //                   // REAL value from API
  //                   dashboard.todayRevenueFormatted,
  //                   style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
  //                 ),
  //           const SizedBox(height: 8),
  //           Row(children: [
  //             Icon(
  //               dashboard.revenueIsUp ? Icons.arrow_upward : Icons.arrow_downward,
  //               color: dashboard.revenueIsUp ? Colors.green : Colors.red,
  //               size: 14,
  //             ),
  //             const SizedBox(width: 4),
  //             // REAL change % vs yesterday
  //             Text(dashboard.revenueChangeLabel,
  //                 style: TextStyle(
  //                     fontSize: 12,
  //                     color: dashboard.revenueIsUp ? Colors.green : Colors.red)),
  //           ]),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
    );
  }

  Widget _buildActionButton({required IconData icon, required String title, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          //border: Border.all(color: Colors.red[100]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(title, textAlign: TextAlign.start, style: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Header Widget ─────────────────────────────────────────────
// CHANGE 2: Accepts real values as parameters instead of hardcoding them

class _DashboardHeader extends StatelessWidget {
  final String businessName;
  final String wasteReduction; // was hardcoded '35%'
  final int highRisk;          // was hardcoded '1'
  final int mediumRisk;        // was hardcoded '0'
  final int lowRisk;           // was hardcoded '3'

  const _DashboardHeader({
    required this.businessName,
    required this.wasteReduction,
    required this.highRisk,
    required this.mediumRisk,
    required this.lowRisk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu, color: Colors.white, size: 28),
              Expanded(
                child: Column(
                  children: [
                    const Text('Welcome',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    // ✅ REAL business name from BusinessProvider
                    Text(businessName,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(_formattedDate(),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.white,
                    child: Icon(Icons.person, color: AppColors.secondary)),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      // Reset all provider state before logout
                      context.read<BusinessProvider>().reset();
                      context.read<InventoryProvider>().reset();
                      context.read<DailySalesProvider>().reset();
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SplashScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ]),
                    ),
                  ],
                ),
              ]),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.trending_down, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Waste Reduction',
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      // ✅ REAL VALUE — was hardcoded '35%'
                      Text(wasteReduction,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('from last week', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      const SizedBox(height: 4),
                      const Row(children: [
                        Icon(Icons.info_outline, color: Colors.white70, size: 10),
                        SizedBox(width: 2),
                        Text('more info', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.warning_amber, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Waste Risk levels',
                            style: TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          // ✅ REAL VALUES — were hardcoded '1', '0', '3'
                          _buildRiskPill('High', '$highRisk', Colors.red[100]!, Colors.red),
                          _buildRiskPill('Medium', '$mediumRisk', Colors.orange[100]!, Colors.orange),
                          _buildRiskPill('Low', '$lowRisk', Colors.green[100]!, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('for this week', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      const Row(children: [
                        Icon(Icons.info_outline, color: Colors.white70, size: 10),
                        SizedBox(width: 2),
                        Text('more info', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildRiskPill(String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Column(children: [
        Text(label, style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

// ── Stats Row (unchanged) ─────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final InventoryProvider inventory;
  const _StatsRow({required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatCard(label: 'Total Products', value: '${inventory.totalProducts}',
          icon: Icons.inventory_2, color: AppColors.secondary),
      const SizedBox(width: 12),
      _StatCard(label: 'Low Stock', value: '${inventory.lowStockProducts.length}',
          icon: Icons.warning_amber, color: Colors.orange),
      const SizedBox(width: 12),
      _StatCard(label: 'Expiring Soon', value: '${inventory.expiringSoonProducts.length}',
          icon: Icons.schedule, color: Colors.red),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    );
  }
}


