import 'package:flutter/material.dart';
import 'home.dart';
import 'notification_page.dart';

class TransplantDetailsScreen extends StatelessWidget {
  final String batchName;
  final String plantName;
  final String datePlanted;
  final String expectedTransplantDate;

  const TransplantDetailsScreen({
    super.key,
    required this.batchName,
    required this.plantName,
    required this.datePlanted,
    required this.expectedTransplantDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/home.png', width: 24, height: 24),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
        title: const Text(
          'Transplant Crop Insights',
          style: TextStyle(
              color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
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
            _buildTextField('Batch Code', batchName),
            _buildTextField('Quantity', '100'),
            _buildTextField('Batch Plant Name', plantName),
            _buildTextField('Transplant Date', 'Mar 13 2025'),
            _buildTextField('Expected Harvest Date', 'Apr 13 2025'),
            _buildTextField(
              'Harvest Quantity',
              '',
              subtitle: 'Add the number of seedlings that is ready for Harvest',
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                      context); // This will go back to Transplant Crop Insights
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value, {String subtitle = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
          TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
              hintText: value,
            ),
            readOnly: true,
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
