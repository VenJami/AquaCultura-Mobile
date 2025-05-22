import 'package:flutter/material.dart';
import '../services/seedling_service.dart';

/// Provider class for managing the state of transplanted crop batches.
/// It fetches crop batches with 'transplanted' status using SeedlingService.
class TransplantProvider with ChangeNotifier {
  List<dynamic> _transplantedCropBatches = [];
  bool _isLoading = false;

  List<dynamic> get transplantedCropBatches => _transplantedCropBatches;
  bool get isLoading => _isLoading;

  void _sortTransplantedCropBatches() {
    _transplantedCropBatches.sort((a, b) {
      final dateAString = a['transplantDetails']?['expectedHarvestDate'];
      final dateBString = b['transplantDetails']?['expectedHarvestDate'];

      final dateA = dateAString != null ? DateTime.tryParse(dateAString) : null;
      final dateB = dateBString != null ? DateTime.tryParse(dateBString) : null;

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

  /// Loads all crop batches with 'transplanted' status for the authenticated user
  Future<void> loadTransplantedCropBatches(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final batches = await SeedlingService.getAllCropBatchesRaw(status: 'transplanted');
      _transplantedCropBatches = batches;
      _sortTransplantedCropBatches();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transplanted batches: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Optionally, a method to clear data or refresh could be added here if needed.
  void clearTransplantedBatches() {
    _transplantedCropBatches = [];
    _sortTransplantedCropBatches();
    notifyListeners();
  }
}
