import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/secure_storage.dart';

class NotificationService {
  static const String _cropBatchesEndpoint = '/cropbatches';

  /// Fetches crop batches due for transplant or harvest today
  static Future<List<dynamic>> fetchDueCropNotifications() async {
    try {
      print('[NotificationService] fetchDueCropNotifications - Starting API call');
      final token = await SecureStorage.getToken();
      if (token == null) {
        print('[NotificationService] fetchDueCropNotifications - No auth token found');
        throw Exception('Authentication token not found');
      }

      // Construct the new endpoint URL
      final url = '${ApiConfig.baseUrl}$_cropBatchesEndpoint/due-today';
      print('[NotificationService] fetchDueCropNotifications - Making API request to $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15)); // Increased timeout slightly

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        print('[NotificationService] fetchDueCropNotifications - Response data length: ${data.length}');
        // For now, just print the fetched notifications
        data.forEach((notification) {
          print('[NotificationService] Due Batch: ${notification['batchCode']} - ${notification['plantType']} - Status: ${notification['status']}');
          if (notification['status'] == 'seedling') {
            print('  Expected Transplant Date: ${notification['expectedTransplantDate']}');
          } else if (notification['status'] == 'transplanted') {
            print('  Expected Harvest Date: ${notification['transplantDetails']?['expectedHarvestDate']}');
          }
        });
        return data;
      } else {
        print('[NotificationService] fetchDueCropNotifications - Error response: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load due crop notifications: ${response.body}');
      }
    } catch (e) {
      print('[NotificationService] fetchDueCropNotifications - Exception: $e');
      // Depending on how you want to handle errors globally, you might rethrow or return an empty list/error indicator
      rethrow; 
    }
  }

  /// Fetches tasks due today for the logged-in user
  static Future<List<dynamic>> fetchDueTaskNotifications() async {
    try {
      print('[NotificationService] fetchDueTaskNotifications - Starting API call');
      final token = await SecureStorage.getToken();
      if (token == null) {
        print('[NotificationService] fetchDueTaskNotifications - No auth token found');
        throw Exception('Authentication token not found');
      }

      // Construct the new endpoint URL for due tasks
      final url = '${ApiConfig.baseUrl}/tasks/due-today'; // Note: /api prefix is part of ApiConfig.baseUrl typically
      print('[NotificationService] fetchDueTaskNotifications - Making API request to $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        print('[NotificationService] fetchDueTaskNotifications - Response data length: ${data.length}');
        data.forEach((task) {
          print('[NotificationService] Due Task: ${task['title']} - Status: ${task['status']}');
        });
        return data;
      } else {
        print('[NotificationService] fetchDueTaskNotifications - Error response: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load due task notifications: ${response.body}');
      }
    } catch (e) {
      print('[NotificationService] fetchDueTaskNotifications - Exception: $e');
      rethrow;
    }
  }
} 