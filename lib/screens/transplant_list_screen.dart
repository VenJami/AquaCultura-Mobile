import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transplant_provider.dart';
import 'transplant_insights.dart';

class TransplantListScreen extends StatefulWidget {
  const TransplantListScreen({super.key});

  @override
  State<TransplantListScreen> createState() => _TransplantListScreenState();
}

class _TransplantListScreenState extends State<TransplantListScreen> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Provider.of<TransplantProvider>(context, listen: false)
        .loadTransplants(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transplants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransplantInsightsScreen(),
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

          if (provider.transplants.isEmpty) {
            return const Center(child: Text('No transplants found'));
          }

          return ListView.builder(
            itemCount: provider.transplants.length,
            itemBuilder: (context, index) {
              final transplant = provider.transplants[index];
              return ListTile(
                title: Text(transplant.name),
                subtitle: Text(transplant.type),
                trailing: Text(transplant.status),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(transplant.name),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: ${transplant.type}'),
                          Text('Status: ${transplant.status}'),
                          Text(
                            'Date: ${transplant.date.toString().split(' ')[0]}',
                          ),
                          Text('Success Rate: ${transplant.successRate}%'),
                          Text('Notes: ${transplant.notes}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Create New Transplant'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  TextField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await Provider.of<TransplantProvider>(context,
                              listen: false)
                          .createTransplant(
                        context,
                        {
                          'name': _nameController.text,
                          'type': _typeController.text,
                          'date': DateTime.now().toIso8601String(),
                          'successRate': 0.0,
                          'status': 'pending',
                          'notes': '',
                        },
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        _nameController.clear();
                        _typeController.clear();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to create transplant'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
