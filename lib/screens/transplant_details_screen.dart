import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transplant_provider.dart';
import '../services/transplant_service.dart';

class TransplantDetailsScreen extends StatefulWidget {
  final String transplantId;

  const TransplantDetailsScreen({
    super.key,
    required this.transplantId,
  });

  @override
  State<TransplantDetailsScreen> createState() =>
      _TransplantDetailsScreenState();
}

class _TransplantDetailsScreenState extends State<TransplantDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _transplant;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransplantDetails();
  }

  Future<void> _loadTransplantDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final transplant =
          await TransplantService.getTransplantByIdRaw(widget.transplantId);

      setState(() {
        _transplant = transplant;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transplant Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading transplant details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTransplantDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildTransplantDetails(),
    );
  }

  Widget _buildTransplantDetails() {
    if (_transplant == null) {
      return const Center(child: Text('No transplant details found'));
    }

    final statusColor = _transplant!['status'] == 'Success'
        ? Colors.green
        : _transplant!['status'] == 'Failed'
            ? Colors.red
            : Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          _transplant!['status'] ?? 'Unknown',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow(
                      'Location', _transplant!['location'] ?? 'Not specified'),
                  _buildInfoRow(
                    'Date',
                    _formatDate(_transplant!['date']),
                  ),
                  if (_transplant!['seedlingId'] != null)
                    _buildInfoRow('Seedling ID', _transplant!['seedlingId']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notes, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(_transplant!['notes'] ?? 'No notes available'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transplant'),
        content: const Text(
          'Are you sure you want to delete this transplant record? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTransplant();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransplant() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await Provider.of<TransplantProvider>(context, listen: false)
          .deleteTransplant(context, widget.transplantId);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
}
