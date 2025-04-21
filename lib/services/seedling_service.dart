import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/secure_storage.dart';

class SeedlingService {
  static const String _seedlingsEndpoint = '/seedlings';

  /// Get all seedlings from the server
  static Future<List<dynamic>> getAllSeedlingsRaw() async {
    try {
      print('getAllSeedlingsRaw - Starting API call');
      final token = await SecureStorage.getToken();
      if (token == null) {
        print('getAllSeedlingsRaw - No auth token found');
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_seedlingsEndpoint';
      print('getAllSeedlingsRaw - Making API request to $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        print('getAllSeedlingsRaw - Response data length: ${data.length}');
        return data;
      } else {
        print('getAllSeedlingsRaw - Error response: ${response.body}');
        throw Exception('Failed to load seedlings: ${response.body}');
      }
    } catch (e) {
      print('getAllSeedlingsRaw - Exception: $e');
      throw e;
    }
  }

  /// Get sample seedlings from the server
  static Future<List<dynamic>> getSampleSeedlingsRaw() async {
    try {
      print('getSampleSeedlingsRaw - Starting API call');
      final token = await SecureStorage.getToken();
      if (token == null) {
        print('getSampleSeedlingsRaw - No auth token found');
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_seedlingsEndpoint/samples';
      print('getSampleSeedlingsRaw - Making API request to $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        print('getSampleSeedlingsRaw - Response data length: ${data.length}');
        return data;
      } else {
        print('getSampleSeedlingsRaw - Error response: ${response.body}');
        throw Exception('Failed to load sample seedlings: ${response.body}');
      }
    } catch (e) {
      print('getSampleSeedlingsRaw - Exception: $e');
      throw e;
    }
  }

  /// Get a seedling by ID
  static Future<dynamic> getSeedlingByIdRaw(String id) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_seedlingsEndpoint/$id';
      print('Getting seedling with ID: $id from $url');

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
        throw Exception('Failed to load seedling: ${response.body}');
      }
    } catch (e) {
      print('Error in getSeedlingByIdRaw: $e');
      throw e;
    }
  }

  /// Create a new seedling
  static Future<dynamic> createSeedlingRaw(Map<String, dynamic> data) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_seedlingsEndpoint';
      print('Creating seedling with data: $data at $url');

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
        throw Exception('Failed to create seedling: ${response.body}');
      }
    } catch (e) {
      print('Error in createSeedlingRaw: $e');
      throw e;
    }
  }

  /// Update a seedling
  static Future<dynamic> updateSeedlingRaw(
      String id, Map<String, dynamic> data) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_seedlingsEndpoint/$id';
      print('Updating seedling $id with data: $data at $url');

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
        throw Exception('Failed to update seedling: ${response.body}');
      }
    } catch (e) {
      print('Error in updateSeedlingRaw: $e');
      throw e;
    }
  }

  /// Delete a seedling
  static Future<dynamic> deleteSeedlingRaw(String id) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '${ApiConfig.baseUrl}$_seedlingsEndpoint/$id';
      print('Deleting seedling with ID: $id from $url');

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
        throw Exception('Failed to delete seedling: ${response.body}');
      }
    } catch (e) {
      print('Error in deleteSeedlingRaw: $e');
      throw e;
    }
  }

  /// Count seedlings by stage
  static Future<Map<String, int>> countSeedlingsByStage() async {
    try {
      final seedlings = await getAllSeedlingsRaw();
      final Map<String, int> counts = {
        'Seeding': 0,
        'Germination': 0,
        'Growing': 0,
        'Harvested': 0,
        'Total': seedlings.length,
      };

      for (final seedling in seedlings) {
        final stage = seedling['stage'] ?? 'Unknown';
        if (counts.containsKey(stage)) {
          counts[stage] = counts[stage]! + 1;
        }
      }

      return counts;
    } catch (e) {
      print('Error counting seedlings by stage: $e');
      throw e;
    }
  }

  // Alias methods for backward compatibility
  static Future<List<dynamic>> getAllSeedlings() {
    return getAllSeedlingsRaw();
  }

  static Future<List<dynamic>> getSampleSeedlings() {
    return getSampleSeedlingsRaw();
  }

  static Future<dynamic> getSeedlingById(String id) {
    return getSeedlingByIdRaw(id);
  }

  static Future<dynamic> createSeedling(Map<String, dynamic> data) {
    return createSeedlingRaw(data);
  }

  static Future<dynamic> updateSeedling(String id, Map<String, dynamic> data) {
    return updateSeedlingRaw(id, data);
  }

  static Future<dynamic> deleteSeedling(String id) {
    return deleteSeedlingRaw(id);
  }
}
