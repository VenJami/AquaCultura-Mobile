import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home.dart';
import 'notification_page.dart';
import 'transplant_crop_insights.dart'; // Import the transplant crop insights screen
import '../services/seedling_service.dart';
import '../utils/json_utils.dart';

class BatchDetailsScreen extends StatefulWidget {
  final String seedlingId;

  const BatchDetailsScreen({
    super.key,
    required this.seedlingId,
  });

  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _seedling;

  @override
  void initState() {
    super.initState();
    _loadSeedlingDetails();
  }

  Future<void> _loadSeedlingDetails() async {
    try {
      final seedling =
          await SeedlingService.getSeedlingByIdRaw(widget.seedlingId);
      setState(() {
        _seedling = seedling;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Error loading seedling details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSeedlingDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Format the date values
    final formattedPlantedDate = DateFormat('MMM. d, yyyy').format(
      DateTime.parse(_seedling!['plantedDate']),
    );

    // Format the expected transplant date from the server
    final expectedTransplantDate = DateFormat('MMM. d, yyyy').format(
      DateTime.parse(_seedling!['expectedTransplantDate']),
    );

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Batch Code', _seedling!['batchCode']),
            _buildTextField('Batch Name', _seedling!['batchName']),
            _buildTextField('Plant Type', _seedling!['plantType']),
            _buildTextField('Planting Date', formattedPlantedDate),
            _buildTextField('Days Since Planting',
                _seedling!['daysSincePlanting'].toString()),
            _buildTextField('Estimated Height (cm)',
                _seedling!['estimatedHeight'].toString()),
            _buildTextField(
                'Germination Rate', '${_seedling!['germination']}%'),
            _buildTextField('pH Level', _seedling!['pHLevel'].toString()),
            _buildTextField('Health Status', _seedling!['healthStatus']),
            _buildTextField(
                'Temperature (°C)', _seedling!['temperature'].toString()),
            _buildTextField('Expected Transplant Date', expectedTransplantDate),
            _buildTextField(
              'Harvest Quantity',
              '',
              subtitle:
                  "Add the number of seedlings that's ready for transplant",
            ),
            if (_seedling!['notes'] != null && _seedling!['notes'].isNotEmpty)
              _buildTextField('Notes', _seedling!['notes']),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigate to Transplant Crop Insights Screen with new batch details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransplantCropInsightsScreen(
                          newBatches: [
                            {
                              'batchName': _seedling!['batchName'],
                              'plantName': _seedling!['plantType'],
                              'datePlanted': formattedPlantedDate,
                            }
                          ],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to NFT Farm'),
                ),
                ElevatedButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete Batch'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Batch?'),
          content: const Text(
            'Are you sure you want to delete this batch? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _deleteSeedling(context),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSeedling(BuildContext context) async {
    Navigator.of(context).pop(); // Close the dialog

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await SeedlingService.deleteSeedlingRaw(widget.seedlingId);

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate back to seedling insights screen
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Batch deleted successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting batch: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
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
        'Seedlings Insight',
        style: TextStyle(
            color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Image.asset('assets/notif.png', width: 24, height: 24),
          onPressed: () {
            Navigator.pushNamed(context, '/notification_page');
          },
        ),
      ],
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
