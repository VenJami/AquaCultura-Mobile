import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/seedling_provider.dart';
import 'seedling_insights_screen.dart';

class SeedlingListScreen extends StatefulWidget {
  const SeedlingListScreen({super.key});

  @override
  State<SeedlingListScreen> createState() => _SeedlingListScreenState();
}

class _SeedlingListScreenState extends State<SeedlingListScreen> {
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
        title: const Text('Seedlings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SeedlingInsightsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SeedlingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.seedlings.isEmpty) {
            return const Center(child: Text('No seedlings found'));
          }

          return ListView.builder(
            itemCount: provider.seedlings.length,
            itemBuilder: (context, index) {
              final seedling = provider.seedlings[index];
              return ListTile(
                title: Text(seedling.name),
                subtitle: Text(seedling.type),
                trailing: Text(seedling.status),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(seedling.name),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: ${seedling.type}'),
                          Text('Status: ${seedling.status}'),
                          Text(
                            'Planting Date: ${seedling.plantingDate.toString().split(' ')[0]}',
                          ),
                          Text('Growth Rate: ${seedling.growthRate}%'),
                          Text('Notes: ${seedling.notes}'),
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
              title: const Text('Create New Seedling'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  TextField(
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
                      await Provider.of<SeedlingProvider>(context,
                              listen: false)
                          .createSeedling(
                        context,
                        name: 'New Seedling',
                        type: 'Type',
                        status: 'healthy',
                        notes: '',
                        plantingDate: DateTime.now(),
                        growthRate: 0.0,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to create seedling'),
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
