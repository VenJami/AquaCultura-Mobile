import 'package:flutter/material.dart';
import 'home.dart';
import 'notification_page.dart';
// import 'batch_details_screen.dart'; // Removed import
import 'package:intl/intl.dart';
import '../services/seedling_service.dart';
import '../providers/seedling_provider.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import 'transplant_crop_insight.dart';
import 'harvested_crop_history_screen.dart';
import '../providers/main_screen_tab_provider.dart'; // Import MainScreenTabProvider

class SeedlingsInsightsScreen extends StatefulWidget {
  const SeedlingsInsightsScreen({super.key});

  @override
  State<SeedlingsInsightsScreen> createState() =>
      _SeedlingsInsightsScreenState();
}

class _SeedlingsInsightsScreenState extends State<SeedlingsInsightsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _seedlings = [];
  List<dynamic> _filteredSeedlings = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool _argumentsProcessed = false; // Flag to ensure arguments are processed only once

  // State for ToggleButtons - now three options
  int _selectedScreenIndex = 0; // 0 for Seedlings, 1 for Transplant, 2 for Harvested
  List<bool> _isSelected = [true, false, false]; // Direct initialization

  @override
  void initState() {
    super.initState();
    _loadSeedlingCropBatches();

    _searchController.addListener(() {
      _filterSeedlingCropBatches();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _processNavigationArguments();
  }

  void _processNavigationArguments() {
    if (!_argumentsProcessed) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        final targetSubScreen = arguments['targetSubScreen'] as String?;
        final actionBatchId = arguments['actionBatchId'] as String?;
        final actionType = arguments['actionType'] as String?;

        // Clear arguments from provider after processing
        Provider.of<MainScreenTabProvider>(context, listen: false).clearNavigationArguments();

        if (targetSubScreen == 'seedlings' && actionBatchId != null && actionType == 'transplant') {
          _argumentsProcessed = true; // Mark as processed
          // Use a post-frame callback to ensure the widget tree is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) { // Check if the widget is still in the tree
              final seedlingProvider = Provider.of<SeedlingProvider>(context, listen: false);
              try {
                final batchData = seedlingProvider.cropBatches.firstWhere(
                  (batch) => batch['_id'] == actionBatchId,
                  orElse: () => null, // Return null if not found
                );
                if (batchData != null) {
                  _showTransplantDialog(context, batchData);
                } else {
                  print('SeedlingsInsightsScreen: Batch with ID $actionBatchId not found for transplant action.');
                }
              } catch (e) {
                 print('SeedlingsInsightsScreen: Error finding batch $actionBatchId: $e');
              }
            }
          });
        }
      }
    }
  }

  void _filterSeedlingCropBatches() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSeedlings = _seedlings.where((batch) {
        return batch['batchName'].toLowerCase().contains(query) ||
            batch['plantType'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadSeedlingCropBatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch crop batches with status 'seedling'
      final response = await SeedlingService.getAllCropBatchesRaw(status: 'seedling');
      final cropBatches = response as List<dynamic>;

      if (cropBatches.isEmpty) {
        // Instead of fetching samples, set seedlings to an empty list
        setState(() {
          _seedlings = [];
          _filteredSeedlings = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _seedlings = cropBatches;
          _filteredSeedlings = cropBatches;
          _isLoading = false;
        });
      }

      if (context.mounted) {
        final seedlingProvider =
            Provider.of<SeedlingProvider>(context, listen: false);
        seedlingProvider.updateCropBatchesList(_seedlings); // This will now correctly reflect an empty list if no batches
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access theme data
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Use theme background color
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Use theme app bar color
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
        elevation: 0,
        title: Text(
          'Seedling Batches',
          style: textTheme.headlineSmall?.copyWith(
            color: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary,
          ),
        ),
        centerTitle: true, // Center title for a modern look
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Seedlings',
            onPressed: () {
              _loadSeedlingCropBatches();
            },
            color: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary, // Ensure icon color matches theme
          ),
          IconButton(
            // Consider using a themed icon if available or tinting asset
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
        onRefresh: _loadSeedlingCropBatches,
        color: colorScheme.primary, // Use theme primary color for indicator
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
            : _errorMessage != null
                ? Center(
                    child: Padding( // Add padding for better spacing
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: colorScheme.error, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading seedling batches',
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
                            onPressed: _loadSeedlingCropBatches,
                            // Button style will be applied by theme
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
                                  _isSelected = List.generate(3, (i) => i == index);
                                });
                                if (index == 1) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TransplantCropInsightScreen(),
                                    ),
                                  );
                                } else if (index == 2) {
                                   Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HarvestedCropHistoryScreen(), // Navigate to Harvested
                                    ),
                                  );
                                }
                                // If index == 0, already on this screen
                              }
                            },
                            borderRadius: BorderRadius.circular(8.0),
                            selectedColor: Colors.white,
                            fillColor: theme.primaryColor,
                            color: theme.primaryColor,
                            constraints: const BoxConstraints(minHeight: 40.0, minWidth: 90.0), // Adjusted minWidth for three buttons
                            children: const <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0), // Adjusted padding
                                child: Text('Seedlings'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0), // Adjusted padding
                                child: Text('Transplanted'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0), // Adjusted padding
                                child: Text('Harvested'), // Added Harvested button
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Search Field - Apply theme
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration( // Will use theme's inputDecorationTheme
                            hintText: 'Search by batch or plant name...',
                            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Add New Batch Button (Fill Width)
                        SizedBox(
                          width: double.infinity, // Make button fill width
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddBatchDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary, // Use theme's primary color
                              foregroundColor: colorScheme.onPrimary, // Use onPrimary for text/icon
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add New Seedling Batch'),
                          ),
                        ),

                        const SizedBox(height: 20), // Spacing before list or empty message

                        _filteredSeedlings.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center, // Center vertically too
                                  children: [
                                     Icon(Icons.eco,
                                        color: theme.primaryColor, size: 48), // Use theme primary color
                                    const SizedBox(height: 16),
                                     Text(
                                      'No seedling batches found',
                                      style: textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                     Text(
                                        'Add a new batch to get started',
                                         style: textTheme.bodyMedium,
                                         textAlign: TextAlign.center,
                                         ),
                                  ],
                                ),
                              )
                            // Replace Table with ListView of Cards
                            : ListView.builder(
                                shrinkWrap: true, // Important inside SingleChildScrollView
                                physics: const NeverScrollableScrollPhysics(), // Disable ListView scrolling
                                itemCount: _filteredSeedlings.length,
                                itemBuilder: (context, index) {
                                  final batch = _filteredSeedlings[index];
                                  return _buildSeedlingCard(context, batch, index);
                                },
                              )
                      ],
                    ),
                  ),
      ),
    );
  }

  void _showAddBatchDialog(BuildContext context) {
    final theme = Theme.of(context); // Access theme for dialog
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final TextEditingController batchCodeController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(); // Add Quantity
    // Remove unused controllers
    // final TextEditingController germinationController = TextEditingController();
    // final TextEditingController pHLevelController = TextEditingController();
    // final TextEditingController notesController = TextEditingController();
    // final TextEditingController growthRateController =
    //     TextEditingController(text: "1.0");
    // final TextEditingController temperatureController =
    //     TextEditingController(text: "25.0");
    // final TextEditingController healthStatusController =
    //     TextEditingController(text: "Healthy");

    // List of available plant types
    final List<String> plantTypes = [
      'Butterhead',
      'Summer Crisp',
      'Romaine Lettuce',
      'Iceberg Lettuce',
      'Red Leaf Lettuce',
      'Leaf Lettuce',
      'Crisphead Lettuce',
    ];
    
    // Default selected plant type
    String selectedPlantType = plantTypes[0]; // Default to first item

    DateTime selectedDate = DateTime.now();
    // Add state for expected transplant date, default 14 days from planting date
    DateTime selectedExpectedTransplantDate = selectedDate.add(const Duration(days: 14));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make sheet background transparent
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setStateModal) {
          // Local loading state
          bool isLoadingDialog = false;
          
          // Function to handle form submission
          Future<void> _submitForm() async {
            // Validation
            final int? quantity = int.tryParse(quantityController.text);
            if (batchCodeController.text.isEmpty ||
                selectedPlantType.isEmpty || // Updated to use selectedPlantType
                quantity == null || quantity <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Batch code, plant name, and a valid quantity are required',
                    style: TextStyle(color: colorScheme.onError),
                  ),
                  backgroundColor: colorScheme.error,
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }

            // Show loading state
            setStateModal(() {
              isLoadingDialog = true;
            });

            try {
              // Create seedling data to send to API
              final cropBatchData = {
                'batchCode': batchCodeController.text,
                'plantType': selectedPlantType, // Updated to use selectedPlantType
                'plantedDate': selectedDate.toIso8601String(),
                'quantity': quantity,
                'expectedTransplantDate': selectedExpectedTransplantDate.toIso8601String(),
              };

              await SeedlingService.createCropBatchRaw(cropBatchData);
              
              // If successful, close the modal
              if (context.mounted) {
                Navigator.of(context).pop();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Batch Added Successfully!',
                        style: TextStyle(color: colorScheme.inversePrimary)),
                    backgroundColor: theme.primaryColor,
                    duration: const Duration(seconds: 2),
                  ),
                );
                
                // Reload seedlings
                _loadSeedlingCropBatches();
              }
            } catch (e) {
              // Hide loading indicator on error
              setStateModal(() {
                isLoadingDialog = false;
              });
              
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}',
                      style: TextStyle(color: colorScheme.onError)),
                  backgroundColor: colorScheme.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
          
          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (_, scrollController) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.dialogBackgroundColor ?? colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              "Add New Seedling Batch",
                              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDialogTextField(context, 'Batch Code *', batchCodeController),
                          
                          // Replace plant type text field with dropdown
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plant Type *', 
                                  style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(
                                      (theme.inputDecorationTheme.border is OutlineInputBorder
                                        ? (theme.inputDecorationTheme.border as OutlineInputBorder).borderRadius.topLeft.x
                                        : 8.0)
                                    ),
                                    border: Border.all(
                                      color: theme.inputDecorationTheme.border?.borderSide.color ?? theme.dividerColor.withOpacity(0.5)
                                    )
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedPlantType,
                                      isExpanded: true,
                                      icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      borderRadius: BorderRadius.circular(8),
                                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                                      dropdownColor: theme.colorScheme.surface,
                                      items: plantTypes.map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setStateModal(() {
                                            selectedPlantType = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          _buildDialogTextField(context, 'Quantity *', quantityController, keyboardType: TextInputType.number),
                          
                          // Planting Date picker
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                            child: Text('Planting Date *',
                                style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: theme.copyWith(
                                      colorScheme: theme.colorScheme.copyWith(
                                        primary: colorScheme.primary, onPrimary: colorScheme.onPrimary, onSurface: colorScheme.onSurface,
                                      ),
                                      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: colorScheme.primary)),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null && picked != selectedDate) {
                                setStateModal(() {
                                  selectedDate = picked;
                                  selectedExpectedTransplantDate = picked.add(const Duration(days: 14));
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                              decoration: BoxDecoration(
                                color: theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(
                                    (theme.inputDecorationTheme.border is OutlineInputBorder
                                      ? (theme.inputDecorationTheme.border as OutlineInputBorder).borderRadius.topLeft.x
                                      : 8.0)
                                ),
                                border: Border.all(color: theme.inputDecorationTheme.border?.borderSide.color ?? theme.dividerColor.withOpacity(0.5))
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMMM d, yyyy').format(selectedDate),
                                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                                  ),
                                  Icon(Icons.calendar_today, color: colorScheme.primary),
                                ],
                              ),
                            ),
                          ),

                          // Expected Transplant Date Picker
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                            child: Text('Expected Transplant Date',
                                style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedExpectedTransplantDate,
                                firstDate: selectedDate.add(const Duration(days: 1)),
                                lastDate: selectedDate.add(const Duration(days: 180)),
                                builder: (context, child) {
                                  return Theme(
                                    data: theme.copyWith(
                                      colorScheme: theme.colorScheme.copyWith(
                                        primary: colorScheme.primary, onPrimary: colorScheme.onPrimary, onSurface: colorScheme.onSurface,
                                      ),
                                      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: colorScheme.primary)),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null && picked != selectedExpectedTransplantDate) {
                                setStateModal(() {
                                  selectedExpectedTransplantDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                              decoration: BoxDecoration(
                                color: theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(
                                    (theme.inputDecorationTheme.border is OutlineInputBorder
                                      ? (theme.inputDecorationTheme.border as OutlineInputBorder).borderRadius.topLeft.x
                                      : 8.0)
                                ),
                                border: Border.all(color: theme.inputDecorationTheme.border?.borderSide.color ?? theme.dividerColor.withOpacity(0.5))
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMMM d, yyyy').format(selectedExpectedTransplantDate),
                                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                                  ),
                                  Icon(Icons.calendar_today, color: colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Center(
                            child: ElevatedButton(
                              onPressed: isLoadingDialog ? null : _submitForm, // Disable when loading
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                child: Text('Add Batch', style: const TextStyle(fontSize: 16)),
                              ),
                            ),
                          ),
                          Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)),
                        ],
                      ),
                    ),
                  ),
                  // Show loading overlay when isLoading is true
                  if (isLoadingDialog)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: CircularProgressIndicator(color: colorScheme.primary),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        });
      },
    );
  }

  // Helper function for gradient colors - now uses theme colors
  List<Color> _getGradientColors(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Create a gradient using primary color variants
    return [
      colorScheme.primary.withOpacity(0.15), // Light shade of primary
      colorScheme.primary.withOpacity(0.35), // Slightly darker shade
    ];
  }

  // Placeholder for card icons - simplified to use a single icon for all crops
  IconData _getCardIcon(String plantType) {
    // Use a single consistent icon for all crop types
    return Icons.eco;
  }

  // Update to accept BuildContext for theme access
  Widget _buildDialogTextField(BuildContext context, String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {

     final theme = Theme.of(context);
     final colorScheme = theme.colorScheme;
     final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Reduced vertical padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)), // Use theme label style
          const SizedBox(height: 6), // Reduced spacing
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            // Use theme's input decoration
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  hintText: 'Enter $label', // Add hint text
                  isDense: true, // Make field slightly denser
            ),
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface), // Use theme text style
          ),
        ],
      ),
    );
  }

  // New method to build seedling card
  Widget _buildSeedlingCard(BuildContext context, Map<String, dynamic> cropBatch, int index) {
    // Log the received cropBatch data for debugging
    print('[SeedlingInsightsScreen] Building card with data: $cropBatch, index: $index');

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final String batchName = cropBatch['batchName'] ?? 'N/A';
    final String plantName = cropBatch['plantType'] ?? 'N/A';
    final String id = cropBatch['_id'] ?? '';
    DateTime? plantedDate = cropBatch['plantedDate'] != null
        ? DateTime.tryParse(cropBatch['plantedDate'])
        : null;
    final String formattedPlantedDate =
        plantedDate != null ? DateFormat('MMM d, \'yy').format(plantedDate) : 'N/A'; // Shorter date

    final int quantity = cropBatch['quantity'] ?? 0;

    DateTime? expectedTransplantDateObj;
    String formattedExpectedTransplantDate = 'N/A';
    if (cropBatch['expectedTransplantDate'] != null) {
      expectedTransplantDateObj = DateTime.tryParse(cropBatch['expectedTransplantDate'].toString());
      if (expectedTransplantDateObj != null) {
        formattedExpectedTransplantDate = DateFormat('MMM d, \'yy').format(expectedTransplantDateObj); // Shorter date
      }
    } else if (cropBatch['calculatedExpectedTransplantDate'] != null) { // Fallback if direct field is null
      expectedTransplantDateObj = DateTime.tryParse(cropBatch['calculatedExpectedTransplantDate'].toString());
      if (expectedTransplantDateObj != null) {
        formattedExpectedTransplantDate = DateFormat('MMM d, \'yy').format(expectedTransplantDateObj);
      }
    }

    bool isDueToday = false;
    if (expectedTransplantDateObj != null) {
      final now = DateTime.now();
      isDueToday = expectedTransplantDateObj.year == now.year &&
                   expectedTransplantDateObj.month == now.month &&
                   expectedTransplantDateObj.day == now.day;
    }

    List<Color> gradientColors = isDueToday 
        ? [
            Colors.green.shade200.withOpacity(0.7), // Lighter green for due today
            Colors.green.shade500.withOpacity(0.8)  // Darker green for due today
          ]
        : _getGradientColors(context);

    IconData cardIcon = _getCardIcon(plantName);

    return GestureDetector(
      onTap: () {
        _showSeedlingInfoModal(context, cropBatch);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1), // Theme-aware shadow
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batchName, // Main title (e.g., "Basic", "Beginner's")
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface, // Theme-aware text color
                        ),
                      ),
                      Text(
                        plantName, // Subtitle (e.g., "Free", "$29/month")
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant, // Theme-aware text color
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.5), // Theme-aware background
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cardIcon, color: colorScheme.primary, size: 28), // Use theme primary color for icon
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCardDetailRow(context, "Planted:", formattedPlantedDate),
            const SizedBox(height: 6),
            _buildCardDetailRow(context, "Quantity:", "$quantity Q's"),
            const SizedBox(height: 6),
            _buildCardDetailRow(context, "Exp. Transplant:", formattedExpectedTransplantDate),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showTransplantDialog(context, cropBatch);
                },
                icon: Icon(Icons.outbox_rounded, size: 18, color: colorScheme.onPrimary), // Use onPrimary for contrast with primary color
                label: Text('Transplant', style: TextStyle(color: colorScheme.onPrimary)), // Use onPrimary for contrast
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary, // Use theme's primary color (green)
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: textTheme.labelMedium,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper for card detail rows in the new design
  Widget _buildCardDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.4), // Theme-aware background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), // Theme-aware text color
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface), // Theme-aware text color
          ),
        ],
      ),
    );
  }

  // --- Modal for Seedling Info & Actions ---
  void _showSeedlingInfoModal(BuildContext context, Map<String, dynamic> cropBatch) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final String batchName = cropBatch['batchName'] ?? 'N/A';
    final String plantName = cropBatch['plantType'] ?? 'N/A';
    final String id = cropBatch['_id'] ?? 'N/A';
    DateTime? plantedDate = cropBatch['plantedDate'] != null
        ? DateTime.tryParse(cropBatch['plantedDate'])
        : null;
    final String formattedPlantedDateFull = plantedDate != null 
        ? DateFormat('MMMM d, yyyy \'at\' HH:mm').format(plantedDate)
        : 'N/A';
    final int quantity = cropBatch['quantity'] ?? 0;
    
    String formattedExpectedTransplantDateFull = 'N/A';
    if (cropBatch['expectedTransplantDate'] != null) {
      DateTime? etd = DateTime.tryParse(cropBatch['expectedTransplantDate'].toString());
      if (etd != null) {
        formattedExpectedTransplantDateFull = DateFormat('MMMM d, yyyy').format(etd);
      }
    } else if (cropBatch['calculatedExpectedTransplantDate'] != null) { 
      DateTime? cetd = DateTime.tryParse(cropBatch['calculatedExpectedTransplantDate'].toString());
      if (cetd != null) {
        formattedExpectedTransplantDateFull = DateFormat('MMMM d, yyyy').format(cetd);
      }
    }

    // Placeholder for creator info - adapt if you have this data in cropBatch
    String createdBy = 'N/A';
    if (cropBatch['createdBy'] != null) {
      if (cropBatch['createdBy'] is Map && cropBatch['createdBy']['name'] != null) {
        createdBy = cropBatch['createdBy']['name'];
      } else {
        createdBy = cropBatch['createdBy'].toString(); // Fallback to ID if name not found or not a map
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Batch Details: $batchName', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildModalInfoRow(textTheme, 'Plant Type:', plantName),
                _buildModalInfoRow(textTheme, 'Batch ID:', id),
                _buildModalInfoRow(textTheme, 'Created By:', createdBy), // Display createdBy
                _buildModalInfoRow(textTheme, 'Planted On:', formattedPlantedDateFull),
                _buildModalInfoRow(textTheme, 'Quantity:', quantity.toString()),
                _buildModalInfoRow(textTheme, 'Expected Transplant:', formattedExpectedTransplantDateFull),
                // Add more details here if needed
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Request Deletion', style: TextStyle(color: colorScheme.error)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the info dialog
                // Placeholder action for deletion request
                print('Deletion requested for batch ID: $id');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deletion requested for $batchName.'),
                    backgroundColor: colorScheme.secondaryContainer,
                    duration: const Duration(seconds: 2),
                  ),
                );
                // Here you would typically call a service or provider method
                // e.g., Provider.of<SeedlingProvider>(context, listen: false).requestDeletion(id);
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper for modal info rows
  Widget _buildModalInfoRow(TextTheme textTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodyLarge?.copyWith(color: textTheme.bodyMedium?.color), // Default text style
          children: <TextSpan>[
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // --- Dialog for Transplanting Seedling --- 
  void _showTransplantDialog(BuildContext context, Map<String, dynamic> cropBatch) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final String cropBatchId = cropBatch['_id'] ?? '';
    final String batchCode = cropBatch['batchName'] ?? 'N/A';
    final int currentQuantity = cropBatch['quantity'] ?? 100;

    final TextEditingController quantityController = TextEditingController(text: currentQuantity.toString());
    final TextEditingController notesController = TextEditingController();
    DateTime selectedTransplantDate = DateTime.now();
    // Initialize expected harvest date, 30 days after transplant date
    DateTime selectedHarvestDate = selectedTransplantDate.add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          // Local loading state
          bool isLoadingDialog = false;
          
          // Function to handle transplant form submission
          Future<void> _submitTransplantForm() async {
            // Validation
            final int? quantity = int.tryParse(quantityController.text);
            if (quantity == null || quantity <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please enter a valid quantity.', 
                      style: TextStyle(color: colorScheme.onError)),
                  backgroundColor: colorScheme.error,
                ),
              );
              return;
            }
            
            if (quantity > currentQuantity) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transplant quantity cannot exceed current batch quantity ($currentQuantity).', 
                      style: TextStyle(color: colorScheme.onError)),
                  backgroundColor: colorScheme.error,
                ),
              );
              return;
            }
            
            // Show loading state
            setStateDialog(() {
              isLoadingDialog = true;
            });
            
            try {
              // Prepare transplant data
              final transplantData = {
                'transplantDate': selectedTransplantDate.toIso8601String(),
                'quantityTransplanted': quantity,
                'notes': notesController.text,
                'expectedHarvestDate': selectedHarvestDate.toIso8601String(),
              };
              
              print('Transplanting Crop Batch ID: $cropBatchId');
              print('Data: $transplantData');
              
              await SeedlingService.transplantCropBatchRaw(cropBatchId, transplantData);
              
              // If successful, close the modal and refresh
              if (context.mounted) {
                Navigator.of(context).pop();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Batch $batchCode transplanted successfully!',
                        style: TextStyle(color: colorScheme.inversePrimary)),
                    backgroundColor: theme.primaryColor,
                    duration: const Duration(seconds: 3),
                  ),
                );
                
                // Reload seedlings
                _loadSeedlingCropBatches();
              }
            } catch (e) {
              // Hide loading indicator on error
              setStateDialog(() {
                isLoadingDialog = false;
              });
              
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error transplanting: ${e.toString()}',
                      style: TextStyle(color: colorScheme.onError)),
                  backgroundColor: colorScheme.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
          
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (_, scrollController) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.dialogBackgroundColor ?? colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40, height: 5, margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          Center(
                            child: Text(
                              "Transplant Batch: $batchCode",
                              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Transplant Date Picker
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                            child: Text('Transplant Date *', style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedTransplantDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                                builder: (context, child) {
                                  return Theme(
                                    data: theme.copyWith(
                                      colorScheme: theme.colorScheme.copyWith(
                                        primary: colorScheme.primary, onPrimary: colorScheme.onPrimary, onSurface: colorScheme.onSurface,
                                      ),
                                      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: colorScheme.primary)),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null && picked != selectedTransplantDate) {
                                setStateDialog(() {
                                  selectedTransplantDate = picked;
                                  selectedHarvestDate = picked.add(const Duration(days: 30));
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                              decoration: BoxDecoration(
                                color: theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(
                                    (theme.inputDecorationTheme.border is OutlineInputBorder
                                      ? (theme.inputDecorationTheme.border as OutlineInputBorder).borderRadius.topLeft.x
                                      : 8.0)
                                  ),
                                  border: Border.all(color: theme.inputDecorationTheme.border?.borderSide.color ?? theme.dividerColor.withOpacity(0.5))
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMMM d, yyyy').format(selectedTransplantDate),
                                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                                  ),
                                  Icon(Icons.calendar_today, color: colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Expected Harvest Date Picker
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                            child: Text('Expected Harvest Date *', style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedHarvestDate,
                                firstDate: selectedTransplantDate.add(const Duration(days: 7)),
                                lastDate: selectedTransplantDate.add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: theme.copyWith(
                                      colorScheme: theme.colorScheme.copyWith(
                                        primary: colorScheme.primary, onPrimary: colorScheme.onPrimary, onSurface: colorScheme.onSurface,
                                      ),
                                      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: colorScheme.primary)),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null && picked != selectedHarvestDate) {
                                setStateDialog(() {
                                  selectedHarvestDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                              decoration: BoxDecoration(
                                color: theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(
                                    (theme.inputDecorationTheme.border is OutlineInputBorder
                                      ? (theme.inputDecorationTheme.border as OutlineInputBorder).borderRadius.topLeft.x
                                      : 8.0)
                                  ),
                                  border: Border.all(color: theme.inputDecorationTheme.border?.borderSide.color ?? theme.dividerColor.withOpacity(0.5))
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMMM d, yyyy').format(selectedHarvestDate),
                                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                                  ),
                                  Icon(Icons.calendar_today, color: colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Quantity Transplanted
                          _buildDialogTextField(context, 'Quantity Transplanted (Max: $currentQuantity) *', quantityController, keyboardType: TextInputType.number),
                          const SizedBox(height: 12),

                          // Notes
                          _buildDialogTextField(context, 'Notes', notesController, maxLines: 3),
                          const SizedBox(height: 25),

                          Center(
                            child: ElevatedButton(
                              onPressed: isLoadingDialog ? null : _submitTransplantForm, // Disable when loading
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                child: Text('Confirm Transplant', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ),
                          Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)),
                        ],
                      ),
                    ),
                  ),
                  // Show loading overlay when isLoading is true
                  if (isLoadingDialog)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: CircularProgressIndicator(color: colorScheme.primary),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        });
      },
    );
  }
}

