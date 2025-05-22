import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transplant_provider.dart';
import 'transplant_details_screen.dart';
import 'package:intl/intl.dart'; // For date formatting

class TransplantInsightsScreen extends StatefulWidget {
  const TransplantInsightsScreen({super.key});

  @override
  State<TransplantInsightsScreen> createState() =>
      _TransplantInsightsScreenState();
}

class _TransplantInsightsScreenState extends State<TransplantInsightsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Use the updated method from TransplantProvider
      Provider.of<TransplantProvider>(context, listen: false)
          .loadTransplantedCropBatches(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transplant Insights'),
      ),
      body: Consumer<TransplantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.transplantedCropBatches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.transplantedCropBatches.isEmpty) {
            return const Center(child: Text('No transplanted batches found to show insights.'));
          }

          // Current CropBatch model doesn't have a success/fail status for the transplant action itself.
          // So, success/failed counts will be 0 for now.
          final successfulTransplantsCount = 0; 
          final failedTransplantsCount = 0;

          return RefreshIndicator(
            onRefresh: () => Provider.of<TransplantProvider>(context, listen: false)
                .loadTransplantedCropBatches(context),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(
                    title: 'Transplanted Batches Summary',
                    totalCount: provider.transplantedCropBatches.length,
                    // These will be 0 until model supports success/failure of transplant event
                    successCount: successfulTransplantsCount, 
                    failedCount: failedTransplantsCount,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All Transplanted Batches', // Changed title
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.transplantedCropBatches.length,
                    itemBuilder: (context, index) {
                      final cropBatch = provider.transplantedCropBatches[index];
                      return _buildTransplantCard(cropBatch);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // FAB removed as direct creation of 'transplant' records is not the flow anymore
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Navigate to create transplant screen
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int totalCount,
    required int successCount,
    required int failedCount,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: 'Total',
                  count: totalCount,
                  color: Colors.blue,
                ),
                _buildStatItem(
                  label: 'Success', // Placeholder
                  count: successCount,
                  color: Colors.green,
                ),
                _buildStatItem(
                  label: 'Failed', // Placeholder
                  count: failedCount,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildTransplantCard(Map<String, dynamic> cropBatch) { // Parameter changed
    // Adapt to CropBatch structure
    final String batchName = cropBatch['batchName'] ?? 'Batch N/A';
    final String plantType = cropBatch['plantType'] ?? 'Plant N/A';
    final Map<String, dynamic>? details = cropBatch['transplantDetails'] as Map<String, dynamic>?;
    final String location = details?['targetLocation'] ?? 'Location N/A';
    final String transplantDateStr = details?['transplantDate'] ?? '';
    
    // For status, it will always be 'transplanted' if it's from TransplantProvider
    // If you want to show a sub-status of the transplant action (e.g. health after transplant), model needs change.
    // For now, we don't have a specific success/failure status for the transplant event itself.
    const statusColor = Colors.orange; // Default for 'transplanted' general status

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text('$batchName ($plantType)'), // Combined for clarity
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location: $location',
            ),
            Text(
              'Transplanted: ${_formatDate(transplantDateStr)}',
            ),
            // Text(
            //   'Status: Transplanted', // Example, replace with actual status if available
            //   style: TextStyle(color: statusColor),
            // ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransplantDetailsScreen(
                transplantId: cropBatch['_id'], // Pass the CropBatch ID
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
