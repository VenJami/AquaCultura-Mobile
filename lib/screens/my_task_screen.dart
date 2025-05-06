import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../models/task.dart' as task_model;
import '../providers/auth_provider.dart';

// Enum to represent task filter states
enum TaskFilter { active, completed, overdue }

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({Key? key}) : super(key: key);

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  // State for the selected filter
  Set<TaskFilter> _selectedSegment = {TaskFilter.active};

  @override
  void initState() {
    super.initState();
    // Load tasks when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks(context);
    });
  }

  @override
  void dispose() {
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

          final colorScheme = Theme.of(context).colorScheme;

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

          // Determine which list to show based on the selected segment
          final List<task_model.Task> currentList;
          final TaskFilter currentFilter = _selectedSegment.first;
          switch (currentFilter) {
            case TaskFilter.active:
              currentList = pendingTasks;
              break;
            case TaskFilter.completed:
              currentList = completedTasks;
              break;
            case TaskFilter.overdue:
              currentList = overdueTasks;
              break;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SegmentedButton<TaskFilter>(
                  segments: <ButtonSegment<TaskFilter>>[
                    ButtonSegment<TaskFilter>(
                        value: TaskFilter.active,
                        label: Text('Active (${pendingTasks.length})'),
                        icon: const Icon(Icons.list_alt)),
                    ButtonSegment<TaskFilter>(
                        value: TaskFilter.completed,
                        label: Text('Completed (${completedTasks.length})'),
                        icon: const Icon(Icons.check_circle)),
                    ButtonSegment<TaskFilter>(
                        value: TaskFilter.overdue,
                        label: Text('Overdue (${overdueTasks.length})'),
                        icon: const Icon(Icons.warning_amber)),
                  ],
                  selected: _selectedSegment,
                  onSelectionChanged: (Set<TaskFilter> newSelection) {
                    setState(() {
                      // By default, segmented button clears selection
                      // if you tap the same segment again. Ensure one segment
                      // is always selected for this use case.
                      if (newSelection.isNotEmpty) {
                        _selectedSegment = newSelection;
                      }
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainer,
                    foregroundColor: colorScheme.primary,
                    selectedForegroundColor: colorScheme.onPrimary,
                    selectedBackgroundColor: colorScheme.primary,
                  ),
                  showSelectedIcon: false,
                ),
              ),
              Expanded(
                child: _buildTaskList(context, currentList, currentFilter),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<task_model.Task> tasks, TaskFilter filter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filter == TaskFilter.completed
                  ? Icons.check_circle_outline_rounded
                  : filter == TaskFilter.overdue
                      ? Icons.running_with_errors_rounded // More active icon for overdue
                      : Icons.inbox_rounded, // Icon for active/empty inbox
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              filter == TaskFilter.active
                  ? 'No active tasks'
                  : filter == TaskFilter.completed
                      ? 'No completed tasks'
                      : 'No overdue tasks',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurfaceVariant,
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
        // Determine if overdue based on the filter or date comparison for active tasks
        final bool isOverdue = filter == TaskFilter.overdue ||
            (filter == TaskFilter.active &&
                !task.isCompleted &&
                task.status != 'Completed' &&
                dueDate.isBefore(DateTime.now()));
        final bool isCompleted = task.isCompleted || task.status == 'Completed';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 1,
          color: colorScheme.surfaceContainerHighest, // Slightly different background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Checkbox(
              value: isCompleted,
              onChanged: (value) {
                if (value != null) {
                  Provider.of<TaskProvider>(context, listen: false)
                      .toggleTaskStatus(context, task.id, value);
                }
              },
              shape: const CircleBorder(),
              activeColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.outline),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Slightly bolder
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  maxLines: 2, // Limit description lines
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14,
                        color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}',
                      style: TextStyle(
                        color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(), // Push priority to the end
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: _getPriorityColor(task.priority, colorScheme),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.priority,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPriorityColor(task.priority, colorScheme),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Color _getPriorityColor(String priority, ColorScheme colorScheme) {
    switch (priority) {
      case 'High':
        return colorScheme.error; // Use theme error color
      case 'Medium':
        return colorScheme.tertiary; // Use theme tertiary color (adjust if needed)
      case 'Low':
        return colorScheme.primary; // Use theme primary color
      default:
        return colorScheme.onSurfaceVariant; // Default color
    }
  }
}
