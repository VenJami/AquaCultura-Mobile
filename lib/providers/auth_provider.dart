import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Task {
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;
  final bool status;

  Task({
    required this.title,
    this.description = "",
    required this.startDate,
    required this.dueDate,
    this.status = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'] ?? "Untitled Task",
      description: json['description'] ?? "",
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now().add(const Duration(days: 1)),
      status: json['status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
    };
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String schedule;
  final List<Task> tasks;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.schedule = "8:00 AM - 4:00 PM", // Default schedule
    this.tasks = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<Task> parsedTasks = [];
    if (json['tasks'] != null) {
      try {
        parsedTasks = (json['tasks'] as List)
            .map((taskJson) => Task.fromJson(taskJson))
            .toList();
      } catch (e) {
        print("Error parsing tasks: $e");
        // Return empty list on parse error rather than crashing
      }
    }

    return User(
      id: json['id'] ?? "",
      name: json['name'] ?? "User",
      email: json['email'] ?? "",
      role: json['role'] ?? "user",
      schedule: json['schedule'] ?? "8:00 AM - 4:00 PM",
      tasks: parsedTasks,
    );
  }
}

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _token;
  User? _user;
  String? _errorMessage;

  // Base URL for API
  final String _baseUrl =
      'http://10.0.2.2:3000/api'; // Use the same address as in ApiConfig for Android emulator

  bool get isLoading => _isLoading;
  bool get isAuth => _token != null;
  String? get token => _token;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  // Method to register a user
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        _token = responseData['token'];
        _user = User.fromJson(responseData['user']);

        // Save token to shared preferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', _token!);

        // Convert tasks to JSON
        final List<Map<String, dynamic>> tasksJson =
            _user!.tasks.map((task) => task.toJson()).toList();

        // Save user data with tasks
        prefs.setString(
            'userData',
            json.encode({
              'id': _user!.id,
              'name': _user!.name,
              'email': _user!.email,
              'role': _user!.role,
              'schedule': _user!.schedule,
              'tasks': tasksJson,
            }));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (error) {
      _errorMessage = 'Could not connect to server';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Method to login a user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notify about loading state

    try {
      print("Attempting login: $email");

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print("Login response status: ${response.statusCode}");
      print("Login response body: ${response.body}");

      // Decode response data
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print("Failed to decode response: $e");
        _errorMessage = "Server returned invalid data";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Successful login
        try {
          _token = responseData['token'] ?? "";
          if (_token!.isEmpty) {
            throw Exception("Token is empty");
          }

          if (responseData['user'] == null) {
            throw Exception("User data is missing");
          }

          _user = User.fromJson(responseData['user']);

          // Save token to shared preferences
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('token', _token!);

          // Convert tasks to JSON
          final List<Map<String, dynamic>> tasksJson =
              _user!.tasks.map((task) => task.toJson()).toList();

          // Save user data with tasks
          prefs.setString(
              'userData',
              json.encode({
                'id': _user!.id,
                'name': _user!.name,
                'email': _user!.email,
                'role': _user!.role,
                'schedule': _user!.schedule,
                'tasks': tasksJson,
              }));

          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        } catch (e) {
          print("Error processing successful login: $e");
          _errorMessage = "Error processing login data";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Login failed - extract error message
        _errorMessage = responseData['message'] ?? 'Authentication failed';
        print(
            'Login error status: ${response.statusCode}, message: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (error) {
      // Network or other error
      _errorMessage = 'Connection error: Could not connect to server';
      print('Login exception: ${error.toString()}');
      _isLoading = false;
      notifyListeners();
      return false; // Return false instead of throwing
    }
  }

  // Method to logout a user
  Future<void> logout() async {
    _token = null;
    _user = null;

    // Clear shared preferences
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('userData');

    notifyListeners();
  }

  // Method to auto login from saved token
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('token')) {
      return false;
    }

    _token = prefs.getString('token');

    if (prefs.containsKey('userData')) {
      final extractedUserData = json.decode(prefs.getString('userData')!);

      // Parse tasks from saved data
      List<Task> savedTasks = [];
      if (extractedUserData['tasks'] != null) {
        savedTasks = (extractedUserData['tasks'] as List)
            .map((taskJson) => Task.fromJson(taskJson))
            .toList();
      }

      _user = User(
        id: extractedUserData['id'],
        name: extractedUserData['name'],
        email: extractedUserData['email'],
        role: extractedUserData['role'],
        schedule: extractedUserData['schedule'] ?? "8:00 AM - 4:00 PM",
        tasks: savedTasks,
      );
    }

    notifyListeners();
    return true;
  }
}
