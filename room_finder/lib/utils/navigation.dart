import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import '../screens/find_roommates_screen.dart';
import '../screens/create_listing_screen.dart';
import '../screens/chat_screen.dart';     
import '../screens/your_profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  // By default, keep "Find Roommates" selected on login.
  const MainScreen({super.key, this.initialIndex = 0});

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

  /// Screens shown in the bottom navigation bar.
  List<Widget> _buildScreens() {
    return const [
      FindRoommatesScreen(),   // Index 0
      CreateListingScreen(),   // Index 1
      ChatScreen(),            // Index 2 
      YourProfileScreen(),     // Index 3
    ];
  }

  /// Handle bottom-nav taps.
  void onTabTapped(int index) => setState(() => _currentIndex = index);

  /// Optional loading overlay.
  void setLoading(bool loading) => setState(() => _isLoading = loading);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _buildScreens(),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
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
                  icon: Icon(FluentIcons.search_24_regular),
                  label: 'Find Roommates',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.add_24_regular),
                  label: 'Create Listing',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FluentIcons.chat_24_regular), // NEW item
                  label: 'Chat',
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
