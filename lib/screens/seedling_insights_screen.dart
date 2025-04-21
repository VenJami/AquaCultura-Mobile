import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/seedling_provider.dart';

class SeedlingInsightsScreen extends StatefulWidget {
  const SeedlingInsightsScreen({super.key});

  @override
  State<SeedlingInsightsScreen> createState() => _SeedlingInsightsScreenState();
}

class _SeedlingInsightsScreenState extends State<SeedlingInsightsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<SeedlingProvider>(context, listen: false)
        .loadSeedlings(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seedling Insights'),
      ),
      body: Consumer<SeedlingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.seedlings.isEmpty) {
            return const Center(child: Text('No seedlings data available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(provider),
                const SizedBox(height: 24),
                _buildGrowthChart(provider),
                const SizedBox(height: 24),
                _buildSuccessRateChart(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(SeedlingProvider provider) {
    final totalSeedlings = provider.seedlings.length;
    final healthySeedlings =
        provider.seedlings.where((s) => s.status == 'healthy').length;
    final successRate =
        (healthySeedlings / totalSeedlings * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Seedlings',
                  totalSeedlings.toString(),
                  Icons.eco,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Healthy Seedlings',
                  healthySeedlings.toString(),
                  Icons.favorite,
                  Colors.red,
                ),
                _buildSummaryItem(
                  'Success Rate',
                  '$successRate%',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildGrowthChart(SeedlingProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Growth Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: provider.seedlings
                          .asMap()
                          .entries
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value.growthRate))
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateChart(SeedlingProvider provider) {
    final Map<String, int> statusCount = {};
    for (final seedling in provider.seedlings) {
      statusCount[seedling.status] = (statusCount[seedling.status] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: statusCount.entries.map((entry) {
                    final color = _getStatusColor(entry.key);
                    final percentage =
                        entry.value / provider.seedlings.length * 100;
                    return PieChartSectionData(
                      color: color,
                      value: percentage,
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: statusCount.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(entry.key),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'unhealthy':
        return Colors.red;
      case 'growing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
