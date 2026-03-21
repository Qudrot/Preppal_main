import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prepal2/core/constants/app_colors.dart';
import 'package:prepal2/presentation/providers/dashboard_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String selectedFilter = 'All';

  List<DashboardAlert> _getFilteredAlerts(List<DashboardAlert> alerts) {
    if (selectedFilter == 'All') return alerts;
    return alerts.where((alert) => alert.severity == selectedFilter).toList();
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'High':
        return AppColors.darkRed;
      case 'Medium':
        return AppColors.accent;
      case 'Low':
        return AppColors.secondary;
      default:
        return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<DashboardProvider>().allAlerts;
    final filteredAlerts = _getFilteredAlerts(alerts);
    int criticalCount = alerts.where((a) => a.severity == 'High').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        title: const Text('Alerts'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Critical alert banner
          if (criticalCount > 0)
            Container(
              color: AppColors.darkRed,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You have critical alerts',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$criticalCount item(s) need immediate attention',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: selectedFilter == 'All',
                    onTap: () {
                      setState(() => selectedFilter = 'All');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'High Risk',
                    isSelected: selectedFilter == 'High',
                    onTap: () {
                      setState(() => selectedFilter = 'High');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Medium',
                    isSelected: selectedFilter == 'Medium',
                    onTap: () {
                      setState(() => selectedFilter = 'Medium');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Info',
                    isSelected: selectedFilter == 'Low',
                    onTap: () {
                      setState(() => selectedFilter = 'Low');
                    },
                  ),
                ],
              ),
            ),
          ),

          // Alerts list
          Expanded(
            child: filteredAlerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No alerts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      return _AlertCard(
                        alert: alert,
                        alertColor: _getAlertColor(alert['type']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.gray,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.black,
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final DashboardAlert alert;
  final Color alertColor;

  const _AlertCard({
    required this.alert,
    required this.alertColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alertColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: alertColor.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              alert.severity == 'High' ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              color: alertColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Just now',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
