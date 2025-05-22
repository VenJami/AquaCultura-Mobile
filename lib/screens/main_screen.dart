import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/due_items_notification_provider.dart';
import '../providers/main_screen_tab_provider.dart';
import 'home.dart';
import 'seedling_insights.dart';
import 'my_task_screen.dart';
import 'calendar_screen.dart';
// import 'batch_details_screen.dart'; // Removed import for deleted file
import 'notification_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _insightsNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _tasksNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _calendarNavigatorKey = GlobalKey<NavigatorState>();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DueItemsNotificationProvider>(context, listen: false).loadDueItemsNotifications();
      final tabProvider = Provider.of<MainScreenTabProvider>(context, listen: false);
      if (tabProvider.navigationArguments != null) {
        _handleTabNavigationArguments(tabProvider.selectedIndex, tabProvider.navigationArguments);
        tabProvider.clearNavigationArguments();
      }
    });
  }

  void _handleTabNavigationArguments(int tabIndex, dynamic args) {
    if (tabIndex == 2 && args is Map && args.containsKey('taskId')) {
        print('[MainScreen] Should navigate to Tasks tab with taskId: ${args['taskId']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tabProvider = Provider.of<MainScreenTabProvider>(context);
    final currentSelectedIndex = tabProvider.selectedIndex;

    return WillPopScope(
      onWillPop: () async {
        final NavigatorState? currentNavigator = _navigatorKeys[currentSelectedIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return false; 
        }
        return currentSelectedIndex == 0;
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentSelectedIndex,
          children: List.generate(_navigatorKeys.length, (index) {
            dynamic initialRouteArgs = (index == currentSelectedIndex) ? tabProvider.navigationArguments : null;
            return _buildOffstageNavigator(index, initialRouteArgs);
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
          currentIndex: currentSelectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).unselectedWidgetColor,
          showUnselectedLabels: true,
          onTap: (index) {
            if (currentSelectedIndex == index) {
              _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
            } else {
              tabProvider.selectTab(index, arguments: null);
            }
          },
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  Widget _buildOffstageNavigator(int index, dynamic initialRouteArguments) {
    var routeMap = _getRoutesForIndex(index); 
    String initialRouteName = '/';

    return Navigator(
      key: _navigatorKeys[index],
      initialRoute: initialRouteName,
      onGenerateRoute: (routeSettings) {
        RouteSettings settingsToUse = routeSettings;
        if (routeSettings.name == initialRouteName && initialRouteArguments != null) {
          settingsToUse = RouteSettings(
            name: routeSettings.name,
            arguments: initialRouteArguments,
          );
          Provider.of<MainScreenTabProvider>(context, listen: false).clearNavigationArguments();
        }

        final pageBuilder = routeMap[settingsToUse.name ?? initialRouteName];
        if (pageBuilder != null) {
          return MaterialPageRoute(
            settings: settingsToUse, 
            builder: (context) => pageBuilder(context),
          );
        }
        return MaterialPageRoute(
          settings: settingsToUse,
          builder: (context) => routeMap[initialRouteName]!(context)
        );
      },
    );
  }

  Map<String, WidgetBuilder> _getRoutesForIndex(int index) {
    switch (index) {
      case 0: // Home Tab
        return {
          '/': (context) => const HomeScreen(),
          '/notification_page': (context) => const NotificationScreen(),
        };
      case 1: // Insights Tab
        return {
          '/': (context) => const SeedlingsInsightsScreen(),
        };
      case 2: // Tasks Tab
        return {
          '/': (context) => const MyTasksScreen(),
        };
      case 3: // Calendar Tab
        return {
          '/': (context) => const CalendarScreen(),
        };
      default:
        return {'/': (context) => const Center(child: Text('Unknown Tab'))};
    }
  }
} 