import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';
import 'welcome_screen.dart';
import '../utils/navigation.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      _noAnimRoute(const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final navColor = Colors.grey[600];

    final items = <_SettingItem>[
      _SettingItem(
        label: loggedIn ? 'Skift bruger' : 'Log ind',
        onTap: () => Navigator.push(context, _noAnimRoute(const LoginScreen())),
      ),
      _SettingItem(
        label: 'Opret profil',
        onTap: () => Navigator.push(context, _noAnimRoute(const CreateAccountScreen())),
      ),
      if (loggedIn)
        _SettingItem(
          label: 'Log ud',
          onTap: () => _logout(context),
        ),
      _SettingItem(
        label: 'Privacy Policy',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy Policy'))),
      ),
      _SettingItem(
        label: 'Terms of Use',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terms of Use'))),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
        title: const Text('Settings'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFEAEAEA)),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _tile(context, item.label, item.onTap);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (i) => Navigator.pushAndRemoveUntil(
          context,
          _noAnimRoute(MainScreen(initialIndex: i)),
          (route) => false,
        ),
        showUnselectedLabels: true,
        selectedItemColor: navColor,
        unselectedItemColor: navColor,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedIconTheme: const IconThemeData(size: 25),
        unselectedIconTheme: const IconThemeData(size: 25),
        items: const [
          BottomNavigationBarItem(icon: Icon(FluentIcons.search_24_regular), label: 'Find Værelse'),
          BottomNavigationBarItem(icon: Icon(FluentIcons.add_24_regular), label: 'Opret'),
          BottomNavigationBarItem(icon: Icon(FluentIcons.chat_24_regular), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(FluentIcons.person_24_regular), label: 'Min Profil'),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          alignment: Alignment.center,
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _SettingItem {
  final String label;
  final VoidCallback onTap;
  _SettingItem({required this.label, required this.onTap});
}

PageRoute _noAnimRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );
