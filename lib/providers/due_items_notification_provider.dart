import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart'; // Uses the service we created

class DueItemsNotificationProvider with ChangeNotifier { // Renamed class
  List<dynamic> _dueCropNotifications = [];
  List<dynamic> _dueTaskNotifications = []; // Added list for task notifications
  bool _isLoading = false;
  DateTime? _lastFetched;

  Set<String> _readCropNotificationIds = {}; // Added
  Set<String> _readTaskNotificationIds = {}; // Added

  // Key for crop notifications last fetched time
  static const String _lastCropFetchedKey = 'due_crop_notifications_last_fetched'; 
  // We might need a separate key for tasks or a general key if fetches are always combined
  // For now, let's assume a combined fetch will update a general key.
  static const String _lastFetchedItemsKey = 'due_items_last_fetched';
  static const String _readCropIdsKey = 'read_crop_notification_ids'; // Added
  static const String _readTaskIdsKey = 'read_task_notification_ids'; // Added


  List<dynamic> get dueCropNotifications => _dueCropNotifications;
  List<dynamic> get dueTaskNotifications => _dueTaskNotifications; // Added getter
  bool get isLoading => _isLoading;
  DateTime? get lastFetched => _lastFetched;

  // Getters for read status
  bool isCropNotificationRead(String id) => _readCropNotificationIds.contains(id);
  bool isTaskNotificationRead(String id) => _readTaskNotificationIds.contains(id);

  // Added getters for unread counts
  int get unreadCropCount => _dueCropNotifications.where((n) => !_readCropNotificationIds.contains(n['_id'] as String?)).length;
  int get unreadTaskCount => _dueTaskNotifications.where((n) => !_readTaskNotificationIds.contains(n['_id'] as String?)).length;
  int get totalUnreadCount => unreadCropCount + unreadTaskCount;

  DueItemsNotificationProvider() { // Renamed constructor
    _loadLastFetchedTimestamp();
    _loadReadNotificationIds(); // Added call
  }

  Future<void> _loadLastFetchedTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Using the new general key
      final timestamp = prefs.getString(_lastFetchedItemsKey); 
      if (timestamp != null) {
        _lastFetched = DateTime.parse(timestamp);
        print('[DueItemsNotificationProvider] Loaded last fetched timestamp: $_lastFetched');
      }
    } catch (e) {
      print('[DueItemsNotificationProvider] Error loading last fetched timestamp: $e');
    }
    // notifyListeners(); // Not needed here as _loadReadNotificationIds will also notify
  }

  Future<void> _loadReadNotificationIds() async { // Added method
    try {
      final prefs = await SharedPreferences.getInstance();
      final readCropIds = prefs.getStringList(_readCropIdsKey);
      if (readCropIds != null) {
        _readCropNotificationIds = readCropIds.toSet();
        print('[DueItemsNotificationProvider] Loaded ${_readCropNotificationIds.length} read crop notification IDs.');
      }
      final readTaskIds = prefs.getStringList(_readTaskIdsKey);
      if (readTaskIds != null) {
        _readTaskNotificationIds = readTaskIds.toSet();
        print('[DueItemsNotificationProvider] Loaded ${_readTaskNotificationIds.length} read task notification IDs.');
      }
    } catch (e) {
      print('[DueItemsNotificationProvider] Error loading read notification IDs: $e');
    }
    notifyListeners(); // Notify after loading both
  }

  Future<void> _saveLastFetchedTimestamp(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Using the new general key
      await prefs.setString(_lastFetchedItemsKey, time.toIso8601String()); 
      _lastFetched = time;
      print('[DueItemsNotificationProvider] Saved last fetched timestamp: $_lastFetched');
    } catch (e) {
      print('[DueItemsNotificationProvider] Error saving last fetched timestamp: $e');
    }
  }

  Future<void> _saveReadCropNotificationIds() async { // Added method
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readCropIdsKey, _readCropNotificationIds.toList());
      print('[DueItemsNotificationProvider] Saved read crop notification IDs.');
    } catch (e) {
      print('[DueItemsNotificationProvider] Error saving read crop IDs: $e');
    }
  }

  Future<void> _saveReadTaskNotificationIds() async { // Added method
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readTaskIdsKey, _readTaskNotificationIds.toList());
      print('[DueItemsNotificationProvider] Saved read task notification IDs.');
    } catch (e) {
      print('[DueItemsNotificationProvider] Error saving read task IDs: $e');
    }
  }

  void markCropNotificationAsRead(String id) { // Added method
    if (_readCropNotificationIds.add(id)) {
      _saveReadCropNotificationIds();
      notifyListeners();
      print('[DueItemsNotificationProvider] Marked crop notification $id as read.');
    }
  }

  void markTaskNotificationAsRead(String id) { // Added method
    if (_readTaskNotificationIds.add(id)) {
      _saveReadTaskNotificationIds();
      notifyListeners();
      print('[DueItemsNotificationProvider] Marked task notification $id as read.');
    }
  }
  
  void markAllCropNotificationsAsRead() { // Added method
    bool changed = false;
    for (var notification in _dueCropNotifications) {
      final id = notification['_id'] as String?;
      if (id != null && _readCropNotificationIds.add(id)) {
        changed = true;
      }
    }
    if (changed) {
      _saveReadCropNotificationIds();
      notifyListeners();
      print('[DueItemsNotificationProvider] Marked all current crop notifications as read.');
    }
  }

  void markAllTaskNotificationsAsRead() { // Added method
    bool changed = false;
    for (var notification in _dueTaskNotifications) {
      final id = notification['_id'] as String?;
      if (id != null && _readTaskNotificationIds.add(id)) {
        changed = true;
      }
    }
    if (changed) {
      _saveReadTaskNotificationIds();
      notifyListeners();
      print('[DueItemsNotificationProvider] Marked all current task notifications as read.');
    }
  }

  // This method will be expanded to fetch both crop and task notifications
  Future<void> loadDueItemsNotifications({bool forceRefresh = false}) async { // Renamed method
    final now = DateTime.now();
    bool shouldFetch = forceRefresh ||
        _lastFetched == null ||
        now.day != _lastFetched!.day ||
        (now.day == _lastFetched!.day && now.hour >= 6 && _lastFetched!.hour < 6) ||
        (_lastFetched!.isBefore(now.subtract(const Duration(days: 1))) && now.hour >=6 );

    if (!shouldFetch) {
      print('[DueItemsNotificationProvider] loadDueItemsNotifications - Not fetching, conditions not met. Last fetched: $_lastFetched');
      // Still notify if read statuses might have changed how current data is displayed
      // but loadReadNotificationIds() already does this.
      // If displaying new notifications (not just refreshing), then this return is fine.
      return;
    }

    if (_isLoading) {
      print('[DueItemsNotificationProvider] loadDueItemsNotifications - Already loading.');
      return; 
    }

    print('[DueItemsNotificationProvider] loadDueItemsNotifications - Starting to fetch...');
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch crop and task notifications in parallel
      final results = await Future.wait([
        NotificationService.fetchDueCropNotifications(),
        NotificationService.fetchDueTaskNotifications(),
      ]);

      _dueCropNotifications = results[0];
      print('[DueItemsNotificationProvider] Fetched ${_dueCropNotifications.length} due crop notifications.');
      
      _dueTaskNotifications = results[1];
      print('[DueItemsNotificationProvider] Fetched ${_dueTaskNotifications.length} due task notifications.');

      await _saveLastFetchedTimestamp(now); // Save timestamp after all fetches
    } catch (e) {
      print('[DueItemsNotificationProvider] loadDueItemsNotifications - Error: $e');
      // If one fails, we might still have partial data, or clear all
      // For simplicity now, errors in either will mean no update to the respective list from this attempt.
      // Consider more granular error handling if needed.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearAllDueNotifications() { // Renamed method
    _dueCropNotifications = [];
    _dueTaskNotifications = []; // Clear task notifications too
    _lastFetched = null; 
    _readCropNotificationIds.clear(); // Added
    _readTaskNotificationIds.clear(); // Added
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_lastFetchedItemsKey);
      prefs.remove(_readCropIdsKey); // Added
      prefs.remove(_readTaskIdsKey); // Added
    });
    print('[DueItemsNotificationProvider] All due notifications and read statuses cleared.');
    notifyListeners();
  }
} 