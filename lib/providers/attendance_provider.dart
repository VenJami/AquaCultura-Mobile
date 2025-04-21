import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

/// Provider class for managing attendance-related state
/// Uses raw JSON data from the server API to avoid model coupling
class AttendanceProvider with ChangeNotifier {
  List<dynamic> _attendanceLog = [];
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};

  List<dynamic> get attendanceLog => _attendanceLog;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get stats => _stats;

  /// Loads all attendance records for the authenticated user
  Future<void> loadAttendance(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check authentication status first
      if (!await isAuthenticated()) {
        throw Exception('You are not authenticated. Please log in again.');
      }

      final attendance = await AttendanceService.getAllAttendanceRaw();

      // Make sure the response is properly handled
      if (attendance == null) {
        _attendanceLog = [];
      } else {
        _attendanceLog = attendance;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Set empty list on error
      _attendanceLog = [];
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        String errorMessage = e.toString();
        // Extract just the message without the 'Exception:' prefix for cleaner display
        if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring('Exception:'.length).trim();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Loads attendance statistics
  Future<void> loadStats(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simply load stats, no special error handling since we're not concerned about roles
      final stats = await AttendanceService.getAttendanceStatsRaw();
      _stats = stats;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Use default empty stats if there was an error
      _stats = {
        "totalDays": 0,
        "present": 0,
        "absent": 0,
        "late": 0,
        "leave": 0
      };

      _isLoading = false;
      notifyListeners();

      // Log the error but don't show to user
      print("Warning: Could not load attendance stats: $e");
    }
  }

  /// Marks attendance with the provided data
  Future<void> markAttendance(
    BuildContext context,
    Map<String, dynamic> attendanceData,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check authentication status first
      if (!await isAuthenticated()) {
        throw Exception('You are not authenticated. Please log in again.');
      }

      final newAttendance =
          await AttendanceService.markAttendanceRaw(attendanceData);
      _attendanceLog.add(newAttendance);

      // Reload stats after marking attendance
      await loadStats(context);

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        String errorMessage = e.toString();
        // Extract just the message without the 'Exception:' prefix for cleaner display
        if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring('Exception:'.length).trim();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Updates an existing attendance record with the provided data
  Future<void> updateAttendance(
    BuildContext context,
    Map<String, dynamic> attendanceData,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check authentication status first
      if (!await isAuthenticated()) {
        throw Exception('You are not authenticated. Please log in again.');
      }

      // Extract the ID from the attendanceData
      final String id = attendanceData['id'];
      // Remove id from the data to be sent to the API
      final Map<String, dynamic> updateData = Map.from(attendanceData);
      updateData.remove('id');

      // Simplified request - no role validation, just token auth
      final updatedAttendance = await http.put(
        Uri.parse('${ApiConfig.attendance}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
        body: json.encode(updateData),
      );

      if (updatedAttendance.statusCode == 200) {
        // Update the local attendance record
        final updatedData = json.decode(updatedAttendance.body)['attendance'];

        // Find and update the record in the local list
        final index =
            _attendanceLog.indexWhere((record) => record['_id'] == id);

        if (index != -1) {
          _attendanceLog[index] = updatedData;
        }

        // Reload stats after updating attendance
        await loadStats(context);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clock-out successful'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _handleHttpError(updatedAttendance, 'update attendance');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        String errorMessage = e.toString();
        // Extract just the message without the 'Exception:' prefix for cleaner display
        if (errorMessage.startsWith('Exception:')) {
          errorMessage = errorMessage.substring('Exception:'.length).trim();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      rethrow;
    }
  }

  // Helper method to get the authentication token
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    return token;
  }

  /// Check if the user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await _getToken();
      return token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Handle HTTP response errors properly
  void _handleHttpError(http.Response response, String operation) {
    if (response.statusCode == 401) {
      throw Exception(
          'Unauthorized: Your session has expired. Please log in again.');
    } else if (response.statusCode == 403) {
      throw Exception(
          'Forbidden: You do not have permission to perform this action.');
    } else {
      throw Exception('Failed to $operation: ${response.body}');
    }
  }
}
