import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../screens/find_roommates_screen.dart';
import '../screens/your_profile_screen.dart';
import '../screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  // Set initialIndex to 1 so that the "Find Roommates" tab (middle) is active upon login.
  const MainScreen({Key? key, this.initialIndex = 1}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  /// Returns the list of screens for the bottom navigation bar.
  List<Widget> _buildScreens() {
    return const [
      SettingsScreen(),       // Index 0: Settings (swapped position)
      FindRoommatesScreen(),   // Index 1: Find Roommates
      YourProfileScreen(),     // Index 2: Profile (swapped position)
    ];
  }

  /// Handle bottom nav item taps
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Optional function to show/hide a loading overlay
  void setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a Stack to allow overlaying a loading indicator.
      body: Stack(
        children: [
          // Preserve the state of each screen using an IndexedStack.
          IndexedStack(
            index: _currentIndex,
            children: _buildScreens(),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
      // Bottom navigation bar (hidden when loading).
      bottomNavigationBar: _isLoading
          ? const SizedBox.shrink()
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: onTabTapped,
              showUnselectedLabels: true,
              selectedItemColor: Colors.grey[1000],
              unselectedItemColor: Colors.grey[600],
              selectedIconTheme: const IconThemeData(size: 25),
              unselectedIconTheme: const IconThemeData(size: 25),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.settings_24_regular),
                  label: 'Settings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.search_24_regular),
                  label: 'Find Roommates',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.person_24_regular),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
