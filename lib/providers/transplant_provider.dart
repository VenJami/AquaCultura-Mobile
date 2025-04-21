import 'package:flutter/material.dart';
import '../services/transplant_service.dart';

/// Provider class for managing transplant-related state
/// Uses raw JSON data from the server API to avoid model coupling
class TransplantProvider with ChangeNotifier {
  List<dynamic> _transplants = [];
  bool _isLoading = false;

  List<dynamic> get transplants => _transplants;
  bool get isLoading => _isLoading;

  /// Loads all transplants for the authenticated user
  Future<void> loadTransplants(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final transplants = await TransplantService.getAllTransplantsRaw();
      _transplants = transplants;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transplants: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Creates a new transplant with the provided data
  Future<void> createTransplant(
    BuildContext context,
    Map<String, dynamic> transplantData,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newTransplant =
          await TransplantService.createTransplantRaw(transplantData);
      _transplants.add(newTransplant);

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transplant created successfully'),
          ),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating transplant: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Updates an existing transplant with new data
  Future<void> updateTransplant(
    BuildContext context,
    String id,
    Map<String, dynamic> transplantData,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updatedTransplant =
          await TransplantService.updateTransplantRaw(id, transplantData);

      // Update the transplant in the local list
      final index =
          _transplants.indexWhere((transplant) => transplant['_id'] == id);
      if (index != -1) {
        _transplants[index] = updatedTransplant;
      }

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transplant updated successfully'),
          ),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating transplant: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Deletes a transplant from the server
  Future<void> deleteTransplant(BuildContext context, String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await TransplantService.deleteTransplant(id);

      // Remove the transplant from the local list
      _transplants.removeWhere((transplant) => transplant['_id'] == id);

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transplant deleted successfully'),
          ),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transplant: ${e.toString()}'),
          ),
        );
      }
    }
  }
}
