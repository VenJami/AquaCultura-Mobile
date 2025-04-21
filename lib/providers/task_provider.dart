import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/task_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/task.dart' as task_model;

/// Provider class for managing task-related state
/// Uses raw JSON data from the server API to avoid model coupling
class TaskProvider with ChangeNotifier {
  List<task_model.Task> _tasks = [];
  bool _isLoading = false;
  String _error = '';

  List<task_model.Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String get error => _error;

  /// Loads tasks assigned to the current user
  Future<void> loadTasks(BuildContext context) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await TaskService.getMyTasks();

      if (response is List) {
        // Convert response to Task objects
        _tasks = response
            .map((taskData) => task_model.Task.fromJson(taskData))
            .toList();
      } else {
        _error = 'Invalid response format';
      }
    } catch (e) {
      _error = e.toString();
      // Clear tasks on error
      _tasks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Updates the status of a task (completed/not completed)
  Future<void> toggleTaskStatus(
    BuildContext context,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      final newStatus = isCompleted ? 'Completed' : 'Pending';

      // Optimistically update local state
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final updatedTask = _tasks[taskIndex].copyWith(
          isCompleted: isCompleted,
          status: newStatus,
        );
        _tasks[taskIndex] = updatedTask;
        notifyListeners();
      }

      // Send update to server
      await TaskService.updateTaskStatus(taskId, newStatus);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update task status')));
      // Reload tasks to get accurate state
      await loadTasks(context);
    }
  }

  /// Updates an existing task with new data
  Future<void> updateTask(
    BuildContext context,
    String id,
    Map<String, dynamic> taskData,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await TaskService.updateTask(id, taskData);
      final updatedTask = task_model.Task.fromJson(response);

      // Check if the current user is still the assignee after the update
      final currentUserId = getCurrentUserId(context);

      // Update the task in the local list if it's still assigned to this user
      if (updatedTask.assignee == currentUserId) {
        final index = _tasks.indexWhere((task) => task.id == id);
        if (index != -1) {
          _tasks[index] = updatedTask;
        } else {
          // Add it if it's now assigned to this user but wasn't before
          _tasks.add(updatedTask);
        }
      } else {
        // Remove it if it's no longer assigned to this user
        _tasks.removeWhere((task) => task.id == id);
      }

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully'),
          ),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Get the current user's ID for task assignment
  String getCurrentUserId(BuildContext context) {
    try {
      // Try to get the user ID from the auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId != null && userId.isNotEmpty) {
        return userId;
      }

      // If we can't get the user ID, return a placeholder
      return 'current-user';
    } catch (e) {
      return 'current-user';
    }
  }

  /// Test loading a specific task by ID
  Future<void> loadSpecificTask(BuildContext context, String taskId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await TaskService.getTaskById(taskId);

      if (response != null) {
        // Create a Task object from the response and add it to the tasks list
        final task = task_model.Task.fromJson(response);

        // Only show the task if it's assigned to the current user
        final currentUserId = getCurrentUserId(context);

        if (task.assignee == currentUserId) {
          _tasks = [task]; // Just show this single task
        } else {
          _error = 'Task is not assigned to the current user';
          _tasks = [];
        }
      } else {
        _error = 'Invalid response format';
        _tasks = [];
      }
    } catch (e) {
      _error = e.toString();
      _tasks = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
