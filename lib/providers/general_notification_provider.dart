import 'dart:convert';
import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http; // Assuming ApiService handles http
import '../models/notification_model.dart';
import '../services/api_service.dart'; // Core service for API calls
import 'auth_provider.dart'; // To get the auth token

class GeneralNotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  final AuthProvider? _authProvider;

  GeneralNotificationProvider(this._authProvider) {
    // Listen to auth changes to fetch notifications when user logs in
    _authProvider?.addListener(_authChanged);
    if (_authProvider?.token != null) {
      fetchNotifications();
    }
  }

  void _authChanged() {
    if (_authProvider?.token != null) {
      fetchNotifications();
    } else {
      _notifications = []; // Clear notifications if user logs out
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_authChanged);
    super.dispose();
  }

  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications => _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    // notifyListeners(); // Usually not needed just for clearing error string
  }

  Future<void> _performApiCall(Function apiCall) async {
    if (_authProvider?.token == null) {
      _errorMessage = "User not authenticated.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    Map<String, String>? originalHeaders;
    try {
      originalHeaders = Map.from(ApiService.headers);
      ApiService.headers['Authorization'] = 'Bearer ${_authProvider!.token}';
      await apiCall();
    } catch (e) {
      _errorMessage = 'An API error occurred: ${e.toString()}';
      // Ensure _isLoading is handled by the calling function if error occurs here
    } finally {
      if (originalHeaders != null) {
        ApiService.headers.clear();
        ApiService.headers.addAll(originalHeaders); // Restore original headers
      }
    }
  }

  Future<void> fetchNotifications({bool forceRefresh = false}) async {
    if (_authProvider?.token == null && !forceRefresh) { // still check token, but allow force refresh for initial load if needed by UI
      _errorMessage = "User not authenticated for fetching notifications.";
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    if (forceRefresh) _notifications = [];
    _errorMessage = null;
    notifyListeners(); // Notify that loading has started

    await _performApiCall(() async {
      final response = await ApiService.get('/notifications');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> notificationsJson = responseData['data']?['notifications'] ?? [];
        _notifications = notificationsJson
            .map((jsonItem) => NotificationModel.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] as String? ?? 'Failed to load notifications: ${response.statusCode}';
        _notifications = [];
      }
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markAsRead(String notificationId) async {
    print('[GeneralNotificationProvider] markAsRead called for ID: $notificationId');
    if (_authProvider?.token == null) {
      print('[GeneralNotificationProvider] markAsRead: Auth token null. Returning false.');
      return false;
    }

    final int notificationIndex = _notifications.indexWhere((n) => n.id == notificationId);
    print('[GeneralNotificationProvider] markAsRead: Notification index: $notificationIndex');

    if (notificationIndex == -1) {
      print('[GeneralNotificationProvider] markAsRead: Notification not found with ID: $notificationId. Returning true (as no action needed).');
      return true; // Or false, depending on desired behavior for not found
    }

    if (_notifications[notificationIndex].isRead) {
      print('[GeneralNotificationProvider] markAsRead: Notification ID $notificationId is already marked as read locally. Returning true.');
      return true;
    }

    _errorMessage = null;
    bool success = false;

    await _performApiCall(() async {
      print('[GeneralNotificationProvider] markAsRead: Calling PUT /api/notifications/$notificationId/read');
      final response = await ApiService.patch('/notifications/$notificationId/read', {});
      print('[GeneralNotificationProvider] markAsRead ID $notificationId: Response Status Code: ${response.statusCode}');
      // print('[GeneralNotificationProvider] markAsRead ID $notificationId: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Important: Create a new list or modify the item in a way that ChangeNotifier recognizes a change.
        // Directly modifying the item's property might not be enough if the list instance itself doesn't change.
        // However, copyWith should create a new instance of NotificationModel.
        _notifications[notificationIndex] = _notifications[notificationIndex].copyWith(isRead: true);
        success = true;
        print('[GeneralNotificationProvider] markAsRead ID $notificationId: Successfully marked as read locally.');
      } else {
        try {
          final responseData = json.decode(response.body);
          _errorMessage = responseData['message'] as String? ?? 'Failed to mark $notificationId as read: ${response.statusCode}';
        } catch (e) {
          _errorMessage = 'Failed to mark $notificationId as read: ${response.statusCode}. Could not parse error response.';
        }
        print('[GeneralNotificationProvider] markAsRead ID $notificationId: Error - $_errorMessage');
      }
    });

    if (success) {
      print('[GeneralNotificationProvider] markAsRead ID $notificationId: Success is true, notifying listeners.');
      notifyListeners();
    } else if (_errorMessage != null) {
      print('[GeneralNotificationProvider] markAsRead ID $notificationId: Error occurred, notifying listeners for error message.');
      notifyListeners();
    }
    print('[GeneralNotificationProvider] markAsRead ID $notificationId returning: $success');
    return success;
  }

  Future<bool> markAllAsRead() async {
    print('[GeneralNotificationProvider] markAllAsRead called. Current unreadCount: $unreadCount');
    if (_authProvider?.token == null || unreadCount == 0) {
      print('[GeneralNotificationProvider] markAllAsRead: Auth token null or unreadCount is 0. Returning false.');
      return false;
    }
    _errorMessage = null;
    bool success = false;

    await _performApiCall(() async {
      print('[GeneralNotificationProvider] markAllAsRead: Calling PUT /api/notifications/read-all');
      final response = await ApiService.patch('/notifications/read-all', {});
      print('[GeneralNotificationProvider] markAllAsRead: Response Status Code: ${response.statusCode}');
      // print('[GeneralNotificationProvider] markAllAsRead: Response Body: ${response.body}'); 

      if (response.statusCode == 200) {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        success = true;
        print('[GeneralNotificationProvider] markAllAsRead: Successfully marked all as read locally.');
      } else {
        try {
            final responseData = json.decode(response.body);
            _errorMessage = responseData['message'] as String? ?? 'Failed to mark all as read: ${response.statusCode}';
        } catch (e) {
            _errorMessage = 'Failed to mark all as read: ${response.statusCode}. Could not parse error response.';
        }
        print('[GeneralNotificationProvider] markAllAsRead: Error - $_errorMessage');
      }
    });
    if (success) {
      print('[GeneralNotificationProvider] markAllAsRead: Success is true, notifying listeners.');
      notifyListeners();
    } else if(_errorMessage != null) {
      print('[GeneralNotificationProvider] markAllAsRead: Error occurred, notifying listeners for error message.');
      notifyListeners();
    }
    print('[GeneralNotificationProvider] markAllAsRead returning: $success');
    return success;
  }

  Future<bool> deleteNotification(String notificationId) async {
    if (_authProvider?.token == null) return false;
    _errorMessage = null;
    bool success = false;

    await _performApiCall(() async {
      final response = await ApiService.delete('/notifications/$notificationId');
      if (response.statusCode == 204 || response.statusCode == 200) {
        _notifications.removeWhere((n) => n.id == notificationId);
        success = true;
      } else {
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] as String? ?? 'Failed to delete notification: ${response.statusCode}';
      }
    });
    if (success) notifyListeners();
    else if(_errorMessage != null) notifyListeners();
    return success;
  }
} 