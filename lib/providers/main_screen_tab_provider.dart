import 'package:flutter/foundation.dart';

class MainScreenTabProvider with ChangeNotifier {
  int _selectedIndex = 0;
  dynamic _navigationArguments;

  int get selectedIndex => _selectedIndex;
  dynamic get navigationArguments => _navigationArguments; // To pass arguments like taskId

  void selectTab(int index, {dynamic arguments}) {
    _selectedIndex = index;
    _navigationArguments = arguments;
    print('[MainScreenTabProvider] Selecting tab: $index with args: $arguments');
    notifyListeners();
  }

  void clearNavigationArguments() {
    _navigationArguments = null;
    print('[MainScreenTabProvider] Cleared navigation arguments.');
    // No need to notifyListeners if only clearing args, unless UI depends on args being null explicitly.
  }
} 