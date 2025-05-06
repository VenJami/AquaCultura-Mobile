import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/seedling_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
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
import 'settings_screen.dart';
import 'package:fl_chart/fl_chart.dart';
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
  List<bool> _taskTeamToggleSelection = [true, false];

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

  // --- Placeholder Chart Data ---
  final List<FlSpot> _tempChartData = [
    const FlSpot(0, 24),
    const FlSpot(1, 25),
    const FlSpot(2, 26),
    const FlSpot(3, 25),
    const FlSpot(4, 24),
    const FlSpot(5, 25),
    const FlSpot(6, 26),
  ];

  final List<FlSpot> _phChartData = [
    const FlSpot(0, 6.0),
    const FlSpot(1, 6.1),
    const FlSpot(2, 6.2),
    const FlSpot(3, 6.1),
    const FlSpot(4, 6.0),
    const FlSpot(5, 6.1),
    const FlSpot(6, 6.2),
  ];

  final List<FlSpot> _nutrientChartData = [
    const FlSpot(0, 4),
    const FlSpot(1, 5),
    const FlSpot(2, 6),
    const FlSpot(3, 5),
    const FlSpot(4, 4),
    const FlSpot(5, 5),
    const FlSpot(6, 6),
  ];

  final List<FlSpot> _germinationChartData = [
    const FlSpot(0, 80),
    const FlSpot(1, 82),
    const FlSpot(2, 83),
    const FlSpot(3, 81),
    const FlSpot(4, 82),
    const FlSpot(5, 84),
    const FlSpot(6, 83),
  ];
  // --- End Placeholder Data ---

  @override
  void initState() {
    super.initState();
    _refreshHomeScreenData(); // Load initial data

    // Load tasks when the screen is initialized (Keep for potential future use)
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<TaskProvider>(context, listen: false)
    //       .loadSpecificTask(context, "67f2690ba581b9c97005e7d3");
    // });
  }

  Future<void> _refreshHomeScreenData() async {
    setState(() {
      _isLoadingSeedlings = true;
      // Consider adding a separate isLoadingTasks if needed for granular feedback
    });

    try {
      // Fetch seedlings and tasks concurrently
      final results = await Future.wait([
        _fetchSeedlings(),
        _fetchTasks(),
      ]);

      // Update state after both fetches are complete
      final fetchedSeedlings = results[0] as List<dynamic>?; // Result from _fetchSeedlings

      setState(() {
        _seedlings = fetchedSeedlings ?? [];
        _isLoadingSeedlings = false;
        // Update cache only if seedlings were fetched
        if (fetchedSeedlings != null) {
          _updateCalculationCache();
        }
      });

    } catch (e) {
      // print('Error refreshing home screen data: $e'); // TODO: Add proper error handling
      setState(() {
        _seedlings = [];
        _isLoadingSeedlings = false;
      });
    }
  }

  Future<List<dynamic>?> _fetchSeedlings() async {
    final seedlingProvider = Provider.of<SeedlingProvider>(context, listen: false);
    // Try provider first (optional optimization, can be removed if always refreshing)
    // List<dynamic> providerSeedlings = seedlingProvider.seedlings;
    // if (providerSeedlings.isNotEmpty) {
    //   return providerSeedlings;
    // }

    try {
      final response = await SeedlingService.getAllSeedlingsRaw();
      if (response.isNotEmpty) {
        // Update the provider
        seedlingProvider.updateSeedlings(response);
        return response;
      } else {
        seedlingProvider.updateSeedlings([]); // Clear provider if response is empty
        return []; // Return empty list
      }
    } catch (e) {
      // print('Error fetching seedlings: $e');
      seedlingProvider.updateSeedlings([]); // Clear provider on error
      return null; // Indicate error
    }
  }

  Future<void> _fetchTasks() async {
    try {
      // Assuming TaskProvider has a method like loadTasks
      // Use listen: false as we are calling it in response to an event, not building UI based on it here
      await Provider.of<TaskProvider>(context, listen: false).loadTasks(context);
    } catch (e) {
      // print('Error fetching tasks: $e');
      // Handle task loading error if necessary (e.g., show a message)
    }
  }

  // Update all cached calculations at once
  void _updateCalculationCache() {
    if (_seedlings.isEmpty) return;

    _cachedTemperature = _calculateAverageTemperature(_seedlings);
    _cachedTemperatureStatus = _getTemperatureStatus(_seedlings);
    _cachedPHLevel = _calculateAveragePHLevel(_seedlings).toString();
    _cachedPHLevelStatus = _getPHLevelStatus(_seedlings);
    _cachedSeedlingAge = '${_getLatestSeedlingAge(_seedlings)}'; // Just days number
    _cachedSeedlingAgeStatus = _getLatestSeedlingAgeStatus(_seedlings);
    _cachedGermination = '${_calculateAverageGermination(_seedlings)}'; // Just number
    _cachedGerminationStatus = _getGerminationStatus(_seedlings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;

    // Define colors for closer match to screenshot
    const reminderCardColor = Color(0xFFFFA726); // Keep custom Reminder color for now
    const statusNormalColor = Colors.green;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background
      appBar: AppBar(
        backgroundColor: colorScheme.primary, // Use theme primary color
        elevation: 0,
        toolbarHeight: 80, // Increased height for content
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Good Morning',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary),
            ),
            Text(
              user?.name ?? 'User',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
            Text(
              'Shift: ${user?.schedule ?? "8:00 AM - 4:00 PM"}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
            ),
          ],
        ),
        actions: [
          _buildAppBarAction(Icons.refresh, () {
            _refreshHomeScreenData(); // Call the combined refresh method
          }),
          _buildAppBarAction(Icons.notifications_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          }),
          _buildAppBarAction(Icons.settings_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          }),
          // Temporary Theme Switcher Button (Optional: Keep or remove)
          IconButton(
            tooltip: "Cycle Theme: ${themeProvider.currentPaletteName}",
            icon: Icon(Icons.palette_outlined, color: colorScheme.onPrimary), // Use theme color
            onPressed: () {
              themeProvider.cyclePalette();
            },
          ),
          const SizedBox(width: 8), // Spacing at the end
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHomeScreenData, // Use combined refresh for pull-to-refresh
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Horizontal padding
          child: ListView(
            children: [
              const SizedBox(height: 16), // Space below AppBar
              // --- Attendance Reminder Card ---
              // Card(
              //   color: reminderCardColor, // Custom orange
              //   shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12)),
              //   elevation: 2,
              //   child: Padding(
              //     padding: const EdgeInsets.all(16.0),
              //     child: Row(
              //       children: [
              //         const CircleAvatar(
              //           backgroundColor: Colors.white54,
              //           radius: 18,
              //           child: Icon(Icons.timer_outlined,
              //               color: reminderCardColor, size: 20),
              //         ),
              //         const SizedBox(width: 12),
              //         Expanded(
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text(
              //                 'Attendance Reminder',
              //                 style: theme.textTheme.titleMedium?.copyWith(
              //                     color: Colors.white,
              //                     fontWeight: FontWeight.bold),
              //               ),
              //               const SizedBox(height: 4),
              //               Text(
              //                 'Please make sure you clock in to record your attendance for today.',
              //                 style: theme.textTheme.bodySmall
              //                     ?.copyWith(color: Colors.white70),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              // Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 12.0),
              //   child: GestureDetector(
              //     onTap: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => const AttendanceLogScreen(),
              //         ),
              //       );
              //     },
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Icon(Icons.touch_app_outlined,
              //             color: colorScheme.primary, size: 18),
              //         const SizedBox(width: 8),
              //         Text(
              //           'Clock In Now',
              //           style: theme.textTheme.bodyMedium?.copyWith(
              //             fontWeight: FontWeight.bold,
              //             color: colorScheme.primary,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              // --- Farm Status Section Header ---
              _buildSectionHeader('Farm Status', Icons.water_drop_outlined,
                  colorScheme.primary),
              const SizedBox(height: 12),

              // --- Info Cards Grid ---
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.9, // Adjusted for chart space
                children: [
                  _buildInfoCard(
                    context,
                    'Water Temperature',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? '25°C'
                        : _cachedTemperature ??
                            _calculateAverageTemperature(_seedlings),
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? 'Normal'
                        : _cachedTemperatureStatus ??
                            _getTemperatureStatus(_seedlings),
                    Icons.thermostat,
                    _tempChartData, // Pass chart data
                    Colors.blue, // Chart line color
                  ),
                  _buildInfoCard(
                    context,
                    'PH Level',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? '6.0'
                        : _cachedPHLevel ??
                            _calculateAveragePHLevel(_seedlings).toString(),
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? 'Normal'
                        : _cachedPHLevelStatus ?? _getPHLevelStatus(_seedlings),
                    Icons.science_outlined,
                    _phChartData, // Pass chart data
                    Colors.orange, // Chart line color
                  ),
                  _buildInfoCard(
                    context,
                    'Nutrient Control',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? '5 days ago' // Example value
                        : '${_cachedSeedlingAge ?? '0'} days ago',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? 'Normal'
                        : _cachedSeedlingAgeStatus ??
                            _getLatestSeedlingAgeStatus(_seedlings),
                    Icons.spa_outlined,
                    _nutrientChartData, // Pass chart data
                    Colors.green, // Chart line color
                  ),
                  _buildInfoCard(
                    context,
                    'Crop Insights',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? '83%' // Example value
                        : '${_cachedGermination ?? '0'}%',
                    _isLoadingSeedlings || _seedlings.isEmpty
                        ? 'Normal'
                        : _cachedGerminationStatus ??
                            _getGerminationStatus(_seedlings),
                    Icons.bar_chart,
                    _germinationChartData, // Pass chart data
                    Colors.purple, // Chart line color
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // --- Crop Insight Section Header ---
              _buildSectionHeader(
                  'Crop Insight', Icons.eco_outlined, colorScheme.primary),
              const SizedBox(height: 12),
              // --- Seedlings List Card ---
              Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16.0, top: 16, right: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeedlingsInsightsScreen(),
                            ),
                          ).then((_) => _refreshHomeScreenData());
                        },
                        child: Text(
                          'Seedlings Insight', // Title inside card now
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
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
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 30.0),
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
              const SizedBox(height: 12), // Add spacing between cards

              // --- Add Transplant Insight Card --- 
              Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transplant Insight', // Title
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Placeholder content - Replace with real data/widgets
                      Row(
                        children: [
                          Icon(Icons.transfer_within_a_station_outlined, color: theme.hintColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Some batches might be ready for transplanting soon. Check details.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      // Add more details or actions here if needed
                    ],
                  ),
                ),
              ),
              // --- End Transplant Insight Card --- 

              const SizedBox(height: 24),

              // --- Restore Task/Team Toggle Buttons ---
              Center(
                child: ToggleButtons(
                  isSelected: _taskTeamToggleSelection,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _taskTeamToggleSelection.length; i++) {
                        _taskTeamToggleSelection[i] = i == index;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  selectedColor: colorScheme.onPrimary,
                  color: colorScheme.primary,
                  fillColor: colorScheme.primary,
                  constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 18),
                          SizedBox(width: 8),
                          Text('My Task'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Team'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // --- Restore Task/Team Sections ---
              if (_taskTeamToggleSelection[0])
                _buildMyTaskSection()
              else if (_taskTeamToggleSelection[1])
                _buildTeamSection(),

              const SizedBox(height: 24),
              // --- Restore Calendar Section Header & Widget ---
              _buildSectionHeader('Calendar Overview', Icons.calendar_today_outlined,
                  colorScheme.primary),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Padding inside card
                  child: _buildCalendarWidget(),
                ),
              ),
              const SizedBox(height: 24), // Spacing at the end
            ],
          ),
        ),
      ),
    );
  }

  // Helper for AppBar actions
  Widget _buildAppBarAction(IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
        child: IconButton(
          icon: Icon(icon, size: 20, color: colorScheme.onPrimary),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }

  // Helper for Section Headers
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSeedlingItemFromData(dynamic seedling) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true, // Make list items less tall
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading:
          Icon(Icons.eco_outlined, color: theme.colorScheme.primary, size: 20),
      title: Text(
        seedling['batchName'] ?? 'Unknown Batch',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Planted date: ${DateFormat('MMM. d, yyyy').format(DateTime.parse(seedling['plantedDate']))}',
        style: theme.textTheme.bodySmall,
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/batchDetails', 
          arguments: {'seedlingId': seedling['_id']}, // Pass seedlingId as argument
        ).then((_) => _refreshHomeScreenData()); // Keep refresh logic
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    String status,
    IconData iconData,
    List<FlSpot> chartData,
    Color chartLineColor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor), // Muted title
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: chartLineColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle, color: chartLineColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: chartLineColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const Spacer(), // Push chart to bottom
            SizedBox(
              height: 40, // Height for the chart
              child: _buildMiniLineChart(chartData, chartLineColor),
            ),
          ],
        ),
      ),
    );
  }

  // --- Mini Line Chart Widget ---
  Widget _buildMiniLineChart(List<FlSpot> spots, Color lineColor) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withOpacity(0.3),
                  lineColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minX: spots.first.x,
        maxX: spots.last.x,
        // Adjust Y range slightly for padding, or dynamically based on data
        minY: spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 1,
        maxY: spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 1,
        baselineY: 0,
      ),
      duration: const Duration(milliseconds: 150), // Optional animation
    );
  }
  // --- End Mini Line Chart Widget ---

  // --- Restore and Restyle HIDDEN WIDGETS ---

  Widget _buildCalendarWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      calendarFormat: _calendarFormat,
      availableGestures: AvailableGestures.horizontalSwipe,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          // Optionally navigate or show tasks for the selected day
        });
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      calendarStyle: CalendarStyle(
        defaultTextStyle: TextStyle(color: colorScheme.onSurface),
        weekendTextStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        todayDecoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(color: colorScheme.onPrimary),
        outsideTextStyle: TextStyle(color: theme.hintColor.withOpacity(0.5)),
      ),
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false, // Hide format button for cleaner look
        titleTextStyle: theme.textTheme.titleMedium!.copyWith(
            color: colorScheme.primary, fontWeight: FontWeight.bold),
        leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.primary),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: theme.hintColor),
        weekendStyle: TextStyle(color: theme.hintColor.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildMyTaskSection() {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                'My Daily Tasks', Icons.task_alt_outlined, colorScheme.primary),
            const SizedBox(height: 12),

            if (taskProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 40),
                      const SizedBox(height: 8),
                      Text('All tasks are done!',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.green)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.take(3).length, // Show max 3 tasks
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final dueDate = task.dueDate;
                  final now = DateTime.now();
                  final isToday = dueDate.year == now.year &&
                      dueDate.month == now.month &&
                      dueDate.day == now.day;
                  final dateDisplay = isToday
                      ? 'Today, ${_formatDate(dueDate)}'
                      : _formatDate(dueDate);

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      visualDensity: VisualDensity.compact,
                      shape: const CircleBorder(),
                      value: task.isCompleted,
                      activeColor: colorScheme.primary,
                      checkColor: colorScheme.onPrimary,
                      side: BorderSide(color: theme.hintColor),
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
                    title: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Due: $dateDisplay', // Simpler subtitle
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Add onTap to view task details maybe?
                  );
                },
              ),

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
                    child: Text('View All Tasks',
                        style: TextStyle(color: colorScheme.primary)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Example static data for team tasks
    final List<Map<String, dynamic>> teamTasks = [
      {
        'id': 't1',
        'title': 'Daily Seedlings Check: Batch 24 Lettuce',
        'due': 'Today, 4:00 PM',
        'completed': _teamTask1Completed,
      },
      {
        'id': 't2',
        'title': 'Transplant Strong Seedlings: Batch 25 Basil',
        'due': 'Today, 4:00 PM',
        'completed': _teamTask2Completed,
      },
    ];

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                'Team Tasks', Icons.group_outlined, colorScheme.primary),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teamTasks.length,
              itemBuilder: (context, index) {
                final task = teamTasks[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    visualDensity: VisualDensity.compact,
                    shape: const CircleBorder(),
                    value: task['completed'],
                    activeColor: colorScheme.primary,
                    checkColor: colorScheme.onPrimary,
                    side: BorderSide(color: theme.hintColor),
                    onChanged: (value) {
                      setState(() {
                        if (task['id'] == 't1') {
                          _teamTask1Completed = value!;
                        } else if (task['id'] == 't2') {
                          _teamTask2Completed = value!;
                        }
                      });
                    },
                  ),
                  title: Text(
                    task['title'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      decoration:
                          task['completed'] ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Due: ${task['due']}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
            // Add "View All Team Tasks" button if applicable
          ],
        ),
      ),
    );
  }

  // --- Helper methods for calculations (Keep as is) ---
  String _calculateAverageTemperature(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return '25°C';
    double sum = 0;
    for (var seedling in seedlings) {
      sum += seedling['temperature'] ?? 25.0;
    }
    return '${(sum / seedlings.length).toStringAsFixed(1)}°C';
  }

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

  double _calculateAveragePHLevel(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 6.0;
    double sum = 0;
    for (var seedling in seedlings) {
      sum += seedling['pHLevel'] ?? 6.0;
    }
    return double.parse((sum / seedlings.length).toStringAsFixed(1));
  }

  String _getPHLevelStatus(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 'Normal';
    double avgPH = _calculateAveragePHLevel(seedlings);
    if (avgPH < 5.5) return 'Low';
    if (avgPH > 7.0) return 'High';
    return 'Normal';
  }

  String _getLatestSeedlingAge(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return '0';
    seedlings.sort((a, b) {
      DateTime dateA = DateTime.parse(a['plantedDate']);
      DateTime dateB = DateTime.parse(b['plantedDate']);
      return dateB.compareTo(dateA);
    });
    DateTime plantedDate = DateTime.parse(seedlings.first['plantedDate']);
    int daysSincePlanting = DateTime.now().difference(plantedDate).inDays;
    return daysSincePlanting.toString();
  }

  String _getLatestSeedlingAgeStatus(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 'Normal'; // Default to Normal if no age
    int days = int.tryParse(_getLatestSeedlingAge(seedlings)) ?? 0;
    if (days < 3) return 'Recent';
    if (days > 14) return 'Old'; // Example threshold
    return 'Normal';
  }

  String _calculateAverageGermination(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return '0';
    double sum = 0;
    for (var seedling in seedlings) {
      sum += seedling['germination'] ?? 0.0;
    }
    return (sum / seedlings.length).toStringAsFixed(0);
  }

  String _getGerminationStatus(List<dynamic> seedlings) {
    if (seedlings.isEmpty) return 'N/A';
    double avgGermination =
        double.tryParse(_calculateAverageGermination(seedlings)) ?? 0;
    if (avgGermination < 50) return 'Low';
    if (avgGermination > 85) return 'Excellent';
    return 'Normal';
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
