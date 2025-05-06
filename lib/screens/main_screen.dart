import 'package:flutter/material.dart';
import 'home.dart';
import 'seedling_insights.dart';
import 'my_task_screen.dart';
import 'calendar_screen.dart';
import 'batch_details_screen.dart';
import 'notification_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // GlobalKeys for Navigator states
  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _insightsNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _tasksNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _calendarNavigatorKey = GlobalKey<NavigatorState>();

  // List of navigator keys
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = [
      _homeNavigatorKey,
      _insightsNavigatorKey,
      _tasksNavigatorKey,
      _calendarNavigatorKey,
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // If the current tab is tapped again, pop to its first route
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      // Switch tab
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // WillPopScope handles the Android back button
    return WillPopScope(
      onWillPop: () async {
        // Check if the current navigator can pop
        final NavigatorState? currentNavigator = _navigatorKeys[_selectedIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return false; // Prevent default back button behavior (closing app)
        }
        // If the current navigator can't pop, allow default behavior (close app)
        // Allow pop only if on the first tab (Home) and its navigator cannot pop
        return _selectedIndex == 0; 
      },
      child: Scaffold(
        // AppBar removed from here - each screen in nested Navigators should have its own if needed
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(_navigatorKeys.length, (index) {
            // Use the _buildOffstageNavigator helper
            return _buildOffstageNavigator(index); 
          }),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.eco), // Or Icons.grass
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt), // Or Icons.list_alt
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Calendar',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: colorScheme.primary, // Use theme primary color
          unselectedItemColor: theme.unselectedWidgetColor, // Use theme unselected color
          showUnselectedLabels: true, // Show labels for inactive tabs
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Ensures all items are visible
        ),
      ),
    );
  }

  // Builds a Navigator for a specific tab index
  Widget _buildOffstageNavigator(int index) {
    // Get the route map for the current index
    var routeMap = _getRoutesForIndex(index); 
    return Navigator(
      key: _navigatorKeys[index],
      initialRoute: '/', // Standard initial route name
      onGenerateRoute: (routeSettings) {
        // Find the builder for the requested route name
        final pageBuilder = routeMap[routeSettings.name];
        if (pageBuilder != null) {
          return MaterialPageRoute(
            settings: routeSettings, // Pass settings for arguments, etc.
            builder: (context) => pageBuilder(context),
          );
        }
        // Handle unknown routes: default to the root screen of the tab
        return MaterialPageRoute(
          settings: routeSettings, 
          builder: (context) => routeMap['/']!(context) // Go to root if route unknown
        );
      },
    );
  }

  // Helper to get the route map for a given tab index
  Map<String, WidgetBuilder> _getRoutesForIndex(int index) {
    switch (index) {
      case 0: // Home Tab
        return {
          '/': (context) => const HomeScreen(),
          '/batchDetails': (context) => _buildBatchDetails(context),
          '/notification_page': (context) => const NotificationScreen(),
          // Add other routes accessible from Home tab
        };
      case 1: // Insights Tab
        return {
          '/': (context) => const SeedlingsInsightsScreen(),
          '/batchDetails': (context) => _buildBatchDetails(context),
          // Add other routes accessible from Insights tab
        };
      case 2: // Tasks Tab
        return {
          '/': (context) => const MyTasksScreen(),
          // Add other routes accessible from Tasks tab
        };
      case 3: // Calendar Tab
        return {
          '/': (context) => const CalendarScreen(),
          // Add other routes accessible from Calendar tab
        };
      default:
        // Return a default empty route map or error screen builder
        return {'/': (context) => const Center(child: Text('Unknown Tab'))};
    }
  }

  // Helper to build BatchDetailsScreen, handling arguments
  Widget _buildBatchDetails(BuildContext context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      final seedlingId = args?['seedlingId'] as String?;
      if (seedlingId == null) {
        // Handle missing argument - pop back or show error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } 
        });
        return const Scaffold(body: Center(child: Text("Error: Missing seedlingId")));
      }
      return BatchDetailsScreen(seedlingId: seedlingId);
  }
} 