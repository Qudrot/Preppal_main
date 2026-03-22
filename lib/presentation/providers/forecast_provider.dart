import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prepal2/data/datasources/forecast_remote_datasource.dart';
import 'package:prepal2/data/models/inventory/product_model.dart';

enum ForecastStatus { initial, loading, loaded, error }

class ForecastData {
  final List<Map<String, dynamic>> sevenDayForecast;
  final List<Map<String, dynamic>> productForecasts;
  final double forecastAccuracy;
  final String aiInsight;

  const ForecastData({
    required this.sevenDayForecast,
    required this.productForecasts,
    required this.forecastAccuracy,
    required this.aiInsight,
  });
}

class ForecastProvider extends ChangeNotifier {
  final ForecastRemoteDataSource _dataSource;

  ForecastProvider(this._dataSource);

  ForecastStatus _status = ForecastStatus.initial;
  String? _errorMessage;
  ForecastData? _forecastData;

  ForecastStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ForecastStatus.loading;
  ForecastData? get forecastData => _forecastData;

  // Get 7-day forecast with proper formatting
  List<Map<String, dynamic>> get sevenDayForecast =>
      _forecastData?.sevenDayForecast ?? [];

  // Get product forecasts
  List<Map<String, dynamic>> get productForecasts =>
      _forecastData?.productForecasts ?? [];

  // Get forecast accuracy percentage
  double get forecastAccuracy => _forecastData?.forecastAccuracy ?? 0.0;

  // Get AI generated insight
  String get aiInsight =>
      _forecastData?.aiInsight ?? 'AI insights pending';

  /// Load all forecast data from ML service for provided products
  Future<void> loadForecastData({
    required List<ProductModel> products,
    required String businessType,
  }) async {
    if (products.isEmpty) {
      _status = ForecastStatus.loaded;
      _forecastData = const ForecastData(
        sevenDayForecast: [],
        productForecasts: [],
        forecastAccuracy: 0.0,
        aiInsight: 'Add products to get AI insights',
      );
      notifyListeners();
      return;
    }

    _status = ForecastStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> allSevenDayForecasts = [];
      final List<Map<String, dynamic>> allProductForecasts = [];
      double totalAccuracy = 0.0;
      int accuracyCount = 0;

      // For the first iteration, we take the first product to represent the "Global" 7-day forecast
      // In a real scenario, this would be an aggregate.
      final firstProduct = products.first;

      for (final product in products) {
        // Skip invalid products that would cause 422 errors
        if (product.name.trim().isEmpty) continue;
        
        final shelfLife = product.shelfLife > 0 ? product.shelfLife : 24; // Default to 24h if 0

        // Fetch 7-day forecast for THIS product
        final sevenDay = await _dataSource.get7DayForecast(
          itemName: product.name,
          businessType: businessType,
          price: product.price,
          shelfLifeHours: shelfLife,
          startingDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );

        // Format 7-day forecast data and add to results (if it's the first one or we want to merge)
        final sevenDayList = _formatSevenDayForecast(sevenDay);
        if (allSevenDayForecasts.isEmpty) {
          allSevenDayForecasts.addAll(sevenDayList);
        }

        // Add to product-level forecasts
        allProductForecasts.add({
          'productName': product.name,
          'forecast_next_7_days': sevenDay['forecast_next_7_days'] ?? [],
          'accuracy': 0.85, // Mock default if accuracy call fails
        });

        // Get accuracy for THIS product (Mocking predicted_demand for now or using a heuristic)
        try {
          final accuracyData = await _dataSource.getForecastAccuracy(
            itemName: product.name,
            predictedDemand: 20.0, // Should be from previous forecasts
          );
          final acc = (accuracyData['accuracy'] as num?)?.toDouble() ?? 0.85;
          totalAccuracy += acc;
          accuracyCount++;
        } catch (_) {
          // Ignore individual accuracy failures
        }
      }

      // Fetch general insights (one call is enough)
      final insights = await _dataSource.getAIInsights();
      final insightMessage = (insights['message'] as String?) ??
          'Focus on ${products.first.name} for the upcoming weekend';

      _forecastData = ForecastData(
        sevenDayForecast: allSevenDayForecasts,
        productForecasts: allProductForecasts,
        forecastAccuracy: accuracyCount > 0 ? (totalAccuracy / accuracyCount) : 0.85,
        aiInsight: insightMessage,
      );

      _status = ForecastStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = ForecastStatus.error;
      print('ForecastProvider error: $_errorMessage');
    }

    notifyListeners();
  }

  /// Format ML response into 7-day forecast structure
  List<Map<String, dynamic>> _formatSevenDayForecast(
      Map<String, dynamic> data) {
    // ML service should return data in format: {days: [{day, actual, predicted}]}
    final daysData = data['days'] as List?;

    if (daysData == null || daysData.isEmpty) {
      // Fallback: return empty list or default structure
      return [];
    }

    return daysData.cast<Map<String, dynamic>>();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
