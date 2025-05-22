import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Will be needed if we add a provider later
// import '../providers/harvested_crop_provider.dart'; // Placeholder
import '../config/theme.dart'; // Assuming you have this for theming
import 'notification_page.dart'; // If you have a notification icon
import 'seedling_insights.dart';
import 'transplant_crop_insight.dart';
// import 'package:intl/intl.dart'; // If date formatting is needed directly
import '../services/seedling_service.dart'; // For fetching data

class HarvestedCropHistoryScreen extends StatefulWidget {
  const HarvestedCropHistoryScreen({super.key});

  @override
  State<HarvestedCropHistoryScreen> createState() =>
      _HarvestedCropHistoryScreenState();
}

class _HarvestedCropHistoryScreenState
    extends State<HarvestedCropHistoryScreen> {
  final TextEditingController _searchController = TextEditingController(); // Added search controller
  List<dynamic> _harvestedBatches = [];
  List<dynamic> _filteredHarvestedBatches = [];
  bool _isLoading = true;
  String? _errorMessage;

  // State for ToggleButtons - now three options
  int _selectedScreenIndex = 2; // 0 for Seedlings, 1 for Transplant, 2 for Harvested
  List<bool> _isSelected = [false, false, true]; // Direct initialization based on _selectedScreenIndex for this screen

  @override
  void initState() {
    super.initState();
    _loadHarvestedBatches();
    _searchController.addListener(_filterBatches);
    // TODO: Load harvested crop batches data here
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) {
    //     Provider.of<HarvestedCropProvider>(context, listen: false)
    //         .loadHarvestedCropBatches(context);
    //   }
    // });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHarvestedBatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await SeedlingService.getAllCropBatchesRaw(status: 'harvested');
      // Sort by harvestDate descending if available, otherwise createdAt or updatedAt
      data.sort((a, b) {
        DateTime? dateA, dateB;
        if (a['harvestDetails'] != null && a['harvestDetails']['harvestDate'] != null) {
          dateA = DateTime.tryParse(a['harvestDetails']['harvestDate']);
        }
        if (b['harvestDetails'] != null && b['harvestDetails']['harvestDate'] != null) {
          dateB = DateTime.tryParse(b['harvestDetails']['harvestDate']);
        }
        dateA ??= DateTime.tryParse(a['updatedAt'] ?? a['createdAt'] ?? '');
        dateB ??= DateTime.tryParse(b['updatedAt'] ?? b['createdAt'] ?? '');

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1; // Nulls last
        if (dateB == null) return -1;
        return dateB.compareTo(dateA); // Sort descending (latest first)
      });

      setState(() {
        _harvestedBatches = data;
        _filteredHarvestedBatches = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterBatches() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHarvestedBatches = _harvestedBatches.where((batch) {
        final batchName = batch['batchName']?.toString().toLowerCase() ?? '';
        final plantType = batch['plantType']?.toString().toLowerCase() ?? '';
        return batchName.contains(query) || plantType.contains(query);
      }).toList();
    });
  }

  Future<void> _refreshHarvestedBatches() async {
    await _loadHarvestedBatches();
  }

  // --- Copied Helper Methods ---
  List<Color> _getGradientColors(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Create a gradient using primary color variants
    return [
      colorScheme.primary.withOpacity(0.15), // Light shade of primary
      colorScheme.primary.withOpacity(0.35), // Slightly darker shade
    ];
  }

  IconData _getCardIcon(String plantType) {
    // Use a single consistent icon for all crop types
    return Icons.eco;
  }

  Widget _buildCardDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 4),
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
  // --- End Copied Helper Methods ---

  // --- Card for Harvested Batch ---
  Widget _buildHarvestedBatchCard(BuildContext context, Map<String, dynamic> cropBatch, int index) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final String batchName = cropBatch['batchName'] ?? 'N/A';
    final String plantType = cropBatch['plantType'] ?? 'N/A';
    final String id = cropBatch['_id'] ?? ''; // For potential tap actions

    // Harvest Details
    final Map<String, dynamic>? harvestDetails = cropBatch['harvestDetails'] as Map<String, dynamic>?;
    DateTime? harvestDate = harvestDetails?['harvestDate'] != null
        ? DateTime.tryParse(harvestDetails!['harvestDate'])
        : null;
    final String formattedHarvestDate =
        harvestDate != null ? DateFormat('MMM d, \'yy').format(harvestDate) : 'N/A';
    final int quantityHarvested = harvestDetails?['quantityHarvested'] ?? 0;
    final String harvestNotes = harvestDetails?['notes'] ?? '-';

    // User Info (assuming backend populates these with objects containing a 'name' field)
    String createdBy = 'N/A';
    if (cropBatch['createdBy'] != null) {
      if (cropBatch['createdBy'] is Map && cropBatch['createdBy']['name'] != null) {
        createdBy = cropBatch['createdBy']['name'];
      } else {
        String idStr = cropBatch['createdBy'].toString();
        createdBy = idStr.length > 8 ? '${idStr.substring(0, 8)}...' : idStr; // Show part of ID
      }
    }
    String harvestedBy = 'N/A';
     if (cropBatch['harvestedBy'] != null) {
      if (cropBatch['harvestedBy'] is Map && cropBatch['harvestedBy']['name'] != null) {
        harvestedBy = cropBatch['harvestedBy']['name'];
      } else {
        String idStr = cropBatch['harvestedBy'].toString();
        harvestedBy = idStr.length > 8 ? '${idStr.substring(0, 8)}...' : idStr; // Show part of ID
      }
    }

    List<Color> gradientColors = _getGradientColors(context);
    IconData cardIcon = _getCardIcon(plantType);

    return GestureDetector(
      onTap: () {
        _showHarvestedBatchDetailsDialog(context, cropBatch);
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
                      Text(batchName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface), overflow: TextOverflow.ellipsis),
                      Text(plantType, style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cardIcon, color: colorScheme.primary, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCardDetailRow(context, "Harvested On:", formattedHarvestDate),
            _buildCardDetailRow(context, "Qty Harvested:", "$quantityHarvested units"),
            _buildCardDetailRow(context, "Harvested By:", harvestedBy),
            if (harvestNotes.isNotEmpty && harvestNotes != '-')
              _buildCardDetailRow(context, "Notes:", harvestNotes),
            // _buildCardDetailRow(context, "Created By:", createdBy), // Optional to show original creator
          ],
        ),
      ),
    );
  }

  // --- Dialog for Harvested Batch Details ---
  void _showHarvestedBatchDetailsDialog(BuildContext context, Map<String, dynamic> cropBatch) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // General Info
    final String batchName = cropBatch['batchName'] ?? 'N/A';
    final String plantType = cropBatch['plantType'] ?? 'N/A';
    final String id = cropBatch['_id'] ?? 'N/A';

    // Seedling Stage Info
    DateTime? plantedDate = cropBatch['plantedDate'] != null
        ? DateTime.tryParse(cropBatch['plantedDate'])
        : null;
    final String formattedPlantedDate =
        plantedDate != null ? DateFormat('MMM d, yyyy, HH:mm').format(plantedDate) : 'N/A';
    final int initialQuantity = cropBatch['quantity'] ?? 0;
    String createdBy = 'N/A';
    if (cropBatch['createdBy'] != null) {
      if (cropBatch['createdBy'] is Map && cropBatch['createdBy']['name'] != null) {
        createdBy = cropBatch['createdBy']['name'];
      } else {
        String idStr = cropBatch['createdBy'].toString();
        createdBy = idStr.length > 8 ? '${idStr.substring(0, 8)}...' : idStr; // Show part of ID
      }
    }
    final String seedlingNotes = cropBatch['notes'] ?? '-'; 

    // Transplant Stage Info
    final Map<String, dynamic>? td = cropBatch['transplantDetails'] as Map<String, dynamic>?;
    DateTime? transplantDate = td?['transplantDate'] != null ? DateTime.tryParse(td!['transplantDate']) : null;
    final String formattedTransplantDate = transplantDate != null ? DateFormat('MMM d, yyyy, HH:mm').format(transplantDate) : 'N/A';
    final int qtyTransplanted = td?['quantityTransplanted'] ?? 0;
    String transferredBy = 'N/A';
    if (cropBatch['transferredBy'] != null) {
      if (cropBatch['transferredBy'] is Map && cropBatch['transferredBy']['name'] != null) {
        transferredBy = cropBatch['transferredBy']['name'];
      } else {
        String idStr = cropBatch['transferredBy'].toString();
        transferredBy = idStr.length > 8 ? '${idStr.substring(0, 8)}...' : idStr;
      }
    }
    final String transplantNotes = td?['notes'] ?? '-';

    // Harvest Stage Info
    final Map<String, dynamic>? hd = cropBatch['harvestDetails'] as Map<String, dynamic>?;
    DateTime? harvestDate = hd?['harvestDate'] != null ? DateTime.tryParse(hd!['harvestDate']) : null;
    final String formattedHarvestDate = harvestDate != null ? DateFormat('MMM d, yyyy, HH:mm').format(harvestDate) : 'N/A';
    final int qtyHarvested = hd?['quantityHarvested'] ?? 0;
    String harvestedBy = 'N/A';
    if (cropBatch['harvestedBy'] != null) {
      if (cropBatch['harvestedBy'] is Map && cropBatch['harvestedBy']['name'] != null) {
        harvestedBy = cropBatch['harvestedBy']['name'];
      } else {
        String idStr = cropBatch['harvestedBy'].toString();
        harvestedBy = idStr.length > 8 ? '${idStr.substring(0, 8)}...' : idStr;
      }
    }
    final String harvestNotes = hd?['notes'] ?? '-';

    Widget _buildDetailItem(String label, String value, {IconData? icon, bool isNote = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          crossAxisAlignment: isNote ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: colorScheme.primary, size: 18),
            if (icon != null) const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                  children: [
                    TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: value.isEmpty || value == '-' ? 'N/A' : value),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Full History: $batchName', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailItem('Plant Type', plantType, icon: Icons.eco_outlined),
                _buildDetailItem('Batch ID', id, icon: Icons.fingerprint),
                const Divider(thickness: 1, height: 20),
                
                Text('Seedling Stage', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                _buildDetailItem('Created By', createdBy, icon: Icons.person_outline),
                _buildDetailItem('Planted On', formattedPlantedDate, icon: Icons.calendar_today_outlined),
                _buildDetailItem('Initial Quantity', '$initialQuantity units', icon: Icons.format_list_numbered),
                if(seedlingNotes.isNotEmpty && seedlingNotes != '-') _buildDetailItem('Seedling Notes', seedlingNotes, icon: Icons.notes_outlined, isNote: true),
                const Divider(thickness: 1, height: 20),

                Text('Transplant Stage', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                _buildDetailItem('Transferred By', transferredBy, icon: Icons.person_pin_circle_outlined),
                _buildDetailItem('Transplanted On', formattedTransplantDate, icon: Icons.calendar_today_outlined),
                _buildDetailItem('Qty Transplanted', '$qtyTransplanted units', icon: Icons.outbox_rounded),
                if(transplantNotes.isNotEmpty && transplantNotes != '-') _buildDetailItem('Transplant Notes', transplantNotes, icon: Icons.notes_outlined, isNote: true),
                const Divider(thickness: 1, height: 20),
                
                Text('Harvest Stage', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                _buildDetailItem('Harvested By', harvestedBy, icon: Icons.person_search_outlined),
                _buildDetailItem('Harvested On', formattedHarvestDate, icon: Icons.calendar_today_outlined),
                _buildDetailItem('Qty Harvested', '$qtyHarvested units', icon: Icons.agriculture_outlined),
                if(harvestNotes.isNotEmpty && harvestNotes != '-') _buildDetailItem('Harvest Notes', harvestNotes, icon: Icons.notes_outlined, isNote: true),
              ],
            ),
          ),
          actions: <Widget>[
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    Widget content;
    if (_isLoading) {
      content = Center(child: CircularProgressIndicator(color: colorScheme.primary));
    } else if (_errorMessage != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Error loading harvested batches', style: textTheme.titleLarge?.copyWith(color: colorScheme.error), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_errorMessage!, style: textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadHarvestedBatches, child: const Text('Retry')),
            ],
          ),
        ),
      );
    } else if (_filteredHarvestedBatches.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_edu_outlined, size: 60, color: theme.disabledColor),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty ? 'No harvested batches yet.' : 'No batches match your search.',
                style: textTheme.headlineSmall, textAlign: TextAlign.center,
              ),
              if (_searchController.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Completed harvests will appear here.', style: textTheme.bodyLarge, textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      );
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredHarvestedBatches.length,
        itemBuilder: (context, index) {
          final batch = _filteredHarvestedBatches[index];
          return _buildHarvestedBatchCard(context, batch, index);
        },
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
        elevation: 0,
        title: Text(
          'Harvested History',
          style: textTheme.headlineSmall?.copyWith(
            color: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Harvested Batches',
            onPressed: _refreshHarvestedBatches,
            color: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary,
          ),
          IconButton(
            icon: Image.asset('assets/notif.png', // Ensure this asset exists
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
        onRefresh: _refreshHarvestedBatches,
        color: colorScheme.primary,
        child: SingleChildScrollView(
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
                      } else if (index == 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TransplantCropInsightScreen(),
                          ),
                        );
                      }
                      // If index == 2, already on this screen
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
                      child: Text('Harvested'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search harvested batches...',
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 20),
              content,
            ],
          ),
        ),
      ),
    );
  }
} 