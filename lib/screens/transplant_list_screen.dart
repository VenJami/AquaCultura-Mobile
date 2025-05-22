import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transplant_provider.dart';
import 'transplant_crop_insight.dart';
import 'package:intl/intl.dart';
import 'batch_details_screen.dart';

class TransplantListScreen extends StatefulWidget {
  const TransplantListScreen({super.key});

  @override
  State<TransplantListScreen> createState() => _TransplantListScreenState();
}

class _TransplantListScreenState extends State<TransplantListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<TransplantProvider>(context, listen: false)
            .loadTransplantedCropBatches(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transplanted Batches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'View Transplant Insights',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransplantCropInsightScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TransplantProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.transplantedCropBatches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture_outlined, size: 60, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text('No transplanted batches found.', style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Transplant seedling batches from the Seedlings screen.',
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              )
            );
          }

          return RefreshIndicator(
            onRefresh: () => Provider.of<TransplantProvider>(context, listen: false)
                                .loadTransplantedCropBatches(context),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.transplantedCropBatches.length,
              itemBuilder: (context, index) {
                final cropBatch = provider.transplantedCropBatches[index];
                return _buildTransplantedBatchCard(context, cropBatch);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransplantedBatchCard(BuildContext context, Map<String, dynamic> cropBatch) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final String batchName = cropBatch['batchName'] ?? 'N/A';
    final String plantType = cropBatch['plantType'] ?? 'N/A';
    final String id = cropBatch['_id'] ?? '';

    final Map<String, dynamic>? transplantDetails = cropBatch['transplantDetails'] as Map<String, dynamic>?;
    
    DateTime? transplantDate = transplantDetails?['transplantDate'] != null
        ? DateTime.tryParse(transplantDetails!['transplantDate'])
        : null;
    final String formattedTransplantDate =
        transplantDate != null ? DateFormat('MMM d, yyyy').format(transplantDate) : 'N/A';

    final int quantityTransplanted = transplantDetails?['quantityTransplanted'] ?? 0;
    final String targetLocation = transplantDetails?['targetLocation'] ?? 'N/A';
    
    DateTime? expectedHarvestDate = transplantDetails?['expectedHarvestDate'] != null
        ? DateTime.tryParse(transplantDetails!['expectedHarvestDate'])
        : null;
    final String formattedExpectedHarvestDate =
        expectedHarvestDate != null ? DateFormat('MMM d, yyyy').format(expectedHarvestDate) : 'N/A';
    
    final String notes = transplantDetails?['notes'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showDetailsDialog(context, cropBatch);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Batch: $batchName',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 8),
              Text('Plant Type: $plantType', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.calendar_today_outlined, 'Transplanted On:', formattedTransplantDate, context),
              _buildInfoRow(Icons.location_on_outlined, 'Location:', targetLocation, context),
              _buildInfoRow(Icons.inventory_2_outlined, 'Quantity:', quantityTransplanted.toString(), context),
              _buildInfoRow(Icons.event_available_outlined, 'Exp. Harvest:', formattedExpectedHarvestDate, context),
              if (notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildInfoRow(Icons.notes_outlined, 'Notes:', notes, context, isNote: true),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, BuildContext context, {bool isNote = false}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: isNote ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: colorScheme.secondary),
          const SizedBox(width: 8),
          Text('$label ', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: isNote ? textTheme.bodyMedium : textTheme.bodyLarge)),
        ],
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
        transplantDate != null ? DateFormat('MMMM d, yyyy ''at'' HH:mm').format(transplantDate) : 'N/A';
    
    final int quantityTransplanted = transplantDetails?['quantityTransplanted'] ?? 0;
    final String targetLocation = transplantDetails?['targetLocation'] ?? 'N/A';
    DateTime? expectedHarvestDate = transplantDetails?['expectedHarvestDate'] != null
        ? DateTime.tryParse(transplantDetails!['expectedHarvestDate'])
        : null;
    final String formattedExpectedHarvestDate =
        expectedHarvestDate != null ? DateFormat('MMMM d, yyyy').format(expectedHarvestDate) : 'N/A';
    final String notes = transplantDetails?['notes'] ?? 'No notes';

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
              Text('Transplant Information:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Transplanted On: $formattedTransplantDate'),
              Text('Quantity Transplanted: $quantityTransplanted'),
              Text('Target Location: $targetLocation'),
              Text('Expected Harvest: $formattedExpectedHarvestDate'),
              const SizedBox(height: 8),
              Text('Notes:', style: textTheme.titleSmall),
              Text(notes.isNotEmpty ? notes : 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
