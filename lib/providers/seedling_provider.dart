import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../services/seedling_service.dart';

/// SeedlingProvider manages the state of seedlings in the application.
/// It communicates with the server API through SeedlingService to perform CRUD operations.
/// The provider works directly with raw JSON data from the server, which includes virtual fields
/// calculated on the server side such as batchName, daysSincePlanting, and estimatedHeight.
class SeedlingProvider with ChangeNotifier {
  List<dynamic> _seedlings = [];
  bool _isLoading = false;

  List<dynamic> get seedlings => _seedlings;
  bool get isLoading => _isLoading;

  /// Loads all seedlings for the authenticated user
  Future<void> loadSeedlings(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final seedlings = await SeedlingService.getAllSeedlingsRaw();
      _seedlings = seedlings;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Creates a new seedling with the provided data
  Future<void> createSeedling(
    BuildContext context, {
    required String batchCode,
    required String plantType,
    required String healthStatus,
    required String notes,
    required DateTime plantedDate,
    int germination = 0,
    double pHLevel = 6.0,
    double temperature = 25.0,
    double growthRate = 1.0,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final seedlingData = {
        'batchCode': batchCode,
        'plantType': plantType,
        'healthStatus': healthStatus,
        'notes': notes,
        'plantedDate': plantedDate.toIso8601String(),
        'germination': germination,
        'pHLevel': pHLevel,
        'temperature': temperature,
        'growthRate': growthRate,
      };

      final newSeedling = await SeedlingService.createSeedlingRaw(seedlingData);
      _seedlings.add(newSeedling);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Updates an existing seedling with the provided data
  Future<void> updateSeedling(
    BuildContext context,
    String id, {
    required String batchCode,
    required String plantType,
    required String healthStatus,
    required String notes,
    required DateTime plantedDate,
    required int germination,
    required double pHLevel,
    required double temperature,
    required double growthRate,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final seedlingData = {
        'batchCode': batchCode,
        'plantType': plantType,
        'healthStatus': healthStatus,
        'notes': notes,
        'plantedDate': plantedDate.toIso8601String(),
        'germination': germination,
        'pHLevel': pHLevel,
        'temperature': temperature,
        'growthRate': growthRate,
      };

      final updatedSeedling =
          await SeedlingService.updateSeedlingRaw(id, seedlingData);
      final index = _seedlings.indexWhere((s) => s['_id'] == id);
      if (index != -1) {
        _seedlings[index] = updatedSeedling;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Deletes a seedling by its ID
  Future<void> deleteSeedling(BuildContext context, String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await SeedlingService.deleteSeedlingRaw(id);
      _seedlings.removeWhere((s) => s['_id'] == id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Updates the seedlings list directly without making an API call
  void updateSeedlings(List<dynamic> seedlings) {
    _seedlings = seedlings;
    notifyListeners();
  }
}
