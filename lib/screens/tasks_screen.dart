import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch tasks from API
      final response = await ApiService.get('/tasks/my-tasks');

      if (response.statusCode == 200) {
        final List<dynamic> tasksData = json.decode(response.body);

        // Process tasks data
        List<Map<String, dynamic>> processedTasks = [];

        for (var task in tasksData) {
          processedTasks.add({
            'id': task['_id'],
            'title': task['title'],
            'description': task['description'] ?? '',
            'dueDate': DateTime.parse(task['dueDate']),
            'status': task['status'],
            'priority': task['priority'],
            'completedAt': task['completedAt'] != null
                ? DateTime.parse(task['completedAt'])
                : null,
          });
        }

        setState(() {
          _tasks = processedTasks;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Handle unauthorized
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tasks. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'RETRY',
            onPressed: () => _fetchTasks(),
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredTasks() {
    if (_selectedFilter == 'All') {
      return _tasks;
    } else {
      return _tasks.where((task) => task['status'] == _selectedFilter).toList();
    }
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    try {
      final response = await ApiService.put(
        '/tasks/$taskId',
        {'status': newStatus},
      );

      if (response.statusCode == 200) {
        setState(() {
          final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
          if (taskIndex != -1) {
            _tasks[taskIndex]['status'] = newStatus;

            // If completed, set completedAt timestamp
            if (newStatus == 'Completed') {
              _tasks[taskIndex]['completedAt'] = DateTime.now();
            } else {
              _tasks[taskIndex]['completedAt'] = null;
            }
          }
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task status updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating task: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task status'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      appBar: CustomAppBar(title: 'My Tasks'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: filteredTasks.isEmpty
                      ? Center(
                          child: Text(
                            'No tasks found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            return _buildTaskCard(filteredTasks[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All'),
          _buildFilterChip('Pending'),
          _buildFilterChip('In Progress'),
          _buildFilterChip('Completed'),
          _buildFilterChip('Overdue'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (bool selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(task['status']).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showTaskDetailsBottomSheet(task);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority and Status
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getPriorityColor(task['priority']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getPriorityColor(task['priority'])
                            .withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      task['priority'],
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPriorityColor(task['priority']),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(task['status']).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      task['status'],
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(task['status']),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Spacer(),

                  // Quick action button
                  if (task['status'] != 'Completed')
                    IconButton(
                      icon: Icon(Icons.check_circle_outline),
                      color: Colors.green,
                      onPressed: () {
                        _updateTaskStatus(task['id'], 'Completed');
                      },
                    ),
                ],
              ),

              SizedBox(height: 12),

              // Title with decoration if completed
              Text(
                task['title'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: task['status'] == 'Completed'
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),

              SizedBox(height: 8),

              // Description
              if (task['description'].isNotEmpty)
                Text(
                  task['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              SizedBox(height: 12),

              // Due date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Due: ${_formatDate(task['dueDate'])}',
                    style: TextStyle(
                      fontSize: 14,
                      color: task['status'] == 'Overdue'
                          ? Colors.red
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetailsBottomSheet(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task['title'],
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getStatusColor(task['status'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(task['status'])
                                  .withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            task['status'],
                            style: TextStyle(
                              fontSize: 14,
                              color: _getStatusColor(task['status']),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Priority and due date
                    Row(
                      children: [
                        Icon(Icons.flag,
                            color: _getPriorityColor(task['priority'])),
                        SizedBox(width: 8),
                        Text(
                          '${task['priority']} Priority',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 24),
                        Icon(Icons.calendar_today, color: Colors.grey.shade700),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(task['dueDate']),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color:
                                task['status'] == 'Overdue' ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      task['description'].isNotEmpty
                          ? task['description']
                          : 'No description provided',
                      style: TextStyle(
                        fontSize: 16,
                        color: task['description'].isEmpty
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),

                    SizedBox(height: 32),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (task['status'] != 'Completed')
                          ElevatedButton.icon(
                            onPressed: () {
                              _updateTaskStatus(task['id'], 'Completed');
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.check_circle),
                            label: Text('Mark Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        if (task['status'] == 'Pending')
                          ElevatedButton.icon(
                            onPressed: () {
                              _updateTaskStatus(task['id'], 'In Progress');
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.play_arrow),
                            label: Text('Start Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        if (task['status'] == 'Completed')
                          ElevatedButton.icon(
                            onPressed: () {
                              _updateTaskStatus(task['id'], 'Pending');
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.replay),
                            label: Text('Reopen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      return 'Tomorrow';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
