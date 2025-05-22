import 'package:flutter/foundation.dart';
import '../services/reading_service.dart';

class WaterTemperatureProvider with ChangeNotifier {
  Map<String, dynamic>? _latestReading;
  List<Map<String, dynamic>> _readings = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get latestReading => _latestReading;
  List<Map<String, dynamic>> get readings => _readings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLatestReading() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await WaterTemperatureService.getLatestReading();
      _latestReading = data;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReadings({
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await WaterTemperatureService.getReadings(
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
      _readings = data;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 