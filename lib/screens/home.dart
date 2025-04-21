import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/seedling_provider.dart';
import '../providers/task_provider.dart';
import '../config/api.dart';
import 'notification_page.dart';
import 'attendance_log_screen.dart';
import 'my_task_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_screen.dart';
import 'seedling_insights.dart';
import '../services/seedling_service.dart';
import 'package:intl/intl.dart';
import 'batch_details_screen.dart';
import '../models/task.dart' as task_model;
// import 'notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedTab = 0; // 0: My Task, 1: Team, 2: Finished

  bool _teamTask1Completed = false;
  bool _teamTask2Completed = false;

  List<dynamic> _seedlings = [];
  bool _isLoadingSeedlings = true;

  // Cache for expensive calculations
  String? _cachedTemperature;
  String? _cachedTemperatureStatus;
  String? _cachedPHLevel;
  String? _cachedPHLevelStatus;
  String? _cachedSeedlingAge;
  String? _cachedSeedlingAgeStatus;
  String? _cachedGermination;
  String? _cachedGerminationStatus;

  @override
  void initState() {
    super.initState();
    _loadSeedlings();

    // Load tasks when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false)
          .loadSpecificTask(context, "67f2690ba581b9c97005e7d3");
    });
  }

  Future<void> _loadSeedlings() async {
    setState(() {
      _isLoadingSeedlings = true;
    });

    try {
      // Try to get seedlings from the provider first
      final seedlingProvider = Provider.of<SeedlingProvider>(
        context,
        listen: false,
      );
      List<dynamic> providerSeedlings = seedlingProvider.seedlings;

      if (providerSeedlings.isNotEmpty) {
        setState(() {
          _seedlings = providerSeedlings;
          _isLoadingSeedlings = false;
        });
        _updateCalculationCache();
        return;
      }

      // If provider has no seedlings, load from API
      final response = await SeedlingService.getAllSeedlingsRaw();
      if (response.isNotEmpty) {
        setState(() {
          _seedlings = response;
          _isLoadingSeedlings = false;
        });

        // Update the provider
        seedlingProvider.updateSeedlings(response);
        _updateCalculationCache();
      } else {
        // Handle empty response
        setState(() {
          _seedlings = [];
          _isLoadingSeedlings = false;
        });
      }
    } catch (e) {
      setState(() {
        _seedlings = [];
        _isLoadingSeedlings = false;
      });
    }
  }

  // Update all cached calculations at once
  void _updateCalculationCache() {
    if (_seedlings.isEmpty) return;

    _cachedTemperature = _calculateAverageTemperature(_seedlings);
    _cachedTemperatureStatus = _getTemperatureStatus(_seedlings);
    _cachedPHLevel = _calculateAveragePHLevel(_seedlings).toString();
    _cachedPHLevelStatus = _getPHLevelStatus(_seedlings);
    _cachedSeedlingAge = '${_getLatestSeedlingAge(_seedlings)} days ago';
    _cachedSeedlingAgeStatus = _getLatestSeedlingAgeStatus(_seedlings);
    _cachedGermination = '${_calculateAverageGermination(_seedlings)}%';
    _cachedGerminationStatus = _getGerminationStatus(_seedlings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/icon.png'),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${Provider.of<AuthProvider>(context).user?.name ?? "User"}!',
                  style: const TextStyle(
                    color: Color(0xFF00679D),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Shift Time: ${Provider.of<AuthProvider>(context).user?.schedule ?? "8:00 AM - 4:00 PM"}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/notif.png', width: 24, height: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Image.asset('assets/cogwheel.png', width: 24, height: 24),
            onPressed: () {
              // Open settings or preferences screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSeedlings,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Attendance Section
              const Text(
                'Note: Please make sure you clock in to record your attendance for today.',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttendanceLogScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Log Here',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),

              // Offline mode indicator
              if (ApiConfig.useOfflineMode)
                Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Offline Mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              // Info Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(
                    'Water Temperature',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? '25°C'
                        : _cachedTemperature ??
                            _calculateAverageTemperature(_seedlings),
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? 'Normal'
                        : _cachedTemperatureStatus ??
                            _getTemperatureStatus(_seedlings),
                    'assets/watertemp.png',
                    Colors.blue,
                  ),
                  _buildInfoCard(
                    'PH Level',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? '6.0'
                        : _cachedPHLevel ??
                            _calculateAveragePHLevel(_seedlings).toString(),
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? 'Normal'
                        : _cachedPHLevelStatus ?? _getPHLevelStatus(_seedlings),
                    'assets/phlevel.png',
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(
                    'Nutrient Control',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? 'N/A'
                        : _cachedSeedlingAge ??
                            '${_getLatestSeedlingAge(_seedlings)} days ago',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? 'N/A'
                        : _cachedSeedlingAgeStatus ??
                            _getLatestSeedlingAgeStatus(_seedlings),
                    'assets/nutrietncontrol.png',
                    Colors.green,
                  ),
                  _buildInfoCard(
                    'Crop Insights',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? 'N/A'
                        : _cachedGermination ??
                            '${_calculateAverageGermination(_seedlings)}%',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? 'N/A'
                        : _cachedGerminationStatus ??
                            _getGerminationStatus(_seedlings),
                    'assets/cropinsights.png',
                    Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              // Crop Insight Section (moved above the task tabs)
              Row(
                children: [
                  Image.asset(
                    'assets/cropinsightsicon.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Crop Insight',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeedlingsInsightsScreen(),
                          ),
                        ).then((_) => _loadSeedlings());
                      },
                      child: const Text(
                        'Seedlings Insight',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _isLoadingSeedlings
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _seedlings.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'No seedlings available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: _seedlings
                                    .take(4) // Show only first 4 seedlings
                                    .map(
                                      (seedling) =>
                                          _buildSeedlingItemFromData(seedling),
                                    )
                                    .toList(),
                              ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Tabs for My Task and Team
              // My Task and Team Tabs with Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _selectedTab = 0),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/mytaskicon.png',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'My Task',
                          style: TextStyle(
                            fontWeight: _selectedTab == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            decoration: _selectedTab == 0
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedTab = 1),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/teamicon.png',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Team',
                          style: TextStyle(
                            fontWeight: _selectedTab == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            decoration: _selectedTab == 1
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_selectedTab == 0)
                _buildMyTaskSection()
              else if (_selectedTab == 1)
                _buildTeamSection(),

              // Calendar Navigation and Widget at the Bottom
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: _buildCalendarWidget(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeedlingItemFromData(dynamic seedling) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Image.asset(
        'assets/cropinsightsicon.png',
        width: 20,
        height: 20,
      ),
      title: Text(
        seedling['batchName'] ?? 'Unknown Batch',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Planted date: ${DateFormat('MMM. d, yyyy').format(DateTime.parse(seedling['plantedDate']))}',
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BatchDetailsScreen(seedlingId: seedling['_id']),
          ),
        ).then((_) => _loadSeedlings());
      },
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    String status,
    String imagePath,
    Color textColor,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imagePath, width: 40, height: 40),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            status,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget() {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      calendarStyle: const CalendarStyle(
        defaultTextStyle: TextStyle(color: Colors.blue),
        weekendTextStyle: TextStyle(color: Colors.blue),
        todayDecoration: BoxDecoration(
          color: Colors.lightBlueAccent,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        titleTextStyle: TextStyle(color: Colors.blue),
        formatButtonTextStyle: TextStyle(color: Colors.blue),
        formatButtonDecoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.blue),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.blue),
      ),
    );
  }

  Widget _buildMyTaskSection() {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyTasksScreen()),
              ).then((_) {
                // Refresh tasks when returning from task screen
                Provider.of<TaskProvider>(
                  context,
                  listen: false,
                ).loadTasks(context);
              });
            },
            child: const Text(
              'My Daily Task Board',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Show loading indicator when tasks are loading
          if (taskProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          // Show tasks or "All tasks are done" message
          else if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: const [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'All tasks are done!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: tasks.take(3).map<Widget>((task_model.Task task) {
                // Format date for display
                final dueDate = task.dueDate;
                final now = DateTime.now();
                final isToday = dueDate.year == now.year &&
                    dueDate.month == now.month &&
                    dueDate.day == now.day;
                final dateDisplay = isToday
                    ? 'Today, ${_formatDate(dueDate)}'
                    : _formatDate(dueDate);

                return ListTile(
                  leading: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(unselectedWidgetColor: Colors.grey),
                    child: Checkbox(
                      shape: const CircleBorder(),
                      value: task.isCompleted,
                      onChanged: (value) {
                        if (value != null) {
                          taskProvider.toggleTaskStatus(
                            context,
                            task.id,
                            value,
                          );
                        }
                      },
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text('Due: $dateDisplay\n${task.description}'),
                );
              }).toList(),
            ),

          // Show "View All" button if there are more than 3 tasks
          if (tasks.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyTasksScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'View All Tasks',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to format dates
  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildTeamSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Team's Task",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: Theme(
              data: Theme.of(
                context,
              ).copyWith(unselectedWidgetColor: Colors.grey),
              child: Checkbox(
                shape: const CircleBorder(),
                value: _teamTask1Completed,
                onChanged: (value) {
                  setState(() {
                    _teamTask1Completed = value!;
                  });
                },
              ),
            ),
            title: const Text('Daily Seedlings Check: Batch 24 Lettuce'),
            subtitle: const Text('Due: Today February 10, 2025\nTime: 4:00 PM'),
          ),
          ListTile(
            leading: Theme(
              data: Theme.of(
                context,
              ).copyWith(unselectedWidgetColor: Colors.grey),
              child: Checkbox(
                shape: const CircleBorder(),
                value: _teamTask2Completed,
                onChanged: (value) {
                  setState(() {
                    _teamTask2Completed = value!;
                  });
                },
              ),
            ),
            title: const Text('Transplant Strong Seedlings: Batch 25 Basil'),
            subtitle: const Text('Due: Today February 10, 2025\nTime: 4:00 PM'),
          ),
        ],
      ),
    );
  }

  // Helper method to calculate average temperature
  String _calculateAverageTemperature(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return '25°C';

    double sum = 0;
    for (var seedling in seedlings) {
      sum += seedling['temperature'] ?? 25.0;
    }
    return '${(sum / seedlings.length).toStringAsFixed(1)}°C';
  }

  // Helper method to get temperature status
  String _getTemperatureStatus(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 'Normal';

    double sum = 0;
    for (var seedling in seedlings) {
      sum += seedling['temperature'] ?? 25.0;
    }
    double avgTemp = sum / seedlings.length;

    if (avgTemp < 18) return 'Low';
    if (avgTemp > 30) return 'High';
    return 'Normal';
  }

  // Helper method to calculate average pH level
  double _calculateAveragePHLevel(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 6.0;

    double sum = 0;
    for (var seedling in seedlings) {
      sum += seedling['pHLevel'] ?? 6.0;
    }
    return double.parse((sum / seedlings.length).toStringAsFixed(1));
  }

  // Helper method to get pH level status
  String _getPHLevelStatus(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 'Normal';

    double avgPH = _calculateAveragePHLevel(seedlings);
    if (avgPH < 5.5) return 'Low';
    if (avgPH > 7.0) return 'High';
    return 'Normal';
  }

  // Helper method to get the latest seedling age in days
  String _getLatestSeedlingAge(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return '0';

    // Sort seedlings by planted date (most recent first)
    seedlings.sort((a, b) {
      DateTime dateA = DateTime.parse(a['plantedDate']);
      DateTime dateB = DateTime.parse(b['plantedDate']);
      return dateB.compareTo(dateA);
    });

    // Get the most recent seedling's age in days
    DateTime plantedDate = DateTime.parse(seedlings.first['plantedDate']);
    int daysSincePlanting = DateTime.now().difference(plantedDate).inDays;
    return daysSincePlanting.toString();
  }

  // Helper method to get latest seedling age status
  String _getLatestSeedlingAgeStatus(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 'N/A';

    int days = int.tryParse(_getLatestSeedlingAge(seedlings)) ?? 0;
    if (days < 3) return 'Recent';
    if (days > 7) return 'Due Soon';
    return 'Normal';
  }

  // Helper method to calculate average germination
  String _calculateAverageGermination(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return '0';

    double sum = 0;
    for (var seedling in seedlings) {
      sum += seedling['germination'] ?? 0.0;
    }
    return (sum / seedlings.length).toStringAsFixed(0);
  }

  // Helper method to get germination status
  String _getGerminationStatus(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 'N/A';

    double avgGermination =
        double.tryParse(_calculateAverageGermination(seedlings)) ?? 0;
    if (avgGermination < 50) return 'Low';
    if (avgGermination > 85) return 'Excellent';
    return 'Normal';
  }
}
