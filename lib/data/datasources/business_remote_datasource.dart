import 'dart:convert';
import 'package:http/http.dart' as http_client;
import 'package:prepal2/core/network/api_client.dart';
import 'package:prepal2/core/network/api_constants.dart';

abstract class BusinessRemoteDataSource {
  Future<Map<String, dynamic>> createBusiness({
    required String businessName,
    required String businessType,
    required String location,
  });
  Future<List<Map<String, dynamic>>> getAllBusinesses();
  Future<Map<String, dynamic>> getBusinessById(String id);
  Future<Map<String, dynamic>> updateBusiness({
    required String id,
    required Map<String, dynamic> updates,
  });
  Future<void> deleteBusiness(String id);
}

class BusinessRemoteDataSourceImpl implements BusinessRemoteDataSource {
  final ApiClient _apiClient;

  BusinessRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> createBusiness({
    required String businessName,
    required String businessType,
    required String location,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.businessCreate,
      body: {
        'businessName': businessName,
        'businessType': businessType,
        'location': location,
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = body['data'] as Map<String, dynamic>;
      if (data['id'] != null) {
        await _apiClient.setBusinessId(data['id'] as String);
      }
      return data;
    } else {
      if (body['errors'] != null) {
        final errors = (body['errors'] as List)
            .map((e) => (e as Map)['message'])
            .join(', ');
        throw Exception(errors);
      }
      throw Exception(body['message'] ?? 'Failed to create business');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllBusinesses() async {
    http_client.Response response = await _apiClient.get(ApiConstants.businessGetAll);
    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = {};
    }

    if (response.statusCode == 404) {
      // Try /api/v1/business/user as a common alternative for listing
      response = await _apiClient.get('/api/v1/business/user');
      if (response.statusCode == 404) {
        // Last resort: Return empty list if no route found to allow onboarding
        print('DEBUG: No business list route found (/api/v1/business or /api/v1/business/user)');
        return [];
      }
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return [];
      }
    }

    // The server returns 404 when the user has not created any businesses yet.
    // Treat that as an empty list so the UI can ask for business details.
    if (response.statusCode == 404 || body['success'] == false) {
      return [];
    }

    if (response.statusCode == 200 && (body['success'] == true || body['data'] != null)) {
      final rawData = body['data'];

      List<dynamic> list;
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map) {
        list = [rawData];
      } else {
        list = [];
      }

      final businesses = list.cast<Map<String, dynamic>>();

      if (businesses.isNotEmpty && businesses.first['id'] != null) {
        await _apiClient.setBusinessId(businesses.first['id'] as String);
      }

      return businesses;
    }

    throw Exception(body['message'] ?? 'Failed to fetch businesses');
  }

  @override
  Future<Map<String, dynamic>> getBusinessById(String id) async {
    final response = await _apiClient.get(ApiConstants.businessGetById(id));
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Business not found');
  }

  @override
  Future<Map<String, dynamic>> updateBusiness({
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    final mappedUpdates = Map<String, dynamic>.from(updates);
    // Maintain internal keys for now as the backend explicitly validated
    // businessName and businessType in the latest logs.

    final response = await _apiClient.put(
      ApiConstants.businessUpdate(id),
      body: mappedUpdates,
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Failed to update business');
  }

  @override
  Future<void> deleteBusiness(String id) async {
    final response = await _apiClient.delete(ApiConstants.businessDelete(id));

    if (response.statusCode != 200 && response.statusCode != 204) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to delete business');
    }
  }
}
