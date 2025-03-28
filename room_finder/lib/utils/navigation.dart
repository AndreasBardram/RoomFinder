import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../screens/home_screen.dart';
import '../screens/find_roommate_screen.dart';
import '../screens/find_apartment_screen.dart';
import '../screens/setting_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({this.initialIndex = 0, Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;  
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> _buildScreens() {
    return const [
      HomeScreen(),
      FindRoommateScreen(),
      FindApartmentScreen(),
      SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use IndexedStack to keep state in each tab
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),

      // BottomNavigationBar with 4 items
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTabTapped,
        showUnselectedLabels: true,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
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
