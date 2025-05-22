import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  DateTime? _lastFetched;

  static const String _lastFetchedKey = 'notifications_last_fetched';

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  DateTime? get lastFetched => _lastFetched;

  NotificationProvider() {
    _loadLastFetchedTimestamp();
  }

  Future<void> _loadLastFetchedTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastFetchedKey);
      if (timestamp != null) {
        _lastFetched = DateTime.parse(timestamp);
        print('[NotificationProvider] Loaded last fetched timestamp: $_lastFetched');
      }
    } catch (e) {
      print('[NotificationProvider] Error loading last fetched timestamp: $e');
      // It's okay if it fails, will just fetch on next opportunity
    }
    notifyListeners(); // Notify listeners in case UI depends on initial lastFetched value
  }

  Future<void> _saveLastFetchedTimestamp(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastFetchedKey, time.toIso8601String());
      _lastFetched = time;
      print('[NotificationProvider] Saved last fetched timestamp: $_lastFetched');
    } catch (e) {
      print('[NotificationProvider] Error saving last fetched timestamp: $e');
    }
  }

  Future<void> loadNotifications(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications =
            data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to load notifications: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDueNotifications({bool forceRefresh = false}) async {
    final now = DateTime.now();
    // Fetch if never fetched, or if it's a new day (after 6 AM), or if forceRefresh is true
    bool shouldFetch = forceRefresh ||
        _lastFetched == null ||
        now.day != _lastFetched!.day || 
        (now.day == _lastFetched!.day && now.hour >= 6 && _lastFetched!.hour < 6);

    if (!shouldFetch) {
      print('[NotificationProvider] loadDueNotifications - Not fetching, conditions not met.');
      return;
    }

    if (_isLoading) return; // Prevent concurrent loads

    print('[NotificationProvider] loadDueNotifications - Starting to fetch...');
    _isLoading = true;
    notifyListeners();

    try {
      final notifications = await NotificationService.fetchDueCropNotifications();
      _notifications = notifications.map((json) => NotificationModel.fromJson(json)).toList();
      print('[NotificationProvider] loadDueNotifications - Fetched ${_notifications.length} notifications.');
      await _saveLastFetchedTimestamp(now);
    } catch (e) {
      print('[NotificationProvider] loadDueNotifications - Error: $e');
      // Optionally, set an error state here for the UI to consume
      // For now, keep existing notifications if fetch fails, or clear them:
      // _notifications = []; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to manually clear notifications if needed (e.g., on logout)
  void clearNotifications() {
    _notifications = [];
    _lastFetched = null; // Reset last fetched time
    // Optionally clear from SharedPreferences too if desired on logout
    // SharedPreferences.getInstance().then((prefs) => prefs.remove(_lastFetchedKey));
    print('[NotificationProvider] Notifications cleared.');
    notifyListeners();
  }
}
