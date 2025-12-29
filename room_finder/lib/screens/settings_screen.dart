import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'log_in_screen.dart';
import 'create_profile_screen.dart';
import 'welcome_screen.dart';
import '../utils/navigation.dart';

const _hairline = Color(0xFFF1F5F9);

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

    final accountItems = <_SettingItem>[
      _SettingItem(
        label: loggedIn ? 'Skift bruger' : 'Log ind',
        icon: FluentIcons.person_24_regular,
        onTap: () => Navigator.push(context, _noAnimRoute(const LoginScreen())),
      ),
      _SettingItem(
        label: 'Opret profil',
        icon: FluentIcons.add_24_regular,
        onTap: () => Navigator.push(context, _noAnimRoute(const CreateAccountScreen())),
      ),
      if (loggedIn)
        _SettingItem(
          label: 'Log ud',
          icon: FluentIcons.arrow_exit_20_regular,
          onTap: () => _logout(context),
          destructive: true,
          chevron: false,
        ),
    ];

    final legalItems = <_SettingItem>[
      _SettingItem(
        label: 'Privatlivspolitik',
        icon: FluentIcons.shield_24_regular,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privatlivspolitik')),
        ),
      ),
      _SettingItem(
        label: 'Vilkår for brug',
        icon: FluentIcons.document_24_regular,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vilkår for brug')),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        title: const Text('Indstillinger'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _hairline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(accountItems),
          const SizedBox(height: 16),
          _buildCard(legalItems),
        ],
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

  Widget _buildCard(List<_SettingItem> items) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _settingsRow(items[i]),
            if (i != items.length - 1)
              const Divider(height: 1, color: _hairline),
          ],
        ],
      ),
    );
  }

  Widget _settingsRow(_SettingItem item) {
    final baseStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: item.destructive ? Colors.red[600] : Colors.black,
    );

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: item.destructive ? Colors.red[600] : Colors.grey[700]),
            const SizedBox(width: 12),
            Expanded(child: Text(item.label, style: baseStyle)),
            if (item.chevron)
              const Icon(FluentIcons.chevron_right_24_regular, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

class _SettingItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  final bool chevron;
  _SettingItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
    this.chevron = true,
  });
}

PageRoute _noAnimRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );
