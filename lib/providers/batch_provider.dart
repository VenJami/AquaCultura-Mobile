import 'package:flutter/material.dart';
import '../services/batch_service.dart';

/// Provider class for managing batch-related state
/// Uses raw JSON data from the server API to avoid model coupling
class BatchProvider with ChangeNotifier {
  List<dynamic> _batches = [];
  bool _isLoading = false;

  List<dynamic> get batches => _batches;
  bool get isLoading => _isLoading;

  /// Loads all batches for the authenticated user
  Future<void> loadBatches(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final batches = await BatchService.getAllBatchesRaw();
      _batches = batches;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading batches: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Gets a batch by ID
  Future<dynamic> getBatchById(String id) async {
    try {
      return await BatchService.getBatchByIdRaw(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new batch with the provided data
  Future<void> createBatch(
    BuildContext context,
    Map<String, dynamic> batchData,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newBatch = await BatchService.createBatchRaw(batchData);
      _batches.add(newBatch);

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch created successfully'),
          ),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating batch: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Updates an existing batch with new data
  Future<void> updateBatch(
    BuildContext context,
    String id,
    Map<String, dynamic> batchData,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updatedBatch = await BatchService.updateBatchRaw(id, batchData);

      // Update the batch in the local list
      final index = _batches.indexWhere((batch) => batch['_id'] == id);
      if (index != -1) {
        _batches[index] = updatedBatch;
      }

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch updated successfully'),
          ),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating batch: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Deletes a batch from the server
  Future<void> deleteBatch(BuildContext context, String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await BatchService.deleteBatch(id);

      // Remove the batch from the local list
      _batches.removeWhere((batch) => batch['_id'] == id);

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch deleted successfully'),
          ),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting batch: ${e.toString()}'),
          ),
        );
      }
    }
  }
}
