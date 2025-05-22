import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../services/seedling_service.dart';

/// SeedlingProvider manages the state of crop batches, particularly those with 'seedling' status.
/// It communicates with the server API through SeedlingService to perform CRUD operations.
/// The provider works directly with raw JSON data from the server, which includes virtual fields
/// calculated on the server side such as batchName, daysSincePlanting, and estimatedHeight.
class SeedlingProvider with ChangeNotifier {
  List<dynamic> _cropBatches = [];
  bool _isLoading = false;

  List<dynamic> get cropBatches => _cropBatches;
  bool get isLoading => _isLoading;

  void _sortCropBatches() {
    _cropBatches.sort((a, b) {
      final dateA = a['expectedTransplantDate'] != null ? DateTime.tryParse(a['expectedTransplantDate']) : null;
      final dateB = b['expectedTransplantDate'] != null ? DateTime.tryParse(b['expectedTransplantDate']) : null;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // Place nulls at the end
      if (dateB == null) return -1; // Place nulls at the end

      // Prioritize today's date
      final now = DateTime.now();
      final todayA = dateA.year == now.year && dateA.month == now.month && dateA.day == now.day;
      final todayB = dateB.year == now.year && dateB.month == now.month && dateB.day == now.day;

      if (todayA && !todayB) return -1;
      if (!todayA && todayB) return 1;

      return dateA.compareTo(dateB);
    });
  }

  /// Loads crop batches with 'seedling' status for the authenticated user
  Future<void> loadSeedlingCropBatches(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final batches = await SeedlingService.getAllCropBatchesRaw(status: 'seedling');
      _cropBatches = batches;
      _sortCropBatches();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Creates a new crop batch (defaults to 'seedling' status on backend)
  Future<void> createCropBatch(
    BuildContext context, {
    required String batchCode,
    required String plantType,
    required String healthStatus,
    required String notes,
    required DateTime plantedDate,
    required int quantity,
    DateTime? expectedTransplantDate,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cropBatchData = {
        'batchCode': batchCode,
        'plantType': plantType,
        'healthStatus': healthStatus,
        'notes': notes,
        'plantedDate': plantedDate.toIso8601String(),
        'quantity': quantity,
        if (expectedTransplantDate != null) 'expectedTransplantDate': expectedTransplantDate.toIso8601String(),
      };

      final newCropBatch = await SeedlingService.createCropBatchRaw(cropBatchData);
      _cropBatches.add(newCropBatch);
      _sortCropBatches();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Updates an existing crop batch
  Future<void> updateCropBatch(
    BuildContext context,
    String id, {
    required String batchCode,
    required String plantType,
    required String healthStatus,
    required String notes,
    required DateTime plantedDate,
    required int quantity,
    DateTime? expectedTransplantDate,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cropBatchData = {
        'batchCode': batchCode,
        'plantType': plantType,
        'healthStatus': healthStatus,
        'notes': notes,
        'plantedDate': plantedDate.toIso8601String(),
        'quantity': quantity,
        if (expectedTransplantDate != null) 'expectedTransplantDate': expectedTransplantDate.toIso8601String(),
      };

      final updatedCropBatch =
          await SeedlingService.updateCropBatchRaw(id, cropBatchData);
      final index = _cropBatches.indexWhere((s) => s['_id'] == id);
      if (index != -1) {
        _cropBatches[index] = updatedCropBatch;
      }
      _sortCropBatches();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Deletes a crop batch by its ID
  Future<void> deleteCropBatch(BuildContext context, String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await SeedlingService.deleteCropBatchRaw(id);
      _cropBatches.removeWhere((s) => s['_id'] == id);
      _sortCropBatches();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Updates the crop batches list directly without making an API call
  /// This is used by seedling_insights_screen.dart
  void updateCropBatchesList(List<dynamic> batches) {
    _cropBatches = batches;
    _sortCropBatches();
    notifyListeners();
  }
}
