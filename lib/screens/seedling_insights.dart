import 'package:flutter/material.dart';
import 'home.dart';
import 'notification_page.dart';
import 'batch_details_screen.dart';
import 'package:intl/intl.dart';
import '../services/seedling_service.dart';
import '../providers/seedling_provider.dart';
import 'package:provider/provider.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: RefreshIndicator(
        onRefresh: _loadSeedlings,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading seedlings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSeedlings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Seedlings Insight',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        const SizedBox(height: 16),

                        // 🔍 Search Field
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by batch or plant name...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        _filteredSeedlings.isEmpty
                            ? Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.eco,
                                        color: Colors.green, size: 48),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No seedlings found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                        'Add a new batch to get started'),
                                  ],
                                ),
                              )
                            : Table(
                                border: TableBorder.all(color: Colors.black54),
                                columnWidths: const {
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(2),
                                },
                                children: [
                                  _buildTableRow('Batch', 'Plant Name', 'Date',
                                      isHeader: true),
                                  ..._filteredSeedlings.map(
                                    (seedling) => _buildClickableTableRow(
                                      context,
                                      seedling['batchName'],
                                      seedling['plantType'],
                                      DateFormat('MMM. d, yyyy').format(
                                        DateTime.parse(seedling['plantedDate']),
                                      ),
                                      seedling['_id'],
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _showAddBatchDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Add New Batch'),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  void _showAddBatchDialog(BuildContext context) {
    final TextEditingController batchCodeController = TextEditingController();
    final TextEditingController plantTypeController = TextEditingController();
    final TextEditingController germinationController = TextEditingController();
    final TextEditingController pHLevelController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final TextEditingController growthRateController =
        TextEditingController(text: "1.0");
    final TextEditingController temperatureController =
        TextEditingController(text: "25.0");
    final TextEditingController healthStatusController =
        TextEditingController(text: "Healthy");

    // Default planting date to today
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0B689A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "Add New Batch",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildDialogTextField('Batch Code', batchCodeController),
                      _buildDialogTextField('Plant Type', plantTypeController),
                      _buildDialogTextField(
                          'Germination (%)', germinationController,
                          keyboardType: TextInputType.number),
                      _buildDialogTextField('pH Level', pHLevelController,
                          keyboardType: TextInputType.number),
                      _buildDialogTextField(
                          'Growth Rate (cm/day)', growthRateController,
                          keyboardType: TextInputType.number),
                      _buildDialogTextField(
                          'Temperature (°C)', temperatureController,
                          keyboardType: TextInputType.number),
                      _buildDialogTextField(
                          'Health Status', healthStatusController),

                      // Date picker
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Planting Date',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM. d, yyyy').format(selectedDate),
                                style: TextStyle(color: Colors.white),
                              ),
                              Icon(Icons.calendar_today, color: Colors.white),
                            ],
                          ),
                        ),
                      ),

                      _buildDialogTextField('Notes', notesController,
                          maxLines: 3),

                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Validate inputs
                            if (batchCodeController.text.isEmpty ||
                                plantTypeController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Batch code and plant type are required',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            );

                            try {
                              // Create seedling data to send to API
                              final seedlingData = {
                                'batchCode': batchCodeController.text,
                                'plantType': plantTypeController.text,
                                'plantedDate': selectedDate.toIso8601String(),
                                'germination':
                                    int.tryParse(germinationController.text) ??
                                        0,
                                'pHLevel':
                                    double.tryParse(pHLevelController.text) ??
                                        6.0,
                                'notes': notesController.text,
                                'growthRate': double.tryParse(
                                        growthRateController.text) ??
                                    1.0,
                                'temperature': double.tryParse(
                                        temperatureController.text) ??
                                    25.0,
                                'healthStatus':
                                    healthStatusController.text.isNotEmpty
                                        ? healthStatusController.text
                                        : 'Healthy',
                              };

                              // Make API call
                              await SeedlingService.createSeedlingRaw(
                                  seedlingData);

                              // Close loading dialog
                              Navigator.of(context).pop();

                              // Close the form dialog
                              Navigator.of(context).pop();

                              // Reload seedlings
                              await _loadSeedlings();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added Successfully!',
                                      style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              // Close loading dialog
                              Navigator.of(context).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}',
                                      style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 10),
                            child: Text('Add', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
      },
    );
  }

  Widget _buildDialogTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white24,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            ),
            style: TextStyle(color: Colors.white),
          ),
        ],
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

  TableRow _buildClickableTableRow(BuildContext context, String batchCode,
      String plantName, String datePlanted, String id) {
    return TableRow(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BatchDetailsScreen(
                  seedlingId: id,
                ),
              ),
            ).then((_) => _loadSeedlings());
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.transparent,
            child: Center(child: Text(batchCode)),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BatchDetailsScreen(
                  seedlingId: id,
                ),
              ),
            ).then((_) => _loadSeedlings());
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.transparent,
            child: Center(child: Text(plantName)),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BatchDetailsScreen(
                  seedlingId: id,
                ),
              ),
            ).then((_) => _loadSeedlings());
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.transparent,
            child: Center(child: Text(datePlanted)),
          ),
        ),
      ],
    );
  }
}
