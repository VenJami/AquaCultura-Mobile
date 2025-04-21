import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../models/task.dart' as task_model;
import '../providers/auth_provider.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({Key? key}) : super(key: key);

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load specific task instead of all tasks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load specific task by ID (the one from MongoDB)
      Provider.of<TaskProvider>(context, listen: false)
          .loadSpecificTask(context, "67f2690ba581b9c97005e7d3");
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Tasks',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<TaskProvider>(context, listen: false)
                  .loadTasks(context);
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = taskProvider.tasks;
          final pendingTasks = tasks
              .where((task) => !task.isCompleted && task.status != 'Completed')
              .toList();
          final completedTasks = tasks
              .where((task) => task.isCompleted || task.status == 'Completed')
              .toList();
          final overdueTasks = tasks
              .where((task) =>
                  task.status == 'Overdue' ||
                  (!task.isCompleted && task.dueDate.isBefore(DateTime.now())))
              .toList();

          return Column(
            children: [
              Container(
                color: Theme.of(context).primaryColor,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(text: 'Active (${pendingTasks.length})'),
                    Tab(text: 'Completed (${completedTasks.length})'),
                    Tab(text: 'Overdue (${overdueTasks.length})'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(context, pendingTasks),
                    _buildTaskList(context, completedTasks),
                    _buildTaskList(context, overdueTasks),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<task_model.Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabController.index == 1
                  ? Icons.check_circle_outline
                  : Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0
                  ? 'No active tasks'
                  : _tabController.index == 1
                      ? 'No completed tasks'
                      : 'No overdue tasks',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final dueDate = task.dueDate;
        final isPastDue = dueDate.isBefore(DateTime.now()) &&
            !task.isCompleted &&
            task.status != 'Completed';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  isPastDue ? Colors.red.withOpacity(0.5) : Colors.transparent,
              width: isPastDue ? 1 : 0,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                if (value != null) {
                  Provider.of<TaskProvider>(context, listen: false)
                      .toggleTaskStatus(context, task.id, value);
                }
              },
              shape: CircleBorder(),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(task.description),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: isPastDue ? Colors.red : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}',
                      style: TextStyle(
                        color: isPastDue ? Colors.red : Colors.grey[700],
                        fontWeight:
                            isPastDue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            _getPriorityColor(task.priority).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getPriorityColor(task.priority),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: null,
          ),
        );
      },
    );
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
}
