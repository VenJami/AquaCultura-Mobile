import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For TransplantProvider
import '../providers/transplant_provider.dart'; // Import TransplantProvider
import '../config/theme.dart';
import 'notification_page.dart';
import 'seedling_insights.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'harvested_crop_history_screen.dart'; // Corrected import
import '../services/seedling_service.dart'; // Added import for SeedlingService
import '../providers/main_screen_tab_provider.dart'; // Import MainScreenTabProvider
// import 'batch_details_screen.dart'; // Potentially for navigation from card

class TransplantCropInsightScreen extends StatefulWidget {
  const TransplantCropInsightScreen({super.key});

  @override
  State<TransplantCropInsightScreen> createState() =>
      _TransplantCropInsightScreenState();
}

class _TransplantCropInsightScreenState
    extends State<TransplantCropInsightScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Data will come from TransplantProvider
  // List<dynamic> _transplantedCrops = []; 
  // List<dynamic> _filteredTransplantedCrops = [];
  bool _argumentsProcessed = false; // Flag to ensure arguments are processed only once

  // State for ToggleButtons - now three options
  int _selectedScreenIndex = 1; // 0 for Seedlings, 1 for Transplant, 2 for Harvested
  List<bool> _isSelected = [false, true, false]; // Direct initialization

  @override
  void initState() {
    super.initState();
    // _isSelected = [_selectedScreenIndex == 0, _selectedScreenIndex == 1, _selectedScreenIndex == 2]; // REMOVED
    // Load data using the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<TransplantProvider>(context, listen: false)
            .loadTransplantedCropBatches(context);
      }
    });

    _searchController.addListener(() {
      // Filtering will be applied directly to the provider's list in the build method
      // or by having the provider handle filtering internally if complex.
      // For simplicity, we can filter a copy of the provider's list here for the UI.
      setState(() {}); // Trigger rebuild to apply filter
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

        if (targetSubScreen == 'transplants' && actionBatchId != null && actionType == 'harvest') {
          _argumentsProcessed = true; // Mark as processed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final transplantProvider = Provider.of<TransplantProvider>(context, listen: false);
              try {
                final batchData = transplantProvider.transplantedCropBatches.firstWhere(
                  (batch) => batch['_id'] == actionBatchId,
                  orElse: () => null,
                );
                if (batchData != null) {
                  _showHarvestDialog(context, batchData); // Call the new harvest dialog
                } else {
                  print('TransplantCropInsightScreen: Batch with ID $actionBatchId not found for harvest action.');
                }
              } catch (e) {
                print('TransplantCropInsightScreen: Error finding batch $actionBatchId: $e');
              }
            }
          });
        }
      }
    }
  }

  List<dynamic> _getFilteredBatches(TransplantProvider provider) {
    if (_searchController.text.isEmpty) {
      return provider.transplantedCropBatches;
    }
    final query = _searchController.text.toLowerCase();
    return provider.transplantedCropBatches.where((batch) {
      final batchName = batch['batchName']?.toString().toLowerCase() ?? '';
      final plantType = batch['plantType']?.toString().toLowerCase() ?? '';
      return batchName.contains(query) || plantType.contains(query);
    }).toList();
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
        title: Text(
          'Transplanted Batches', // Updated title
          style: textTheme.headlineSmall?.copyWith(
            color: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Transplanted Batches',
            onPressed: () {
              Provider.of<TransplantProvider>(context, listen: false)
                  .loadTransplantedCropBatches(context);
            },
            color: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary, // Ensure icon color matches theme
          ),
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
      body: Consumer<TransplantProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => Provider.of<TransplantProvider>(context, listen: false)
                .loadTransplantedCropBatches(context),
            color: colorScheme.primary,
            child: provider.isLoading && provider.transplantedCropBatches.isEmpty // Show loading only if list is empty initially
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                // Error handling can be enhanced in the provider or here
                // For now, relying on SnackBar shown by provider on error.
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ToggleButtons(
                            isSelected: _isSelected,
                            onPressed: (int index) {
                              if (_selectedScreenIndex != index) {
                                setState(() {
                                  _selectedScreenIndex = index;
                                  _isSelected = List.generate(3, (i) => i == index);
                                });
                                if (index == 0) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SeedlingsInsightsScreen(),
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
                                // If index == 1, already on this screen
                              }
                            },
                            borderRadius: BorderRadius.circular(8.0),
                            selectedColor: Colors.white,
                            fillColor: theme.primaryColor,
                            color: theme.primaryColor,
                            constraints: const BoxConstraints(minHeight: 40.0, minWidth: 90.0), // Adjusted minWidth
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
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search transplanted batches...', // Updated hint
                            prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTransplantedList(provider, context), // Use new method
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTransplantedList(TransplantProvider provider, BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final filteredBatches = _getFilteredBatches(provider);

    if (provider.isLoading && filteredBatches.isEmpty) {
        // Covered by the main consumer's loading indicator if list is empty
        // If you want a specific loading indicator here while list is non-empty and refreshing, add it.
    }

    if (!provider.isLoading && filteredBatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.spa_outlined, size: 60, color: Theme.of(context).disabledColor),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty 
                    ? 'No transplanted batches found.' 
                    : 'No batches match your search.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (_searchController.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Batches will appear here once they are transplanted from the seedlings screen.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredBatches.length,
      itemBuilder: (context, index) {
        final cropBatch = filteredBatches[index];
        return _buildTransplantedBatchCard(context, cropBatch, index);
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

  // Helper for card detail rows (copied and adapted from SeedlingsInsightsScreen)
  Widget _buildCardDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 4), // Add some margin between rows
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  // Copied from transplant_list_screen.dart (and adapted slightly)
  Widget _buildTransplantedBatchCard(BuildContext context, Map<String, dynamic> cropBatch, int index) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final String batchName = cropBatch['batchName'] ?? 'N/A';
    final String plantType = cropBatch['plantType'] ?? 'N/A';
    // final String id = cropBatch['_id'] ?? ''; // Not used for onTap here, but good to have if needed

    final Map<String, dynamic>? transplantDetails = cropBatch['transplantDetails'] as Map<String, dynamic>?;
    
    DateTime? transplantDate = transplantDetails?['transplantDate'] != null
        ? DateTime.tryParse(transplantDetails!['transplantDate'])
        : null;
    final String formattedTransplantDate =
        transplantDate != null ? DateFormat('MMM d, \'yy').format(transplantDate) : 'N/A'; // Shorter date

    final int quantityTransplanted = transplantDetails?['quantityTransplanted'] ?? 0;
    final String targetLocation = transplantDetails?['targetLocation'] ?? 'N/A'; // Though not displayed, kept for context
    
    DateTime? expectedHarvestDateObj;
    String formattedExpectedHarvestDate = 'N/A';
    if (transplantDetails?['expectedHarvestDate'] != null) {
        expectedHarvestDateObj = DateTime.tryParse(transplantDetails!['expectedHarvestDate']);
        if (expectedHarvestDateObj != null) {
            formattedExpectedHarvestDate = DateFormat('MMM d, \'yy').format(expectedHarvestDateObj);
        }
    }

    bool isDueToday = false;
    if (expectedHarvestDateObj != null) {
      final now = DateTime.now();
      isDueToday = expectedHarvestDateObj.year == now.year &&
                   expectedHarvestDateObj.month == now.month &&
                   expectedHarvestDateObj.day == now.day;
    }

    List<Color> gradientColors = isDueToday 
        ? [
            Colors.green.shade200.withOpacity(0.7), // Lighter green for due today
            Colors.green.shade500.withOpacity(0.8)  // Darker green for due today
          ]
        : _getGradientColors(context);

    IconData cardIcon = _getCardIcon(plantType);

    return GestureDetector(
      onTap: () {
        _showDetailsDialog(context, cropBatch);
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
              color: colorScheme.shadow.withOpacity(0.1),
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
                        batchName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        plantType,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cardIcon, color: colorScheme.primary, size: 28), // Use theme primary color for icon
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCardDetailRow(context, "Transplanted On:", formattedTransplantDate),
            _buildCardDetailRow(context, "Quantity:", "$quantityTransplanted Q's"),
            _buildCardDetailRow(context, "Exp. Harvest:", formattedExpectedHarvestDate),
            const SizedBox(height: 16), // Spacing before button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showHarvestDialog(context, cropBatch);
                },
                icon: Icon(Icons.agriculture_outlined, size: 18, color: colorScheme.onPrimary),
                label: Text('Harvest', style: TextStyle(color: colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: textTheme.labelMedium,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            )
            // No button here for now, as primary action is viewing details via onTap
            // If a button is needed later, it can be added similarly to SeedlingInsightsScreen
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> cropBatch) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final String batchName = cropBatch['batchName'] ?? 'N/A';
    final String plantType = cropBatch['plantType'] ?? 'N/A';
    final String status = cropBatch['status'] ?? 'N/A';

    final Map<String, dynamic>? transplantDetails = cropBatch['transplantDetails'] as Map<String, dynamic>?;
    DateTime? transplantDate = transplantDetails?['transplantDate'] != null
        ? DateTime.tryParse(transplantDetails!['transplantDate'])
        : null;
    final String formattedTransplantDate =
        transplantDate != null ? DateFormat('MMMM d, yyyy \'at\' HH:mm').format(transplantDate) : 'N/A';
    
    final int quantityTransplanted = transplantDetails?['quantityTransplanted'] ?? 0;
    final String targetLocation = transplantDetails?['targetLocation'] ?? 'N/A';
    DateTime? expectedHarvestDate = transplantDetails?['expectedHarvestDate'] != null
        ? DateTime.tryParse(transplantDetails!['expectedHarvestDate'])
        : null;
    final String formattedExpectedHarvestDate =
        expectedHarvestDate != null ? DateFormat('MMMM d, yyyy').format(expectedHarvestDate) : 'N/A';
    final String notes = transplantDetails?['notes'] ?? 'No notes provided.';

    // New fields for who processed steps
    String createdBy = 'N/A';
    if (cropBatch['createdBy'] != null) {
      if (cropBatch['createdBy'] is Map && cropBatch['createdBy']['name'] != null) {
        createdBy = cropBatch['createdBy']['name'];
      } else {
        createdBy = cropBatch['createdBy'].toString();
      }
    }

    String transferredBy = 'N/A';
    if (cropBatch['transferredBy'] != null) {
      if (cropBatch['transferredBy'] is Map && cropBatch['transferredBy']['name'] != null) {
        transferredBy = cropBatch['transferredBy']['name'];
      } else {
        transferredBy = cropBatch['transferredBy'].toString();
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batch Details: $batchName', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plant Type: $plantType', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Status: ${status[0].toUpperCase()}${status.substring(1)}', style: textTheme.titleMedium?.copyWith(color: colorScheme.secondary)),
              const Divider(height: 20),
              Text('Processing Information:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              _buildInfoRow(context, Icons.person_outline, 'Created By:', createdBy),
              const Divider(height: 20),
              Text('Transplant Information:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              _buildInfoRow(context, Icons.person_pin_circle_outlined, 'Transferred By:', transferredBy),
              _buildInfoRow(context, Icons.calendar_today_outlined, 'Transplanted On:', formattedTransplantDate),
              _buildInfoRow(context, Icons.inventory_2_outlined, 'Quantity:', quantityTransplanted.toString()),
              _buildInfoRow(context, Icons.event_available_outlined, 'Expected Harvest:', formattedExpectedHarvestDate),
              const SizedBox(height: 8),
              Text('Notes:', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(notes.isNotEmpty ? notes : 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          // Potentially add an 'Edit' button here to update transplant details
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
      ],
    );
  }

  // --- Dialog for Harvesting Crop --- 
  void _showHarvestDialog(BuildContext context, Map<String, dynamic> cropBatch) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final String cropBatchId = cropBatch['_id'] ?? '';
    final String batchName = cropBatch['batchName'] ?? 'N/A';
    final int currentQuantity = cropBatch['transplantDetails']?['quantityTransplanted'] ?? cropBatch['quantity'] ?? 0;

    final TextEditingController quantityController = TextEditingController(text: currentQuantity.toString());
    final TextEditingController notesController = TextEditingController();
    DateTime selectedHarvestDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) { // Renamed to dialogContext to avoid conflict
        return StatefulBuilder(builder: (stfContext, setStateDialog) { // Renamed context to stfContext
          bool isLoadingDialog = false;

          Future<void> _submitHarvestForm() async {
            final int? quantityHarvested = int.tryParse(quantityController.text);

            if (quantityHarvested == null || quantityHarvested <= 0) {
              ScaffoldMessenger.of(stfContext).showSnackBar(
                SnackBar(
                  content: Text('Please enter a valid quantity harvested.', style: TextStyle(color: colorScheme.onError)),
                  backgroundColor: colorScheme.error,
                ),
              );
              return;
            }
            if (quantityHarvested > currentQuantity) {
               ScaffoldMessenger.of(stfContext).showSnackBar(
                SnackBar(
                  content: Text('Harvest quantity ($quantityHarvested) cannot exceed available quantity ($currentQuantity).', style: TextStyle(color: colorScheme.onError)),
                  backgroundColor: colorScheme.error,
                ),
              );
              return;
            }

            setStateDialog(() {
              isLoadingDialog = true;
            });

            final harvestData = {
              'harvestDate': selectedHarvestDate.toIso8601String(),
              'quantityHarvested': quantityHarvested,
              'notes': notesController.text,
            };

            print('Attempting to harvest Crop Batch ID: $cropBatchId with data: $harvestData');

            try {
              await SeedlingService.harvestCropBatchRaw(cropBatchId, harvestData);
              
              // Pop dialog first
              if (Navigator.of(stfContext).canPop()) {
                 Navigator.of(stfContext).pop();
              }

              ScaffoldMessenger.of(context).showSnackBar( // Use original screen context for SnackBar
                SnackBar(
                  content: Text('Batch $batchName harvest recorded successfully!'), // Updated message
                  backgroundColor: theme.primaryColor,
                ),
              );
              // Refresh transplant list
              Provider.of<TransplantProvider>(context, listen: false).loadTransplantedCropBatches(context);
            } catch (e) {
              ScaffoldMessenger.of(stfContext).showSnackBar(
                SnackBar(content: Text('Error harvesting: ${e.toString()}', style: TextStyle(color: colorScheme.onError)), backgroundColor: colorScheme.error),
              );
            } finally {
              if(mounted) {
              setStateDialog(() { isLoadingDialog = false; });
            }
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
                              "Harvest Batch: $batchName",
                              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Harvest Date Picker
                          _buildDatePickerField(
                            context: stfContext, // Use StatefulBuilder context for dialog elements
                            label: 'Harvest Date *',
                            selectedDate: selectedHarvestDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 90)), // Allow some past dates
                            lastDate: DateTime.now().add(const Duration(days: 30)), // Allow some future dates
                            onDateChanged: (pickedDate) {
                              setStateDialog(() {
                                selectedHarvestDate = pickedDate;
                              });
                            },
                            colorScheme: colorScheme, // Pass colorScheme
                            textTheme: textTheme // Pass textTheme
                          ),
                          const SizedBox(height: 12),
                          _buildGeneralDialogTextField(stfContext, 'Quantity Harvested (Max: $currentQuantity) *', quantityController, keyboardType: TextInputType.number, colorScheme: colorScheme, textTheme: textTheme),
                          const SizedBox(height: 12),
                          _buildGeneralDialogTextField(stfContext, 'Notes', notesController, maxLines: 3, colorScheme: colorScheme, textTheme: textTheme),
                          const SizedBox(height: 25),
                          Center(
                            child: ElevatedButton(
                              onPressed: isLoadingDialog ? null : _submitHarvestForm,
                              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                child: Text('Confirm Harvest', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ),
                          Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(stfContext).viewInsets.bottom)),
                        ],
                      ),
                    ),
                  ),
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

  // Helper for date picker field (can be made common or kept local if specific styles)
  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime selectedDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onDateChanged,
    required ColorScheme colorScheme, // Added
    required TextTheme textTheme,   // Added
  }) {
    // final theme = Theme.of(context); // Already available via passed colorScheme/textTheme
    // final textTheme = theme.textTheme;
    // final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: firstDate,
              lastDate: lastDate,
               builder: (pickerContext, child) { // Renamed context to pickerContext
                  return Theme(
                    data: Theme.of(pickerContext).copyWith(
                      colorScheme: colorScheme.copyWith(
                        primary: colorScheme.primary, 
                        onPrimary: colorScheme.onPrimary,
                        onSurface: colorScheme.onSurface,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                      ),
                    ),
                    child: child!,
                  );
                },
            );
            if (picked != null && picked != selectedDate) {
              onDateChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(
                  (Theme.of(context).inputDecorationTheme.border is OutlineInputBorder
                    ? (Theme.of(context).inputDecorationTheme.border as OutlineInputBorder).borderRadius.topLeft.x
                    : 8.0)
                ),
                border: Border.all(color: Theme.of(context).inputDecorationTheme.border?.borderSide.color ?? Theme.of(context).dividerColor.withOpacity(0.5))
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
      ],
    );
  }

  Widget _buildGeneralDialogTextField(BuildContext context, String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text, required ColorScheme colorScheme, required TextTheme textTheme}) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  hintText: 'Enter $label',
                  isDense: true,
                  // Accessing theme for border styles, fill color etc.
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? colorScheme.surfaceVariant.withOpacity(0.3),
                  border: Theme.of(context).inputDecorationTheme.border ?? OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)))
            ),
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
} 