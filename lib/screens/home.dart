import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/seedling_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/due_items_notification_provider.dart';
import '../providers/general_notification_provider.dart';
import 'notification_page.dart';
import 'my_task_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'seedling_insights.dart';
import '../services/seedling_service.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'transplant_crop_insight.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<bool> _taskTeamToggleSelection = [true, false];

  bool _teamTask1Completed = false;
  bool _teamTask2Completed = false;

  List<dynamic> _seedlings = [];
  bool _isLoadingSeedlings = true;

  // Revised state variables for Transplant Insight (summary of transplanted batches)
  List<dynamic> _transplantedBatchesSummary = [];
  bool _isLoadingTransplantInsights = true;

  // State variables for Survival Rate Analytics
  bool _isLoadingSurvivalRates = true;
  double? _avgSeedlingToTransplantSurvivalRate;
  double? _avgTransplantToHarvestSurvivalRate;
  double? _avgOverallSurvivalRate;
  List<FlSpot> _seedlingToTransplantSurvivalHistoryData = [];
  List<FlSpot> _transplantToHarvestSurvivalHistoryData = [];
  List<FlSpot> _overallSurvivalHistoryData = [];

  // Cache for expensive calculations
  String? _cachedSeedlingAge;
  String? _cachedSeedlingAgeStatus;

    // Add state for latest readings
  bool _isLoadingReading = true;
  double? _latestTemperature;
  double? _latestPh;
  List<FlSpot> _tempChartData = [];
  List<FlSpot> _phChartData = [];
  Timer? _refreshTimer;
  
  // Cache for survival rate analytics
  double? _cachedAvgSeedlingToTransplantSurvivalRate;
  String? _cachedSeedlingToTransplantSurvivalStatus; // e.g., "Avg. Rate"
  double? _cachedAvgTransplantToHarvestSurvivalRate;
  String? _cachedTransplantToHarvestSurvivalStatus;
  double? _cachedAvgOverallSurvivalRate;
  String? _cachedOverallSurvivalStatus;
  List<FlSpot> _cachedSeedlingToTransplantSurvivalHistoryData = [];
  List<FlSpot> _cachedTransplantToHarvestSurvivalHistoryData = [];
  List<FlSpot> _cachedOverallSurvivalHistoryData = [];

  // Add state for last pump message
  String? _lastPumpMessage;
  String? _minutesAgo;

  // --- Placeholder Chart Data ---

  final List<FlSpot> _nutrientChartData = [
    const FlSpot(0, 4),
    const FlSpot(1, 5),
    const FlSpot(2, 6),
    const FlSpot(3, 5),
    const FlSpot(4, 4),
    const FlSpot(5, 5),
    const FlSpot(6, 6),
  ];
  // --- End Placeholder Data ---

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshHomeScreenData();
      Provider.of<GeneralNotificationProvider>(context, listen: false).fetchNotifications();
      Provider.of<DueItemsNotificationProvider>(context, listen: false).loadDueItemsNotifications();
      
      // Start polling for the latest readings
      _fetchLatestReadings();
          _refreshTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _fetchLatestReadings();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLatestReadings() async {
    setState(() {
      _isLoadingReading = true;
    });

    try {
      // Fetch the latest readings
      final Map<String, dynamic> waterReadings = await ApiService.getLatestReadings();
      print('Water Readings: $waterReadings'); // Debug: Log the water readings

      // Extract the timestamp from the readings
      DateTime? lastPumpOnTime;
      if (waterReadings['timestamp'] != null) {
        lastPumpOnTime = DateTime.parse(waterReadings['timestamp']).toLocal(); // Get the timestamp
        print('Last Pump On Time: $lastPumpOnTime'); // Debug: Log the last pump time
      }

      // Check if the readings have changed
      if (waterReadings.isNotEmpty) {
        setState(() {
          double currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
          double temperature = waterReadings['temperature']?.toDouble() ?? 0.0;
          double ph = waterReadings['ph']?.toDouble() ?? 0.0;

          // Add new readings to the chart data
          _tempChartData.add(FlSpot(currentTime, temperature));
          _phChartData.add(FlSpot(currentTime, ph));

          // Keep only the latest 7 readings
          if (_tempChartData.length > 7) {
            _tempChartData.removeAt(0); // Remove the oldest reading
          }
          if (_phChartData.length > 7) {
            _phChartData.removeAt(0); // Remove the oldest reading
          }

          // Update the latest values
          _latestTemperature = temperature;
          _latestPh = ph;

          // Update the last pump time display with formatted timestamp
          if (lastPumpOnTime != null) {
            String formattedTime = DateFormat('MMM d, yyyy, h:mm a').format(lastPumpOnTime); // Format the timestamp
            final duration = DateTime.now().difference(lastPumpOnTime);
            String relativeTime = duration.inMinutes > 0 ? '${duration.inMinutes} minutes ago' : 'Just now';
            _lastPumpMessage = '$formattedTime';
            _minutesAgo = '$relativeTime'; // Combine formatted time and relative time
          } else {
            _lastPumpMessage = 'Never'; // Or some default message
          }
        });
      }
      _isLoadingReading = false;
    } catch (e) {
      print('Error fetching water readings: $e');
      setState(() {
        _isLoadingReading = false;
      });
    }
  }

  Future<void> _refreshHomeScreenData() async {
    setState(() {
      _isLoadingSeedlings = true;
      _isLoadingTransplantInsights = true; 
      _isLoadingSurvivalRates = true;
      _isLoadingReading = true;
    });

    try {
      // Fetch seedlings, transplanted summary, and tasks concurrently
      final results = await Future.wait([
        _fetchSeedlings(),
        _fetchTransplantedBatchesSummary(), // Fetch summary of transplanted batches
        _fetchTasks(),
        _fetchBatchDataForAnalytics(), // Fetch all data for survival analytics
        _fetchLatestReadings(),
      ]);

      final fetchedSeedlings = results[0] as List<dynamic>?;
      final fetchedTransplantedSummary = results[1] as List<dynamic>?; // Result from new method
      final allBatchesForAnalytics = results[3] as List<dynamic>?; // Result for survival analytics

      setState(() {
        _seedlings = fetchedSeedlings ?? [];
        _isLoadingSeedlings = false;
        if (fetchedSeedlings != null) {
          _updateCalculationCache();
          // _updateTransplantInsights(); // This method is removed/replaced by direct fetch
        }
        
        _transplantedBatchesSummary = fetchedTransplantedSummary ?? [];
        _isLoadingTransplantInsights = false;

        if (allBatchesForAnalytics != null) {
          _calculateSurvivalRateAnalytics(allBatchesForAnalytics);
        }
        _isLoadingSurvivalRates = false;
      });

    } catch (e) {
      setState(() {
        _seedlings = [];
        _isLoadingSeedlings = false;
        _transplantedBatchesSummary = [];
        _isLoadingTransplantInsights = false;
        _isLoadingSurvivalRates = false;
        _isLoadingReading = false;
      });
    }
  }

  Future<List<dynamic>?> _fetchSeedlings() async {
    final seedlingProvider = Provider.of<SeedlingProvider>(context, listen: false);
    try {
      final response = await SeedlingService.getAllCropBatchesRaw(status: 'seedling'); 
      if (response.isNotEmpty) {
        // Format today's date for proper comparison
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Two-tier sorting: first separate today's items, then sort each group by date
        final todayItems = <dynamic>[];
        final futureItems = <dynamic>[];
        
        // First pass: separate today's items from future items
        for (var item in response) {
          bool isToday = false;
          DateTime? targetDate;
          
          // Check expected transplant date
          if (item['expectedTransplantDate'] != null) {
            targetDate = DateTime.tryParse(item['expectedTransplantDate']);
          } else if (item['calculatedExpectedTransplantDate'] != null) {
            targetDate = DateTime.tryParse(item['calculatedExpectedTransplantDate']);
          }
          
          if (targetDate != null) {
            // Compare dates without time component
            final itemDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
            isToday = itemDate.isAtSameMomentAs(today);
            print("Item ${item['batchName']} date: $itemDate, isToday: $isToday");
          }
          
          if (isToday) {
            todayItems.add(item);
          } else {
            futureItems.add(item);
          }
        }
        
        // Sort each group by date
        todayItems.sort((a, b) {
          final dateA = a['expectedTransplantDate'] != null ? 
              DateTime.tryParse(a['expectedTransplantDate']) : 
              DateTime.tryParse(a['calculatedExpectedTransplantDate'] ?? '');
          final dateB = b['expectedTransplantDate'] != null ? 
              DateTime.tryParse(b['expectedTransplantDate']) : 
              DateTime.tryParse(b['calculatedExpectedTransplantDate'] ?? '');
              
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });
        
        futureItems.sort((a, b) {
          final dateA = a['expectedTransplantDate'] != null ? 
              DateTime.tryParse(a['expectedTransplantDate']) : 
              DateTime.tryParse(a['calculatedExpectedTransplantDate'] ?? '');
          final dateB = b['expectedTransplantDate'] != null ? 
              DateTime.tryParse(b['expectedTransplantDate']) : 
              DateTime.tryParse(b['calculatedExpectedTransplantDate'] ?? '');
              
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });
        
        // Combine the groups with today's items first
        final sortedResponse = [...todayItems, ...futureItems];
        
        print("SORTED SEEDLINGS (${sortedResponse.length} items):");
        for (var item in sortedResponse) {
          final dateStr = item['expectedTransplantDate'] ?? item['calculatedExpectedTransplantDate'] ?? 'no date';
          final dateObj = DateTime.tryParse(dateStr);
          final formattedDate = dateObj != null ? "${dateObj.year}-${dateObj.month.toString().padLeft(2, '0')}-${dateObj.day.toString().padLeft(2, '0')}" : dateStr;
          print("- ${item['batchName']}: $formattedDate");
        }
        
        seedlingProvider.updateCropBatchesList(sortedResponse); 
        return sortedResponse;
      } else {
        seedlingProvider.updateCropBatchesList([]); 
        return []; 
      }
    } catch (e) {
      print("Error fetching seedlings: $e");
      seedlingProvider.updateCropBatchesList([]); 
      return null; 
    }
  }

  // New method to fetch a summary of transplanted batches
  Future<List<dynamic>?> _fetchTransplantedBatchesSummary() async {
    try {
      final response = await SeedlingService.getAllCropBatchesRaw(status: 'transplanted');
      
      // Format today's date for proper comparison
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Two-tier sorting: first separate today's items, then sort each group by date
      final todayItems = <dynamic>[];
      final futureItems = <dynamic>[];
      
      // First pass: separate today's items from future items
      for (var item in response) {
        bool isToday = false;
        DateTime? targetDate;
        
        // Check expected harvest date
        if (item['transplantDetails'] != null && item['transplantDetails']['expectedHarvestDate'] != null) {
          targetDate = DateTime.tryParse(item['transplantDetails']['expectedHarvestDate']);
        }
        
        if (targetDate != null) {
          // Compare dates without time component
          final itemDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
          isToday = itemDate.isAtSameMomentAs(today);
          print("Transplant ${item['batchName']} date: $itemDate, isToday: $isToday");
        }
        
        if (isToday) {
          todayItems.add(item);
        } else {
          futureItems.add(item);
        }
      }
      
      // Sort each group by date
      todayItems.sort((a, b) {
        final dateA = a['transplantDetails']?['expectedHarvestDate'] != null ? 
            DateTime.tryParse(a['transplantDetails']['expectedHarvestDate']) : null;
        final dateB = b['transplantDetails']?['expectedHarvestDate'] != null ? 
            DateTime.tryParse(b['transplantDetails']['expectedHarvestDate']) : null;
            
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });
      
      futureItems.sort((a, b) {
        final dateA = a['transplantDetails']?['expectedHarvestDate'] != null ? 
            DateTime.tryParse(a['transplantDetails']['expectedHarvestDate']) : null;
        final dateB = b['transplantDetails']?['expectedHarvestDate'] != null ? 
            DateTime.tryParse(b['transplantDetails']['expectedHarvestDate']) : null;
            
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });
      
      // Combine the groups with today's items first
      final sortedResponse = [...todayItems, ...futureItems];
      
      print("SORTED TRANSPLANTS (${sortedResponse.length} items):");
      for (var item in sortedResponse) {
        final dateStr = item['transplantDetails']?['expectedHarvestDate'] ?? 'no date';
        final dateObj = DateTime.tryParse(dateStr);
        final formattedDate = dateObj != null ? "${dateObj.year}-${dateObj.month.toString().padLeft(2, '0')}-${dateObj.day.toString().padLeft(2, '0')}" : dateStr;
        print("- ${item['batchName']}: $formattedDate");
      }
      
      return sortedResponse;
    } catch (e) {
      print("Error fetching transplanted batches: $e");
      return null;
    }
  }

  Future<void> _fetchTasks() async {
    try {
      await Provider.of<TaskProvider>(context, listen: false).loadTasks(context);
    } catch (e) {
    }
  }

  // New method to fetch all batch data needed for survival analytics
  Future<List<dynamic>?> _fetchBatchDataForAnalytics() async {
    // This method will fetch seedling, transplanted, and harvested batches.
    // For now, it's a placeholder. Implementation will follow.
    try {
      final seedlingBatches = await SeedlingService.getAllCropBatchesRaw(status: 'seedling');
      final transplantedBatches = await SeedlingService.getAllCropBatchesRaw(status: 'transplanted');
      final harvestedBatches = await SeedlingService.getAllCropBatchesRaw(status: 'harvested');
      
      // Combine all batches. We might need to merge them intelligently later
      // if a single batch moves through statuses but is fetched as separate documents.
      // Assuming for now `_id` is consistent and we can reconcile.
      // Or, better, if the backend can provide a comprehensive view for analytics.
      // For now, just returning a combined list. Need to ensure no duplicates if _id is same.
      
      // Simple combination:
      // List<dynamic> allBatches = [...seedlingBatches, ...transplantedBatches, ...harvestedBatches];
      
      // More robust way to combine, assuming `_id` is the unique identifier for a batch across its lifecycle
      // This is important if a batch appears in multiple lists due to its current status.
      // However, the current service call fetches based on a *single* status.
      // So, a batch is either 'seedling', 'transplanted', OR 'harvested' from these calls.
      // The goal is to get all *distinct* batches and their *full history* if possible,
      // or at least enough info for the chain calculation.
      
      // For survival rate, we need to trace a batch from seedling qty to transplant qty to harvest qty.
      // The current `getAllCropBatchesRaw` fetches based on *current* status.
      // This means a harvested batch will have its seedling and transplant info within its document.
      
      // So, fetching all 'harvested' batches should give us the most complete data for full-cycle analysis.
      // Fetching all 'transplanted' batches for seedling->transplant.
      // Fetching all 'seedling' batches for current seedling counts (less relevant for *historical* survival).

      // Let's fetch ALL batches and the calculation logic will sift through them.
      // The backend model `cropBatch.js` implies that a single document transitions status
      // and accumulates details (transplantDetails, harvestDetails).
      // So, fetching all documents without a status filter, or with multiple statuses, would be ideal
      // if the service supported it. Since it doesn't, we fetch all and then process.
      // The most "complete" batches for full lifecycle are those with status 'harvested'.
      // The ones with 'transplanted' have seedling and transplant info.

      // For now, let's fetch all batches of all three types.
      // The calculation logic will need to be smart about linking these if they are separate items
      // or interpreting them if they are single items with full history.
      // Given `cropBatch.js` structure, a single batch document transitions its status and accumulates data.
      // So if we fetch status: 'harvested', it should contain previous stage data.

      // Fetching all batches and then filtering/processing:
      List<dynamic> allBatches = [];
      allBatches.addAll(await SeedlingService.getAllCropBatchesRaw(status: 'seedling'));
      allBatches.addAll(await SeedlingService.getAllCropBatchesRaw(status: 'transplanted'));
      allBatches.addAll(await SeedlingService.getAllCropBatchesRaw(status: 'harvested'));
      
      // Remove duplicates by _id, preferring the one with more complete data (e.g. harvested over seedling)
      final Map<String, dynamic> uniqueBatches = {};
      for (var batch in allBatches) {
        final id = batch['_id'] as String;
        if (!uniqueBatches.containsKey(id) || 
            _getBatchStagePriority(batch) > _getBatchStagePriority(uniqueBatches[id]!)) {
          uniqueBatches[id] = batch;
        }
      }
      return uniqueBatches.values.toList();

    } catch (e) {
      print("Error fetching batch data for analytics: $e");
      return null;
    }
  }

  // Helper to prioritize batches if duplicates are found (e.g., harvested is most complete)
  int _getBatchStagePriority(Map<String, dynamic> batch) {
    final status = batch['status'];
    if (status == 'harvested') return 3;
    if (status == 'transplanted') return 2;
    if (status == 'seedling') return 1;
    return 0;
  }

  // Placeholder for survival rate calculation logic
  void _calculateSurvivalRateAnalytics(List<dynamic> allBatches) {
    if (allBatches.isEmpty) {
      setState(() {
        _avgSeedlingToTransplantSurvivalRate = null; // Or some default like 0.0 or 100.0 based on user's "100%" comment
        _avgTransplantToHarvestSurvivalRate = null;
        _avgOverallSurvivalRate = null;
        _seedlingToTransplantSurvivalHistoryData = [];
        _transplantToHarvestSurvivalHistoryData = [];
        _overallSurvivalHistoryData = [];
        _updateSurvivalRateCache(); // Update cache with empty/default values
      });
      return;
    }

    // --- Seedling to Transplant Survival ---
    List<double> seedlingToTransplantRates = [];
    List<FlSpot> s2tHistory = [];
    int s2tBatchCounter = 0;

    // Sort batches by creation date for more meaningful history chart if possible
    // This assumes 'createdAt' is a reliable ISO string. Add error handling if not.
    try {
      allBatches.sort((a, b) {
        DateTime? dateA = DateTime.tryParse(a['createdAt'] ?? '');
        DateTime? dateB = DateTime.tryParse(b['createdAt'] ?? '');
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return -1; // Sort nulls first or last as preferred
        if (dateB == null) return 1;
        return dateA.compareTo(dateB); // Ascending by creation time
      });
    } catch (e) {
      // Proceed with unsorted if sorting fails
    }
    

    for (var batch in allBatches) {
      final initialQty = batch['quantity'] as num?;

      if (initialQty != null && initialQty > 0) {
        double currentRate; // Rate for this specific batch for S2T stage

        if (batch['status'] == 'seedling') {
          // For active seedlings, current survival to transplant is 100%
          currentRate = 100.0;
        } else if (batch['status'] == 'transplanted' || batch['status'] == 'harvested') {
          final transplantedQty = batch['transplantDetails']?['quantityTransplanted'] as num?;
          if (transplantedQty != null && transplantedQty > 0) {
            currentRate = (transplantedQty / initialQty) * 100.0;
          } else {
            // If transplanted/harvested but no valid transplant qty, treat as 0% for this stage (or skip?)
            // For now, let's treat as 0% for this batch at this stage if data is missing post-seedling stage.
            currentRate = 0.0; 
          }
        } else {
          // Other statuses (e.g., disposed) - skip for S2T calculation or assign specific rate?
          continue; // Skip this batch for S2T average
        }
        
        seedlingToTransplantRates.add(currentRate);
        s2tHistory.add(FlSpot(s2tBatchCounter.toDouble(), currentRate));
        s2tBatchCounter++;

      } else {
        // Skip this batch for S2T average
      }
    }

    if (seedlingToTransplantRates.isNotEmpty) {
      _avgSeedlingToTransplantSurvivalRate = seedlingToTransplantRates.reduce((a, b) => a + b) / seedlingToTransplantRates.length;
    } else {
      _avgSeedlingToTransplantSurvivalRate = null; // Will display 100% as per requirement
    }
    // Take last 7 for chart, or fewer if less data. History is already chronologically sorted.
    _seedlingToTransplantSurvivalHistoryData = s2tHistory.length > 7 ? s2tHistory.sublist(s2tHistory.length - 7) : s2tHistory;


    // --- Transplant to Harvest Survival ---
    List<double> transplantToHarvestRates = [];
    List<FlSpot> t2hHistory = [];
    int t2hBatchCounter = 0;

    // Filter for harvested batches and sort by harvestDate for history chart
    List<dynamic> harvestedBatchesForT2H = allBatches.where((b) => b['status'] == 'harvested').toList();
    try {
       harvestedBatchesForT2H.sort((a, b) {
        DateTime? dateA = DateTime.tryParse(a['harvestDetails']?['harvestDate'] ?? '');
        DateTime? dateB = DateTime.tryParse(b['harvestDetails']?['harvestDate'] ?? '');
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return -1;
        if (dateB == null) return 1;
        return dateA.compareTo(dateB); // Ascending by harvest time
      });
    } catch (e) {
      // Proceed with unsorted if sorting fails
    }

    for (var batch in harvestedBatchesForT2H) {
      final transplantedQty = batch['transplantDetails']?['quantityTransplanted'] as num?;
      final harvestedQty = batch['harvestDetails']?['quantityHarvested'] as num?;

      if (transplantedQty != null && transplantedQty > 0 && harvestedQty != null && harvestedQty > 0) {
        double rate = (harvestedQty / transplantedQty) * 100.0;
        transplantToHarvestRates.add(rate);
        t2hHistory.add(FlSpot(t2hBatchCounter.toDouble(), rate));
        t2hBatchCounter++;
      } else {
        // Skip this batch for T2H average
      }
    }

    if (transplantToHarvestRates.isNotEmpty) {
      _avgTransplantToHarvestSurvivalRate = transplantToHarvestRates.reduce((a, b) => a + b) / transplantToHarvestRates.length;
    } else {
      _avgTransplantToHarvestSurvivalRate = null;
    }
    _transplantToHarvestSurvivalHistoryData = t2hHistory.length > 7 ? t2hHistory.sublist(t2hHistory.length - 7) : t2hHistory;


    // --- Overall Survival (Seedling to Harvest) ---
    List<double> overallRates = [];
    List<FlSpot> overallHistory = [];
    int overallBatchCounter = 0;

    // Using the same sorted harvestedBatchesForT2H as it's relevant here too
    for (var batch in harvestedBatchesForT2H) {
      final initialQty = batch['quantity'] as num?;
      final harvestedQty = batch['harvestDetails']?['quantityHarvested'] as num?;

      if (initialQty != null && initialQty > 0 && harvestedQty != null && harvestedQty > 0) {
        double rate = (harvestedQty / initialQty) * 100.0;
        overallRates.add(rate);
        overallHistory.add(FlSpot(overallBatchCounter.toDouble(), rate));
        overallBatchCounter++;
      } else {
        // Skip this batch for overall average
      }
    }

    if (overallRates.isNotEmpty) {
      _avgOverallSurvivalRate = overallRates.reduce((a, b) => a + b) / overallRates.length;
    } else {
      _avgOverallSurvivalRate = null;
    }
    _overallSurvivalHistoryData = overallHistory.length > 7 ? overallHistory.sublist(overallHistory.length - 7) : overallHistory;
    
    _updateSurvivalRateCache();
  }

  // New method to update survival rate cache
  void _updateSurvivalRateCache() {
    _cachedAvgSeedlingToTransplantSurvivalRate = _avgSeedlingToTransplantSurvivalRate;
    _cachedSeedlingToTransplantSurvivalStatus = _avgSeedlingToTransplantSurvivalRate != null ? "Avg. Rate" : "N/A";
    _cachedAvgTransplantToHarvestSurvivalRate = _avgTransplantToHarvestSurvivalRate;
    _cachedTransplantToHarvestSurvivalStatus = _avgTransplantToHarvestSurvivalRate != null ? "Avg. Rate" : "N/A";
    _cachedAvgOverallSurvivalRate = _avgOverallSurvivalRate;
    _cachedOverallSurvivalStatus = _avgOverallSurvivalRate != null ? "Avg. Rate" : "N/A";
    
    _cachedSeedlingToTransplantSurvivalHistoryData = List.from(_seedlingToTransplantSurvivalHistoryData);
    _cachedTransplantToHarvestSurvivalHistoryData = List.from(_transplantToHarvestSurvivalHistoryData);
    _cachedOverallSurvivalHistoryData = List.from(_overallSurvivalHistoryData);
  }

  // Update all cached calculations at once
  void _updateCalculationCache() {
    if (_seedlings.isEmpty) return;

    _cachedSeedlingAge = '${_getLatestSeedlingAge(_seedlings)}'; // Just days number
    _cachedSeedlingAgeStatus = _getLatestSeedlingAgeStatus(_seedlings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;

    // Consume notification providers
    final dueItemsProvider = Provider.of<DueItemsNotificationProvider>(context);
    final generalNotificationProvider = Provider.of<GeneralNotificationProvider>(context);

    final bool hasUnreadDueItems = dueItemsProvider.dueCropNotifications.any((n) => !dueItemsProvider.isCropNotificationRead(n['_id'])) ||
                                 dueItemsProvider.dueTaskNotifications.any((n) => !dueItemsProvider.isTaskNotificationRead(n['_id']));
    final bool hasUnreadSystemMessages = generalNotificationProvider.unreadCount > 0;
    final bool showNotificationBadge = hasUnreadDueItems || hasUnreadSystemMessages;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80, // Increased height for content
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                Colors.blue.shade400, // Lighter blue at center
                Theme.of(context).primaryColor,
              ],
              stops: [0.0, 1.0],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Good Morning', // This was static, can be dynamic if needed
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary),
            ),
            Text(
              user?.name ?? 'User',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
            Text(
              'Shift: ${user?.schedule ?? "8:00 AM - 4:00 PM"}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
            ),
          ],
        ),
        actions: [
          _buildAppBarAction(
            Icons.notifications_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
            badge: showNotificationBadge
                ? Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: const Text( // Optional: show count
                        '', // Empty string for just a dot, or use generalNotificationProvider.unreadCount.toString()
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : null,
          ),
          _buildAppBarAction(Icons.settings_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          }),
          const SizedBox(width: 8), // Spacing at the end
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHomeScreenData, // Use combined refresh for pull-to-refresh
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Horizontal padding
          child: ListView(
            children: [
              const SizedBox(height: 16), // Space below AppBar
              // --- Farm Status Section Header ---
              _buildSectionHeader('Farm Status', Icons.water_drop_outlined,
                  colorScheme.primary),
              const SizedBox(height: 12),

              // --- Info Cards Grid ---
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.9, // Adjusted for chart space
                children: [
                  _buildInfoCard(
                    context,
                    'Water Temperature',
                    _isLoadingReading
                        ? 'Loading...'
                        : _latestTemperature != null
                            ? '${_latestTemperature!.toStringAsFixed(2)}°C'
                            : 'N/A',
                    _isLoadingReading
                        ? 'Loading...'
                        : _latestTemperature != null
                            ? (_latestTemperature! < 18 ? 'Low' : _latestTemperature! > 30 ? 'High' : 'Normal')
                            : 'Unknown',
                    Icons.thermostat,
                    _tempChartData,
                   Colors.blue,
                  ),
                  _buildInfoCard(
                    context,
                    'PH Level',
                    _isLoadingReading
                        ? 'Loading...'
                        : _latestPh != null
                            ? _latestPh!.toStringAsFixed(2)
                            : 'N/A',
                    _isLoadingReading
                        ? 'Loading...'
                        : _latestPh != null
                            ? (_latestPh! < 5.5 ? 'Low' : _latestPh! > 7.0 ? 'High' : 'Normal')
                            : 'Unknown',
                    Icons.science_outlined,
                    _phChartData,
                    Colors.orange,
                  ),
                  _buildInfoCard(
                    context,
                    'Nutrient Control',
                    _minutesAgo ?? 'Never', // Display the last pump message
                    _lastPumpMessage ?? 'Never', // Status can be adjusted as needed
                    Icons.spa_outlined,
                    _nutrientChartData,
                    Colors.green,
                  ),
                  _buildInfoCard(
                    context,
                    'Crop Insights',
                    _isLoadingSurvivalRates || _cachedAvgSeedlingToTransplantSurvivalRate == null
                        ? '100%' // Display 100% if loading or no data
                        : '${_cachedAvgSeedlingToTransplantSurvivalRate!.toStringAsFixed(1)}%',
                    _isLoadingSurvivalRates
                        ? 'Loading...'
                        : (_cachedAvgSeedlingToTransplantSurvivalRate == null
                            ? 'Initial Stage' // Status when 100% is shown due to no data
                            : _cachedSeedlingToTransplantSurvivalStatus ?? 'Avg. Survival'),
                    Icons.trending_up, // New Icon
                    _isLoadingSurvivalRates || _cachedAvgSeedlingToTransplantSurvivalRate == null
                        ? [] // Pass empty list for chart if 100% is shown or loading
                        : _cachedSeedlingToTransplantSurvivalHistoryData,
                    Colors.blue, // New Color
                    minYChartValue: 0, // Y-axis for percentage
                    maxYChartValue: 105, // Y-axis for percentage ( slightly > 100 for padding)
                  ),
                  // --- New Survival Rate Info Cards ---
                  // _buildInfoCard(
                  //   context,
                  //   'Seedling Survival',
                  //   _isLoadingSurvivalRates 
                  //       ? 'Loading...' 
                  //       : _cachedAvgSeedlingToTransplantSurvivalRate != null 
                  //           ? '${_cachedAvgSeedlingToTransplantSurvivalRate!.toStringAsFixed(1)}%' 
                  //           : 'N/A',
                  //   _isLoadingSurvivalRates ? '' : (_cachedSeedlingToTransplantSurvivalStatus ?? 'N/A'),
                  //   Icons.trending_up, // Example icon
                  //   _isLoadingSurvivalRates ? [] : _cachedSeedlingToTransplantSurvivalHistoryData,
                  //   Colors.cyan, // Example color
                  // ),
                  // _buildInfoCard(
                  //   context,
                  //   'Transplant Yield',
                  //    _isLoadingSurvivalRates 
                  //       ? 'Loading...' 
                  //       : _cachedAvgTransplantToHarvestSurvivalRate != null 
                  //           ? '${_cachedAvgTransplantToHarvestSurvivalRate!.toStringAsFixed(1)}%' 
                  //           : 'N/A',
                  //   _isLoadingSurvivalRates ? '' : (_cachedTransplantToHarvestSurvivalStatus ?? 'N/A'),
                  //   Icons.shield_outlined, // Example icon
                  //   _isLoadingSurvivalRates ? [] : _cachedTransplantToHarvestSurvivalHistoryData,
                  //   Colors.teal, // Example color
                  // ),
                  // _buildInfoCard(
                  //   context,
                  //   'Overall Yield',
                  //   _isLoadingSurvivalRates 
                  //       ? 'Loading...' 
                  //       : _cachedAvgOverallSurvivalRate != null 
                  //           ? '${_cachedAvgOverallSurvivalRate!.toStringAsFixed(1)}%' 
                  //           : 'N/A',
                  //   _isLoadingSurvivalRates ? '' : (_cachedOverallSurvivalStatus ?? 'N/A'),
                  //   Icons.pie_chart_outline, // Example icon
                  //   _isLoadingSurvivalRates ? [] : _cachedOverallSurvivalHistoryData,
                  //   Colors.pink, // Example color
                  // ),
                ],
              ),
              const SizedBox(height: 20),
              // --- Crop Insight Section Header ---
              _buildSectionHeader(
                  'Crop Insight', Icons.eco_outlined, colorScheme.primary),
              const SizedBox(height: 12),
              // --- Seedlings List Card ---
              Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16.0, top: 16, right: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeedlingsInsightsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Seedlings Insight', // Title inside card now
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    _isLoadingSeedlings
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _seedlings.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 30.0),
                                  child: Text(
                                    'No seedlings available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: _seedlings
                                    .take(4) // Show only first 4 seedlings
                                    .map(
                                      (seedling) =>
                                          _buildSeedlingItemFromData(seedling),
                                    )
                                    .toList(),
                              ),
                  ],
                ),
              ),
              const SizedBox(height: 12), // Add spacing between cards

              // --- Add Transplant Insight Card --- 
              _buildTransplantInsightCard(),
              // --- End Transplant Insight Card --- 

              const SizedBox(height: 24),

              // --- Restore Task/Team Toggle Buttons ---
              Center(
                child: ToggleButtons(
                  isSelected: _taskTeamToggleSelection,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _taskTeamToggleSelection.length; i++) {
                        _taskTeamToggleSelection[i] = i == index;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  selectedColor: colorScheme.onPrimary,
                  color: colorScheme.primary,
                  fillColor: colorScheme.primary,
                  constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 18),
                          SizedBox(width: 8),
                          Text('My Task'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Team'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // --- Restore Task/Team Sections ---
              if (_taskTeamToggleSelection[0])
                _buildMyTaskSection()
              else if (_taskTeamToggleSelection[1])
                _buildTeamSection(),

              const SizedBox(height: 24),
              // --- Restore Calendar Section Header & Widget ---
              _buildSectionHeader('Calendar Overview', Icons.calendar_today_outlined,
                  colorScheme.primary),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Padding inside card
                  child: _buildCalendarWidget(),
                ),
              ),
              const SizedBox(height: 24), // Spacing at the end
            ],
          ),
        ),
      ),
    );
  }

  // Helper for AppBar actions
  Widget _buildAppBarAction(IconData icon, VoidCallback onPressed, {Widget? badge}) {
    return Stack(
      children: <Widget>[
        IconButton(
          icon: Icon(icon, size: 28), // Increased size slightly
          onPressed: onPressed,
          color: Theme.of(context).colorScheme.onPrimary, // Ensure icon color matches
          tooltip: icon == Icons.notifications_outlined ? 'Notifications' : (icon == Icons.settings_outlined ? 'Settings' : null),
        ),
        if (badge != null) badge, // Display badge if provided
      ],
    );
  }

  // Helper for Section Headers
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSeedlingItemFromData(dynamic seedling) {
    final theme = Theme.of(context);
    
    // Get expected transplant date
    DateTime? expectedTransplantDate;
    if (seedling['expectedTransplantDate'] != null) {
      expectedTransplantDate = DateTime.tryParse(seedling['expectedTransplantDate']);
    } else if (seedling['calculatedExpectedTransplantDate'] != null) {
      expectedTransplantDate = DateTime.tryParse(seedling['calculatedExpectedTransplantDate']);
    }
    
    String formattedDate = expectedTransplantDate != null 
        ? DateFormat('MMM. d, yyyy').format(expectedTransplantDate)
        : 'Not scheduled';
        
    // Check if expected date is today
    bool isToday = false;
    if (expectedTransplantDate != null) {
      final now = DateTime.now();
      isToday = expectedTransplantDate.year == now.year && 
                expectedTransplantDate.month == now.month && 
                expectedTransplantDate.day == now.day;
    }
        
    return ListTile(
      dense: true, // Make list items less tall
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Icon(Icons.eco, color: theme.colorScheme.primary, size: 20),
      title: Text(
        seedling['batchName'] ?? 'Unknown Batch',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Expected transplant: $formattedDate',
        style: theme.textTheme.bodySmall,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SeedlingsInsightsScreen(),
          ),
        ).then((_) => _refreshHomeScreenData());
      },
      tileColor: isToday ? Colors.green.shade50 : null,
      shape: isToday ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.green.shade300, width: 1),
      ) : null,
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    String status,
    IconData iconData,
    List<FlSpot> chartData,
    Color chartLineColor,
    {double? minYChartValue, double? maxYChartValue}
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor), // Muted title
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: chartLineColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, color: chartLineColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: chartLineColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const Spacer(), // Push chart to bottom
            SizedBox(
              height: 40, // Height for the chart
              child: _buildMiniLineChart(chartData, chartLineColor, minYValue: minYChartValue, maxYValue: maxYChartValue),
            ),
          ],
        ),
      ),
    );
  }

  // --- Mini Line Chart Widget ---
  Widget _buildMiniLineChart(List<FlSpot> spots, Color lineColor, {double? minYValue, double? maxYValue}) {
    if (spots.isEmpty) {
      return const SizedBox.shrink(); // Return an empty widget if there are no spots
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withOpacity(0.3),
                  lineColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minX: spots.first.x,
        maxX: spots.last.x,
        // Adjust Y range slightly for padding, or dynamically based on data
        minY: minYValue ?? spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 1,
        maxY: maxYValue ?? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 1,
        baselineY: 0,
      ),
      duration: const Duration(milliseconds: 150), // Optional animation
    );
  }
  // --- End Mini Line Chart Widget ---

  // --- Restore and Restyle HIDDEN WIDGETS ---

  Widget _buildCalendarWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      calendarFormat: _calendarFormat,
      availableGestures: AvailableGestures.horizontalSwipe,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          // Optionally navigate or show tasks for the selected day
        });
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      calendarStyle: CalendarStyle(
        defaultTextStyle: TextStyle(color: colorScheme.onSurface),
        weekendTextStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        todayDecoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(color: colorScheme.onPrimary),
        outsideTextStyle: TextStyle(color: theme.hintColor.withOpacity(0.5)),
      ),
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false, // Hide format button for cleaner look
        titleTextStyle: theme.textTheme.titleMedium!.copyWith(
            color: colorScheme.primary, fontWeight: FontWeight.bold),
        leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.primary),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: theme.hintColor),
        weekendStyle: TextStyle(color: theme.hintColor.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildMyTaskSection() {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                'My Daily Tasks', Icons.task_alt_outlined, colorScheme.primary),
            const SizedBox(height: 12),

            if (taskProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 40),
                      const SizedBox(height: 8),
                      Text('All tasks are done!',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.green)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.take(3).length, // Show max 3 tasks
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final dueDate = task.dueDate;
                  final now = DateTime.now();
                  final isToday = dueDate.year == now.year &&
                      dueDate.month == now.month &&
                      dueDate.day == now.day;
                  final dateDisplay = isToday
                      ? 'Today, ${_formatDate(dueDate)}'
                      : _formatDate(dueDate);

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      visualDensity: VisualDensity.compact,
                      shape: const CircleBorder(),
                      value: task.isCompleted,
                      activeColor: colorScheme.primary,
                      checkColor: colorScheme.onPrimary,
                      side: BorderSide(color: theme.hintColor),
                      onChanged: (value) {
                        if (value != null) {
                          taskProvider.toggleTaskStatus(
                            context,
                            task.id,
                            value,
                          );
                        }
                      },
                    ),
                    title: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Due: $dateDisplay', // Simpler subtitle
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Add onTap to view task details maybe?
                  );
                },
              ),

            if (tasks.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyTasksScreen(),
                        ),
                      );
                    },
                    child: Text('View All Tasks',
                        style: TextStyle(color: colorScheme.primary)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Example static data for team tasks
    final List<Map<String, dynamic>> teamTasks = [
      {
        'id': 't1',
        'title': 'Daily Seedlings Check: Batch 24 Lettuce',
        'due': 'Today, 4:00 PM',
        'completed': _teamTask1Completed,
      },
      {
        'id': 't2',
        'title': 'Transplant Strong Seedlings: Batch 25 Basil',
        'due': 'Today, 4:00 PM',
        'completed': _teamTask2Completed,
      },
    ];

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                'Team Tasks', Icons.group_outlined, colorScheme.primary),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teamTasks.length,
              itemBuilder: (context, index) {
                final task = teamTasks[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    visualDensity: VisualDensity.compact,
                    shape: const CircleBorder(),
                    value: task['completed'],
                    activeColor: colorScheme.primary,
                    checkColor: colorScheme.onPrimary,
                    side: BorderSide(color: theme.hintColor),
                    onChanged: (value) {
                      setState(() {
                        if (task['id'] == 't1') {
                          _teamTask1Completed = value!;
                        } else if (task['id'] == 't2') {
                          _teamTask2Completed = value!;
                        }
                      });
                    },
                  ),
                  title: Text(
                    task['title'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      decoration:
                          task['completed'] ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Due: ${task['due']}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
            // Add "View All Team Tasks" button if applicable
          ],
        ),
      ),
    );
  }

  // --- Helper methods for calculations (Keep as is) ---
  String _calculateAverageTemperature(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return '25°C';
    double sum = 0;
    for (var seedling in seedlings) {
      sum += seedling['temperature'] ?? 25.0;
    }
    return '${(sum / seedlings.length).toStringAsFixed(1)}°C';
  }

  String _getTemperatureStatus(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 'Normal';
    double sum = 0;
    for (var seedling in seedlings) {
      sum += seedling['temperature'] ?? 25.0;
    }
    double avgTemp = sum / seedlings.length;
    if (avgTemp < 18) return 'Low';
    if (avgTemp > 30) return 'High';
    return 'Normal';
  }

  double _calculateAveragePHLevel(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 6.0;
    double sum = 0;
    for (var seedling in seedlings) {
      sum += seedling['pHLevel'] ?? 6.0;
    }
    return double.parse((sum / seedlings.length).toStringAsFixed(1));
  }

  String _getPHLevelStatus(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 'Normal';
    double avgPH = _calculateAveragePHLevel(seedlings);
    if (avgPH < 5.5) return 'Low';
    if (avgPH > 7.0) return 'High';
    return 'Normal';
  }

  String _getLatestSeedlingAge(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return '0';
    seedlings.sort((a, b) {
      DateTime dateA = DateTime.parse(a['plantedDate']);
      DateTime dateB = DateTime.parse(b['plantedDate']);
      return dateB.compareTo(dateA);
    });
    DateTime plantedDate = DateTime.parse(seedlings.first['plantedDate']);
    int daysSincePlanting = DateTime.now().difference(plantedDate).inDays;
    return daysSincePlanting.toString();
  }

  String _getLatestSeedlingAgeStatus(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 'Normal'; // Default to Normal if no age
    int days = int.tryParse(_getLatestSeedlingAge(seedlings)) ?? 0;
    if (days < 3) return 'Recent';
    if (days > 14) return 'Old'; // Example threshold
    return 'Normal';
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // --- Updated Widget for Transplant Insight Card (showing transplanted batches) ---
  Widget _buildTransplantInsightCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, top: 16, right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransplantCropInsightScreen(),
                  ),
                ).then((_) => _refreshHomeScreenData());
              },
              child: Text(
                'Transplant Insight',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          _isLoadingTransplantInsights
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _transplantedBatchesSummary.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 30.0),
                        child: Text(
                          'No transplanted batches available',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: _transplantedBatchesSummary
                          .take(4) // Show only first 4 transplanted batches
                          .map(
                            (batch) => _buildTransplantItemFromData(batch),
                          )
                          .toList(),
                    ),
        ],
      ),
    );
  }

  // New helper method to build transplant list items, similar to seedling items
  Widget _buildTransplantItemFromData(dynamic transplantBatch) {
    final theme = Theme.of(context);
    
    // Get expected harvest date
    DateTime? expectedHarvestDate;
    if (transplantBatch['transplantDetails'] != null && 
        transplantBatch['transplantDetails']['expectedHarvestDate'] != null) {
      expectedHarvestDate = DateTime.tryParse(transplantBatch['transplantDetails']['expectedHarvestDate']);
    }
    
    String formattedDate = expectedHarvestDate != null 
        ? DateFormat('MMM. d, yyyy').format(expectedHarvestDate)
        : 'Not scheduled';
    
    // Check if expected date is today
    bool isToday = false;
    if (expectedHarvestDate != null) {
      final now = DateTime.now();
      isToday = expectedHarvestDate.year == now.year && 
                expectedHarvestDate.month == now.month && 
                expectedHarvestDate.day == now.day;
    }
    
    return ListTile(
      dense: true, // Make list items less tall
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Icon(Icons.eco, color: theme.colorScheme.primary, size: 20),
      title: Text(
        transplantBatch['batchName'] ?? 'Unknown Batch',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Expected harvest: $formattedDate',
        style: theme.textTheme.bodySmall,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TransplantCropInsightScreen(),
          ),
        ).then((_) => _refreshHomeScreenData());
      },
      tileColor: isToday ? Colors.green.shade50 : null,
      shape: isToday ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.green.shade300, width: 1),
      ) : null,
    );
  }
  // --- End Transplant Insight Card Widget ---
}
