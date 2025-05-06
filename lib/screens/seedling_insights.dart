import 'package:flutter/material.dart';
import 'home.dart';
import 'notification_page.dart';
import 'batch_details_screen.dart';
import 'package:intl/intl.dart';
import '../services/seedling_service.dart';
import '../providers/seedling_provider.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import 'transplant_crop_insight.dart';

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

  // State for ToggleButtons
  int _selectedScreenIndex = 0; // 0 for Seedlings, 1 for Transplant
  List<bool> _isSelected = [true, false];

  @override
  void initState() {
    super.initState();
    _loadSeedlings();

    _searchController.addListener(() {
      _filterSeedlings();
    });
  }

  void _filterSeedlings() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSeedlings = _seedlings.where((seedling) {
        return seedling['batchName'].toLowerCase().contains(query) ||
            seedling['plantType'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadSeedlings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to get all seedlings first
      final response = await SeedlingService.getAllSeedlingsRaw();
      final seedlings = response as List<dynamic>;

      if (seedlings.isEmpty) {
        // If no seedlings exist, try to get sample seedlings
        final samplesResponse = await SeedlingService.getSampleSeedlingsRaw();
        final samples = samplesResponse as List<dynamic>;
        setState(() {
          _seedlings = samples;
          _filteredSeedlings = samples;
          _isLoading = false;
        });
      } else {
        setState(() {
          _seedlings = seedlings;
          _filteredSeedlings = seedlings;
          _isLoading = false;
        });
      }

      // Update the provider if available
      if (context.mounted) {
        final seedlingProvider =
            Provider.of<SeedlingProvider>(context, listen: false);
        seedlingProvider.updateSeedlings(_seedlings);
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
          'Seedlings Insight',
          style: textTheme.headlineSmall?.copyWith(
            color: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary,
          ),
        ),
        centerTitle: true, // Center title for a modern look
        actions: [
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
        onRefresh: _loadSeedlings,
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
                            'Error loading seedlings',
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
                            onPressed: _loadSeedlings,
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
                                  _isSelected = [
                                    _selectedScreenIndex == 0,
                                    _selectedScreenIndex == 1
                                  ];
                                });
                                if (index == 1) {
                                  // Navigate to Transplant Screen
                                  Navigator.pushReplacement(
                                    context, // Use pushReplacement to avoid stacking
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TransplantCropInsightScreen(),
                                    ),
                                  );
                                }
                                // No action needed if index is 0 (already here)
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
                            // Style automatically applied by theme
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add New Batch'),
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
                                      'No seedlings found',
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
                                  final seedling = _filteredSeedlings[index];
                                  return _buildSeedlingCard(context, seedling);
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
    final TextEditingController plantTypeController = TextEditingController(); // Keep, rename label later
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

    DateTime selectedDate = DateTime.now();
    // Add state for expected transplant date, default 14 days from planting date
    DateTime selectedExpectedTransplantDate = selectedDate.add(const Duration(days: 14));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make sheet background transparent
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          // Local loading state
          bool isLoading = false;
          
          // Function to handle form submission
          Future<void> _submitForm() async {
            // Validation
            final int? quantity = int.tryParse(quantityController.text);
            if (batchCodeController.text.isEmpty ||
                plantTypeController.text.isEmpty ||
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
            setState(() {
              isLoading = true;
            });

            try {
              // Create seedling data to send to API
              final seedlingData = {
                'batchCode': batchCodeController.text,
                'plantType': plantTypeController.text,
                'plantedDate': selectedDate.toIso8601String(),
                'quantity': quantity,
                'expectedTransplantDate': selectedExpectedTransplantDate.toIso8601String(),
              };

              // Make API call
              await SeedlingService.createSeedlingRaw(seedlingData);
              
              // If successful, close the modal
              if (context.mounted) {
                Navigator.of(context).pop();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added Successfully!',
                        style: TextStyle(color: colorScheme.inversePrimary)),
                    backgroundColor: theme.primaryColor,
                    duration: const Duration(seconds: 2),
                  ),
                );
                
                // Reload seedlings
                _loadSeedlings();
              }
            } catch (e) {
              // Hide loading indicator on error
              setState(() {
                isLoading = false;
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
                              "Add New Batch",
                              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDialogTextField(context, 'Batch Code *', batchCodeController),
                          _buildDialogTextField(context, 'Plant Name *', plantTypeController),
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
                                setState(() {
                                  selectedDate = picked;
                                  selectedExpectedTransplantDate = picked.add(const Duration(days: 14));
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 15),
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
                                setState(() {
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
                              onPressed: isLoading ? null : _submitForm, // Disable when loading
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
                  if (isLoading)
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
  Widget _buildSeedlingCard(BuildContext context, Map<String, dynamic> seedling) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final String batchCode = seedling['batchName'] ?? 'N/A';
    final String plantName = seedling['plantType'] ?? 'N/A';
    final String id = seedling['_id'] ?? '';
    DateTime? plantedDate = seedling['plantedDate'] != null
        ? DateTime.tryParse(seedling['plantedDate'])
        : null;
    final String formattedPlantedDate =
        plantedDate != null ? DateFormat('MMM d, yyyy').format(plantedDate) : 'N/A';

    // Placeholder data - Replace with actual data when available
    final int quantity = seedling['quantity'] ?? 100; // Example placeholder
    final String expectedTransplantDate = plantedDate != null
        ? DateFormat('MMM d, yyyy').format(plantedDate.add(const Duration(days: 21))) // Example: 21 days after planting
        : 'N/A';

    return Card(
      // Use theme card settings
      // elevation: theme.cardTheme.elevation,
      // shape: theme.cardTheme.shape,
      // color: theme.cardTheme.color,
      margin: const EdgeInsets.only(bottom: 16.0), // Spacing between cards
      child: InkWell(
        onTap: () {
          if (id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BatchDetailsScreen(seedlingId: id),
              ),
            ).then((_) => _loadSeedlings()); // Reload data after returning
          }
        },
        // Ensure borderRadius is of type BorderRadius?
        borderRadius: (theme.cardTheme.shape is RoundedRectangleBorder && (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius is BorderRadius)
          ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius as BorderRadius
          : BorderRadius.circular(8.0), // Fallback if shape is not RoundedRect or borderRadius is not BorderRadius
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Batch: $batchCode',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  // Optional: Add an icon like a chevron for navigation indication
                  Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 8),
              Text('Plant: $plantName', style: textTheme.bodyLarge),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(context, Icons.calendar_today, 'Planted: $formattedPlantedDate'),
                  _buildInfoChip(context, Icons.numbers, 'Qty: $quantity'), // Placeholder
                ],
              ),
              const SizedBox(height: 8),
               _buildInfoChip(context, Icons.schedule, 'Transplant: $expectedTransplantDate'), // Placeholder
              const SizedBox(height: 16), // Add spacing before the button

              // Transplant Button - Use FilledButton.tonalIcon for more visibility
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    _showTransplantDialog(context, seedling);
                  },
                  icon: Icon(Icons.outbox_rounded, size: 18), // Adjusted size slightly
                  label: const Text('Transplant Seedling'),
                  // style: FilledButton.styleFrom( // Theme should handle most styling
                  //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  // ),
                ),
                // child: TextButton.icon(
                //   onPressed: () {
                //     // Call the dialog function
                //     _showTransplantDialog(context, seedling);
                //   },
                //   icon: Icon(Icons.outbox_rounded, color: colorScheme.primary, size: 20), // Example icon
                //   label: Text(
                //     'Transplant Seedling',
                //     style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                //   ),
                //   style: TextButton.styleFrom(
                //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                //     // Add a subtle border or background if needed
                //     // shape: RoundedRectangleBorder(
                //     //   side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                //     //   borderRadius: BorderRadius.circular(8),
                //     // )
                //   ),
                // ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for consistent info display (like chips)
  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // --- Dialog for Transplanting Seedling --- 
  void _showTransplantDialog(BuildContext context, Map<String, dynamic> seedling) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final String seedlingId = seedling['_id'] ?? '';
    final String batchCode = seedling['batchName'] ?? 'N/A';
    // TODO: Get current quantity if available from seedling data
    final int currentQuantity = seedling['quantity'] ?? 100; 

    final TextEditingController quantityController = TextEditingController(text: currentQuantity.toString());
    final TextEditingController locationController = TextEditingController();
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
          bool isLoading = false;
          
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
            
            if (locationController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please enter the target location/system.', 
                      style: TextStyle(color: colorScheme.onError)),
                  backgroundColor: colorScheme.error,
                ),
              );
              return;
            }
            
            // Show loading state
            setStateDialog(() {
              isLoading = true;
            });
            
            try {
              // Prepare transplant data
              final transplantData = {
                'transplantDate': selectedTransplantDate.toIso8601String(),
                'quantityTransplanted': quantity,
                'targetLocation': locationController.text,
                'notes': notesController.text,
                'expectedHarvestDate': selectedHarvestDate.toIso8601String(),
              };
              
              print('Transplanting Seedling ID: $seedlingId');
              print('Data: $transplantData');
              
              // TODO: Replace with actual API call
              // await SeedlingService.transplantSeedling(seedlingId, transplantData);
              await Future.delayed(const Duration(seconds: 1)); // Simulate network call
              
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
                _loadSeedlings();
              }
            } catch (e) {
              // Hide loading indicator on error
              setStateDialog(() {
                isLoading = false;
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
                          _buildDialogTextField(context, 'Quantity Transplanted *', quantityController, keyboardType: TextInputType.number),
                          const SizedBox(height: 12),

                          // Target Location/System
                          _buildDialogTextField(context, 'Target Location/System *', locationController),
                          const SizedBox(height: 12),

                          // Notes
                          _buildDialogTextField(context, 'Notes', notesController, maxLines: 3),
                          const SizedBox(height: 25),

                          Center(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submitTransplantForm, // Disable when loading
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
                  if (isLoading)
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
