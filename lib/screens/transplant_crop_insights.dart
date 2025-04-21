import 'package:flutter/material.dart';
import 'transplant_insights.dart';
import 'notification_page.dart';

class TransplantCropInsightsScreen extends StatefulWidget {
  final List<Map<String, String>> newBatches;

  const TransplantCropInsightsScreen({super.key, this.newBatches = const []});

  @override
  _TransplantCropInsightsScreenState createState() =>
      _TransplantCropInsightsScreenState();
}

class _TransplantCropInsightsScreenState
    extends State<TransplantCropInsightsScreen> {
  List<Map<String, String>> transplantBatches = [
    {
      'batchName': 'Batch A1',
      'plantName': 'Romaine Lettuce',
      'datePlanted': 'Feb. 13, 2025',
      'expectedHarvestDate': 'April 13, 2025'
    },
    {
      'batchName': 'Batch A2',
      'plantName': 'Green Leaf Lettuce',
      'datePlanted': 'Feb. 13, 2025',
      'expectedHarvestDate': 'April 13, 2025'
    },
    {
      'batchName': 'Batch A3',
      'plantName': 'Red Leaf Lettuce',
      'datePlanted': 'Feb. 13, 2025',
      'expectedHarvestDate': 'April 13, 2025'
    },
    {
      'batchName': 'Batch A4',
      'plantName': 'Butterhead Lettuce',
      'datePlanted': 'Feb. 13, 2025',
      'expectedHarvestDate': 'April 13, 2025'
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.newBatches.isNotEmpty) {
      transplantBatches.addAll(widget.newBatches);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/home.png', width: 24, height: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/notif.png', width: 24, height: 24),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transplant Crop Insight',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const SizedBox(height: 20),
            Table(
              border: TableBorder.all(color: Colors.black54),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                _buildTableRow('Batch', 'Plant Name', 'Date', isHeader: true),
                for (var batch in transplantBatches)
                  _buildClickableTableRow(context, batch),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String col1, String col2, String col3,
      {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.blue[100] : Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(col1,
              style: TextStyle(
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(col2,
              style: TextStyle(
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(col3,
              style: TextStyle(
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
      ],
    );
  }

  TableRow _buildClickableTableRow(
      BuildContext context, Map<String, String> batch) {
    return TableRow(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransplantDetailsScreen(
                  batchName: batch['batchName']!,
                  plantName: batch['plantName']!,
                  datePlanted: batch['datePlanted']!,
                  expectedTransplantDate:
                      batch['datePlanted']!, // Now correctly passed
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(9.0),
            child: Text(batch['batchName']!,
                style: const TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(batch['plantName']!),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(batch['datePlanted']!),
        ),
      ],
    );
  }
}
