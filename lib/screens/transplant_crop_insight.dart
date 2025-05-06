import 'package:flutter/material.dart';
import '../config/theme.dart'; // Import your theme
import 'notification_page.dart'; // If needed for actions
import 'seedling_insights.dart'; // Import for navigation back

class TransplantCropInsightScreen extends StatefulWidget {
  const TransplantCropInsightScreen({super.key});

  @override
  State<TransplantCropInsightScreen> createState() =>
      _TransplantCropInsightScreenState();
}

class _TransplantCropInsightScreenState
    extends State<TransplantCropInsightScreen> {
  final TextEditingController _searchController = TextEditingController();
  // TODO: Add state variables for transplanted crops data, loading, error handling
  bool _isLoading = false; // Example
  String? _errorMessage; // Example
  List<dynamic> _transplantedCrops = []; // Example
  List<dynamic> _filteredTransplantedCrops = []; // Example

  // State for ToggleButtons
  int _selectedScreenIndex = 1; // 0 for Seedlings, 1 for Transplant
  List<bool> _isSelected = [false, true];

  @override
  void initState() {
    super.initState();
    // TODO: Load initial transplanted crop data
    _searchController.addListener(() {
      _filterTransplantedCrops();
    });
  }

  // TODO: Implement filtering logic
  void _filterTransplantedCrops() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // _filteredTransplantedCrops = _transplantedCrops.where((crop) {
      //   // return crop['batchName'].toLowerCase().contains(query) ||
      //   //     crop['plantType'].toLowerCase().contains(query);
      // }).toList();
    });
  }

  // TODO: Implement data loading logic
  Future<void> _loadTransplantedCrops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    // Placeholder for API call or data fetching
    await Future.delayed(const Duration(seconds: 1)); // Simulate loading
    setState(() {
      // _transplantedCrops = fetchedData;
      // _filteredTransplantedCrops = fetchedData;
      _isLoading = false;
    });
    // Handle errors appropriately
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
        elevation: 0,
        // Navigator will handle back arrow automatically
        title: Text(
          'Transplant Crop Insight',
          style: textTheme.headlineSmall?.copyWith(
            color: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Image.asset('assets/notif.png',
                width: 24,
                height: 24,
                color: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransplantedCrops,
        color: colorScheme.primary,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading data', // Generic error message
                            style: textTheme.titleLarge?.copyWith(color: colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadTransplantedCrops,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle Buttons for Screen Navigation
                        Center(
                          child: ToggleButtons(
                            isSelected: _isSelected,
                            onPressed: (int index) {
                              if (_selectedScreenIndex != index) {
                                setState(() {
                                  _selectedScreenIndex = index;
                                  _isSelected = [
                                    _selectedScreenIndex == 0,
                                    _selectedScreenIndex == 1
                                  ];
                                });
                                if (index == 0) {
                                  // Navigate back to Seedlings Screen
                                  Navigator.pushReplacement(
                                    context, // Use pushReplacement to avoid stacking
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SeedlingsInsightsScreen(),
                                    ),
                                  );
                                }
                                // No action needed if index is 1 (already here)
                              }
                            },
                            borderRadius: BorderRadius.circular(8.0),
                            selectedColor: Colors.white,
                            fillColor: theme.primaryColor, // Use theme color for selected
                            color: theme.primaryColor, // Use theme color for unselected
                            constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
                            children: const <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text('Seedlings'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text('Transplant'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Search Field
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search transplanted crops...',
                            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // TODO: Replace with ListView/Cards for transplanted crops
                        _filteredTransplantedCrops.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 40), // Add some top margin
                                    Icon(Icons.grass, color: theme.primaryColor, size: 48),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No transplanted crops found',
                                      style: textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Transplant a batch to see data here.',
                                      style: textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredTransplantedCrops.length,
                                itemBuilder: (context, index) {
                                  // final crop = _filteredTransplantedCrops[index];
                                  // return _buildTransplantedCropCard(context, crop); // TODO: Create card builder
                                  return Text('Item $index'); // Placeholder
                                },
                              ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // TODO: Add a _buildTransplantedCropCard method similar to _buildSeedlingCard
  // Widget _buildTransplantedCropCard(BuildContext context, Map<String, dynamic> crop) {
  //   // ... implementation ...
  // }
} 