import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For date formatting
import '../config/api.dart';
import '../utils/secure_storage.dart';

class EventService {
  static const String _eventsEndpoint = '/events'; // Base endpoint for events

  /// Fetches events for the specified month and year for the logged-in user
  static Future<List<dynamic>> fetchEventsForMonth(DateTime month) async {
    try {
      print('[EventService] fetchEventsForMonth - Starting for month: ${DateFormat('yyyy-MM').format(month)}');
      final token = await SecureStorage.getToken();
      if (token == null) {
        print('[EventService] fetchEventsForMonth - No auth token found');
        throw Exception('Authentication token not found');
      }

      // Calculate start and end dates for the given month
      final firstDayOfMonth = DateTime(month.year, month.month, 1);
      final lastDayOfMonth = DateTime(month.year, month.month + 1, 0); // Day 0 of next month gives last day of current

      // Format dates as YYYY-MM-DD strings for the API query
      final formatter = DateFormat('yyyy-MM-dd');
      final startDate = formatter.format(firstDayOfMonth);
      final endDate = formatter.format(lastDayOfMonth);

      // Construct the endpoint URL with query parameters
      final url = '${ApiConfig.baseUrl}$_eventsEndpoint?startDate=$startDate&endDate=$endDate';
      print('[EventService] fetchEventsForMonth - Making API request to $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20)); // Slightly longer timeout for potentially more data

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Assuming the API returns { success: true, count: N, data: [...] }
        if (responseData is Map<String, dynamic> && responseData['success'] == true) {
           final data = responseData['data'] as List<dynamic>;
           print('[EventService] fetchEventsForMonth - Response data length: ${data.length}');
           // Optional: Print fetched event details for debugging
           // data.forEach((event) {
           //   print('[EventService] Fetched Event: ${event['title']} on ${event['date']}');
           // });
           return data;
        } else {
           print('[EventService] fetchEventsForMonth - Unexpected response format: ${response.body}');
           throw Exception('Failed to parse events from response');
        }

      } else {
        print('[EventService] fetchEventsForMonth - Error response: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load events: ${response.body}');
      }
    } catch (e) {
      print('[EventService] fetchEventsForMonth - Exception: $e');
      // Depending on how you want to handle errors globally, you might rethrow or return an empty list/error indicator
      rethrow;
    }
  }
} 