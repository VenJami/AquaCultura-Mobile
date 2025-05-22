import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // Use timeout settings from config
  static final Duration _connectionTimeout = Duration(seconds: 10);

  static Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static void setAuthToken(String token) {
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print("Auth token set: Bearer ${token.substring(0, math.min(10, token.length))}...");
    } else {
      headers.remove('Authorization');
      print("Auth token cleared");
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token != null && token.isNotEmpty) {
      print("Using token from shared preferences for request");
    } else {
      print("No token found in shared preferences");
    }

    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    
    print("Headers for request: ${requestHeaders.keys.toList()}");
    return requestHeaders;
  }

  // Generic GET method
  static Future<http.Response> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      print("Making GET request to: $url");
      
      final requestHeaders = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: requestHeaders).timeout(_connectionTimeout);
      
      print("API response status: ${response.statusCode}");
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        print("API response status: ${response.statusCode}, body: ${response.body}");
        throw Exception("API Error: Status ${response.statusCode}");
      }
    } catch (e) {
      print("Error in GET request: $e");
      throw Exception("Failed to perform GET request: $e");
    }
  }

  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    return response;
  }

  static Future<http.Response> put(
      String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    return response;
  }

  static Future<http.Response> patch(
      String endpoint, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    return response;
  }

  static Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return response;
  }
  
  /// Fetches the latest water temperature, pH level readings, and the timestamp
  /// Returns a Map with 'temperature', 'ph', and 'timestamp' keys
  static Future<Map<String, dynamic>> getLatestReadings() async {
    try {
      final response = await get('/readings/latest');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'temperature': data['temperature']?.toDouble() ?? 0.0,
          'ph': data['ph']?.toDouble() ?? 0.0,
          'timestamp': data['timestamp'],
        };
      } else {
        throw Exception('Failed to load water readings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching water readings: $e');
      // Return default values on error
      return {'temperature': 0.0, 'ph': 0.0, 'timestamp': null};
    }
  }
}