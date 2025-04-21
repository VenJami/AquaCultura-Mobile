import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

/// Service class for handling attendance-related API operations
class AttendanceService {
  /// Helper method to handle HTTP errors with clear error messages
  static Exception _handleHttpError(http.Response response, String operation) {
    if (response.statusCode == 401) {
      return Exception(
          'Unauthorized: Your session has expired. Please log in again.');
    } else if (response.statusCode == 403) {
      return Exception(
          'Forbidden: You do not have permission to perform this action.');
    } else {
      try {
        // Try to extract an error message from the JSON response
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map && jsonResponse.containsKey('message')) {
          return Exception(jsonResponse['message']);
        }
      } catch (_) {
        // If JSON parsing fails, use the raw response
      }
      return Exception('Failed to $operation (Status: ${response.statusCode})');
    }
  }

  /// Fetches all attendance records from the server for the authenticated user
  static Future<dynamic> getAllAttendanceRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    // Simplified request - no role validation, just token auth
    final response = await http.get(
      Uri.parse(ApiConfig.attendance),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      // Check if the response has the expected structure
      if (jsonResponse is Map && jsonResponse.containsKey('attendance')) {
        return jsonResponse['attendance'];
      } else if (jsonResponse is List) {
        return jsonResponse;
      } else {
        // Return empty list if the structure is unexpected
        return [];
      }
    } else {
      throw _handleHttpError(response, 'load attendance records');
    }
  }

  /// Fetches attendance statistics from the server
  static Future<dynamic> getAttendanceStatsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    // Simplified request - no role validation, just token auth
    final response = await http.get(
      Uri.parse('${ApiConfig.attendance}/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw _handleHttpError(response, 'load attendance statistics');
    }
  }

  /// Marks attendance (present, absent, late)
  static Future<dynamic> markAttendanceRaw(
      Map<String, dynamic> attendanceData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    // Simplified request - no role validation, just token auth
    final response = await http.post(
      Uri.parse('${ApiConfig.attendance}/mark'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(attendanceData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw _handleHttpError(response, 'mark attendance');
    }
  }

  /// Requests basic attendance permissions for the current user -
  /// Simplified to just return true since we're no longer checking roles
  static Future<bool> requestBasicAttendanceAccess() async {
    // Since we're not validating roles, just return success
    return true;
  }
}
