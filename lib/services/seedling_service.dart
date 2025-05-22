import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/secure_storage.dart';

class SeedlingService {
  static const String _cropBatchesEndpoint = '/cropbatches';

  /// Get all crop batches from the server, optionally filtered by status
  static Future<List<dynamic>> getAllCropBatchesRaw({String? status}) async {
    try {
      print('getAllCropBatchesRaw - Starting API call (status: $status)');
      final token = await SecureStorage.getToken();
      if (token == null) {
        print('getAllCropBatchesRaw - No auth token found');
        throw Exception('Authentication token not found');
      }

      String url = '${ApiConfig.baseUrl}$_cropBatchesEndpoint';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }
      print('getAllCropBatchesRaw - Making API request to $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        print('getAllCropBatchesRaw - Response data length: ${data.length}');
        return data;
      } else {
        print('getAllCropBatchesRaw - Error response: ${response.body}');
        throw Exception('Failed to load crop batches: ${response.body}');
      }
    } catch (e) {
      print('getAllCropBatchesRaw - Exception: $e');
      rethrow;
    }
  }

  /// Get sample crop batches from the server
  static Future<List<dynamic>> getSampleCropBatchesRaw() async {
    try {
      print('getSampleCropBatchesRaw - Starting API call');
      final token = await SecureStorage.getToken();
      if (token == null) {
        print('getSampleCropBatchesRaw - No auth token found');
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_cropBatchesEndpoint/samples';
      print('getSampleCropBatchesRaw - Making API request to $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        print('getSampleCropBatchesRaw - Response data length: ${data.length}');
        return data;
      } else {
        print('getSampleCropBatchesRaw - Error response: ${response.body}');
        throw Exception('Failed to load sample crop batches: ${response.body}');
      }
    } catch (e) {
      print('getSampleCropBatchesRaw - Exception: $e');
      rethrow;
    }
  }

  /// Get a crop batch by ID
  static Future<dynamic> getCropBatchByIdRaw(String id) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_cropBatchesEndpoint/$id';
      print('Getting crop batch with ID: $id from $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load crop batch: ${response.body}');
      }
    } catch (e) {
      print('Error in getCropBatchByIdRaw: $e');
      rethrow;
    }
  }

  /// Create a new crop batch
  static Future<dynamic> createCropBatchRaw(Map<String, dynamic> data) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_cropBatchesEndpoint';
      print('Creating crop batch with data: $data at $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create crop batch: ${response.body}');
      }
    } catch (e) {
      print('Error in createCropBatchRaw: $e');
      rethrow;
    }
  }

  /// Update a crop batch
  static Future<dynamic> updateCropBatchRaw(
      String id, Map<String, dynamic> data) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_cropBatchesEndpoint/$id';
      print('Updating crop batch $id with data: $data at $url');

      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update crop batch: ${response.body}');
      }
    } catch (e) {
      print('Error in updateCropBatchRaw: $e');
      rethrow;
    }
  }

  /// Transplant a crop batch
  static Future<dynamic> transplantCropBatchRaw(
      String id, Map<String, dynamic> transplantData) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_cropBatchesEndpoint/$id/transplant';
      print('Transplanting crop batch $id with data: $transplantData at $url');

      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(transplantData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to transplant crop batch: ${response.statusCode} ${response.body}');
        throw Exception('Failed to transplant crop batch: ${response.body}');
      }
    } catch (e) {
      print('Error in transplantCropBatchRaw: $e');
      rethrow;
    }
  }

  /// Harvest a crop batch
  static Future<dynamic> harvestCropBatchRaw(
    String id, Map<String, dynamic> harvestData) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_cropBatchesEndpoint/$id/harvest';
      print('Harvesting crop batch $id with data: $harvestData at $url');

      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(harvestData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to harvest crop batch: ${response.statusCode} ${response.body}');
        throw Exception('Failed to harvest crop batch: ${response.body}');
      }
    } catch (e) {
      print('Error in harvestCropBatchRaw: $e');
      rethrow;
    }
  }

  /// Delete a crop batch
  static Future<dynamic> deleteCropBatchRaw(String id) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_cropBatchesEndpoint/$id';
      print('Deleting crop batch with ID: $id from $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete crop batch: ${response.body}');
      }
    } catch (e) {
      print('Error in deleteCropBatchRaw: $e');
      rethrow;
    }
  }
}
