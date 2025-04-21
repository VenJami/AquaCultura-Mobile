import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transplant_provider.dart';
import 'transplant_details_screen.dart';

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
      Provider.of<TransplantProvider>(context, listen: false)
          .loadTransplants(context);
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
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.transplants.isEmpty) {
            return const Center(child: Text('No transplants found'));
          }

          final successfulTransplants = provider.transplants
              .where((transplant) => transplant['status'] == 'Success')
              .toList();

          final failedTransplants = provider.transplants
              .where((transplant) => transplant['status'] == 'Failed')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  title: 'Transplant Summary',
                  totalCount: provider.transplants.length,
                  successCount: successfulTransplants.length,
                  failedCount: failedTransplants.length,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recent Transplants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.transplants.length,
                  itemBuilder: (context, index) {
                    final transplant = provider.transplants[index];
                    return _buildTransplantCard(transplant);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create transplant screen
        },
        child: const Icon(Icons.add),
      ),
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
                  label: 'Success',
                  count: successCount,
                  color: Colors.green,
                ),
                _buildStatItem(
                  label: 'Failed',
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

  Widget _buildTransplantCard(Map<String, dynamic> transplant) {
    final statusColor = transplant['status'] == 'Success'
        ? Colors.green
        : transplant['status'] == 'Failed'
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(transplant['location'] ?? 'No location'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${_formatDate(transplant['date'])}',
            ),
            Text(
              'Status: ${transplant['status']}',
              style: TextStyle(color: statusColor),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransplantDetailsScreen(
                transplantId: transplant['_id'],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
