import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../screens/home_screen.dart';
import '../screens/find_roommate_screen.dart';
import '../screens/find_apartment_screen.dart';
import '../screens/setting_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

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

  /// List of pages for each bottom nav item
  List<Widget> _buildScreens() {
    return const [
      HomeScreen(),
      FindRoommateScreen(),
      FindApartmentScreen(),
      SettingsScreen(),
    ];
  }

  /// Handle tab presses
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Optional function to show/hide loading overlay
  void setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A Stack so we can overlay a loading screen if needed
      body: Stack(
        children: [
          // Keep each page's state with an IndexedStack
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
      // Show BottomNavigationBar unless loading is active
      bottomNavigationBar: _isLoading
          ? const SizedBox.shrink()
          : BottomNavigationBar(
              // Use fixed type so icons/labels don’t shift or resize
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: onTabTapped,
              showUnselectedLabels: true,
              selectedItemColor: Colors.grey[1000],
              unselectedItemColor: Colors.grey[600],

              // Force both selected & unselected icons to the same size
              selectedIconTheme: const IconThemeData(size: 25),
              unselectedIconTheme: const IconThemeData(size: 25),

              items: const [
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.home_24_regular),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.people_24_regular),
                  label: 'Roommate',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.building_home_24_regular),
                  label: 'Apartment',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.settings_24_regular),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}
