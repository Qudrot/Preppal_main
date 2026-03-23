import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:prepal2/core/network/api_client.dart';
import 'package:prepal2/core/network/api_constants.dart';

abstract class ForecastRemoteDataSource {
  /// Calls ML service to get 7-day demand forecast for a specific product
  Future<Map<String, dynamic>> get7DayForecast({
    required String itemName,
    required String businessType,
    required double price,
    required int shelfLifeHours,
    required String startingDate,
  });

  /// Get forecast accuracy metrics (last 30 days)
  Future<Map<String, dynamic>> getForecastAccuracy({
    required String itemName,
    required double predictedDemand,
  });

  /// Get AI insights based on current forecast data
  Future<Map<String, dynamic>> getAIInsights();

  /// Get product-level forecasts
  Future<List<Map<String, dynamic>>> getProductForecasts();
}

class ForecastRemoteDataSourceImpl implements ForecastRemoteDataSource {
  final ApiClient _apiClient;

  ForecastRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> get7DayForecast({
    required String itemName,
    required String businessType,
    required double price,
    required int shelfLifeHours,
    required String startingDate,
  }) async {
    // Call ML service to get 7-day forecast
    final response = await _apiClient.mlPost(
      ApiConstants.mlPredictWeek,
      body: {
        'businessId': _apiClient.getBusinessId() ?? '',
        'item_name': itemName,
        'business_type': businessType,
        'price': price,
        'shelf_life_hours': shelfLifeHours,
        'starting_date': startingDate,
        // ML API requires exactly 7 values (one per forecast day).
        // Valid weather values: 'Clear' or 'Rainy' only.
        'weather_forecast': ['Clear', 'Clear', 'Clear', 'Clear', 'Clear', 'Clear', 'Clear'],
        'holiday_flags': [0, 0, 0, 0, 0, 0, 0],
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return body['data'] ?? body;
    } else {
      throw Exception(body['message'] ?? 'Failed to fetch 7-day forecast');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProductForecasts() async {
    // Get product-level forecasts from ML service using mlPredictWeek
    final response = await _apiClient.mlPost(
      ApiConstants.mlPredictWeek,
      body: {
        'businessId': _apiClient.getBusinessId() ?? '',
        'item_name': 'All', // Default for summary
        'business_type': 'Bakery', // Default for summary
        'price': 0.0,
        'shelf_life_hours': 24,
        'starting_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'weather_forecast': ['Clear', 'Clear', 'Clear', 'Clear', 'Clear', 'Clear', 'Clear'],
        'holiday_flags': [0, 0, 0, 0, 0, 0, 0],
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final data = body['data'] ?? [];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map) {
        return [data as Map<String, dynamic>];
      }
      return [];
    } else {
      throw Exception(
          body['message'] ?? 'Failed to fetch product forecasts');
    }
  }

  @override
  Future<Map<String, dynamic>> getForecastAccuracy({
    required String itemName,
    required double predictedDemand,
  }) async {
    // Get historical forecast accuracy (last 30 days)
    final response = await _apiClient.mlPost(
      ApiConstants.mlAccuracy,
      body: {
        'businessId': _apiClient.getBusinessId() ?? '',
        'item_name': itemName,
        'predicted_demand': predictedDemand <= 0 ? 10.0 : predictedDemand, // Guard against 0 or negative
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return body['data'] ?? body;
    } else {
      // If ML service can't compute accuracy, return defaults
      return {
        'accuracy': 0.0,
        'daysAnalyzed': 30,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getAIInsights() async {
    // Get AI-generated insights about forecast patterns
    final response = await _apiClient.mlPost(
      ApiConstants.mlRecommend,
      body: {
        'businessId': _apiClient.getBusinessId() ?? '',
        // Some backends require these even for general recommendations
        'item_name': 'General',
        'predicted_demand': 10.0, 
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return body['data'] ?? body;
    } else {
      // Return sensible default if ML service fails
      return {
        'message': 'AI insights pending',
        'type': 'info',
      };
    }
  }
}
