import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import '../utils/secure_storage.dart';
import '../models/api_response.dart';

/// Service class for handling task-related API operations
class TaskService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _tasksEndpoint = '/tasks';

  /// Get user's tasks (tasks assigned to the current user)
  static Future<List<dynamic>> getMyTasks() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$_baseUrl$_tasksEndpoint/my-tasks';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Failed to load my tasks: $errorMessage');
      }
    } catch (e) {
      throw e;
    }
  }

  /// Get all tasks (admin only)
  static Future<List<dynamic>> getAllTasks() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$_baseUrl$_tasksEndpoint';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Failed to load all tasks: $errorMessage');
      }
    } catch (e) {
      throw e;
    }
  }

  /// Get tasks for a specific user (admin only)
  static Future<List<dynamic>> getUserTasks(String userId) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$_baseUrl$_tasksEndpoint/user/$userId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Failed to load user tasks: $errorMessage');
      }
    } catch (e) {
      throw e;
    }
  }

  /// Get a specific task by ID
  static Future<dynamic> getTaskById(String taskId) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$_baseUrl$_tasksEndpoint/$taskId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Failed to load task: $errorMessage');
      }
    } catch (e) {
      throw e;
    }
  }

  /// Update a task
  static Future<dynamic> updateTask(
      String taskId, Map<String, dynamic> taskData) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$_baseUrl$_tasksEndpoint/$taskId';
      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(taskData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Failed to update task: $errorMessage');
      }
    } catch (e) {
      throw e;
    }
  }

  /// Update task status
  static Future<dynamic> updateTaskStatus(String taskId, String status) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$_baseUrl$_tasksEndpoint/$taskId';
      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'status': status}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Failed to update task status: $errorMessage');
      }
    } catch (e) {
      throw e;
    }
  }

  /// Helper to parse error messages from API responses
  static String _parseErrorMessage(http.Response response) {
    try {
      final body = json.decode(response.body);
      return body['error'] ?? 'Unknown error';
    } catch (e) {
      return 'Status ${response.statusCode}: ${response.body}';
    }
  }

  // Backwards compatibility methods
  static Future<dynamic> getAllTasksRaw() => getAllTasks();
  static Future<dynamic> getTaskByIdRaw(String id) => getTaskById(id);
  static Future<dynamic> updateTaskRaw(
          String id, Map<String, dynamic> taskData) =>
      updateTask(id, taskData);
  static Future<dynamic> toggleTaskStatusRaw(String id, bool isCompleted) {
    final status = isCompleted ? 'Completed' : 'Pending';
    return updateTaskStatus(id, status);
  }
}
