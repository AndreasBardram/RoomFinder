import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/custom_error_message.dart';
import '../utils/navigation.dart';
import 'log_in_screen.dart';
import 'create_profile_screen.dart';
import 'welcome_screen.dart';
import 'blocked_users_screen.dart';

const _hairline = Color(0xFFF1F5F9);

const _supportUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSckbsBVAXV8Gzs-MtQhdT19E4vVfmoOw0NrAU7UzBDLebj4nA/viewform';
const _privacyUrl ='https://www.freeprivacypolicy.com/live/106be54b-71ab-4ca5-9790-093088b098bf';
const _termsUrl = 'https://www.freeprivacypolicy.com/live/1399525e-02bf-43d7-acc3-e819576e42d9';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  ButtonStyle get _blackBtn => ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 24, 24, 24),
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );

  ButtonStyle get _outlineBtn => OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: Color(0xFFE6E8EF), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );

  InputDecoration _dialogFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF6F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          content: CustomErrorMessage(message: msg),
        ),
      );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      _toast(context, 'Mangler link.');
      return;
    }
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.inAppBrowserView,
    );
    if (!ok && context.mounted) _toast(context, 'Kunne ikke åbne link.');
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      _noAnimRoute(const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await _confirmDeleteDialog(context);
    if (confirm != true) return;

    try {
      final providerIds = user.providerData.map((p) => p.providerId).toList();

      if (providerIds.contains('password')) {
        final pw = await _askPasswordDialog(context);
        if (pw == null || pw.trim().isEmpty) return;

        final email = user.email;
        if (email == null || email.isEmpty) {
          if (!context.mounted) return;
          _toast(context, 'Mangler email på brugeren.');
          return;
        }

        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: pw.trim()),
        );
      } else {
        if (!context.mounted) return;
        _toast(context, 'Log ind igen for at slette kontoen.');
        return;
      }

      final uid = user.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      await user.delete();
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        _noAnimRoute(const WelcomeScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'wrong-password' => 'Forkert password.',
        'requires-recent-login' => 'Log ind igen og prøv at slette kontoen bagefter.',
        _ => e.message ?? 'Kunne ikke slette kontoen.',
      };
      if (!context.mounted) return;
      _toast(context, msg);
    } catch (_) {
      if (!context.mounted) return;
      _toast(context, 'Kunne ikke slette kontoen.');
    }
  }

  Future<bool?> _confirmDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1AFF0000),
                    ),
                    child: const Icon(
                      FluentIcons.delete_24_regular,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Slet konto',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Er du sikker? Dette sletter din konto permanent.',
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.35),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6E8EF), width: 1),
                ),
                child: const Text(
                  '• Du mister adgang til din profil\n• Handling kan ikke fortrydes',
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: _outlineBtn,
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuller'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: _blackBtn,
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Slet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _askPasswordDialog(BuildContext context) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bekræft med password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Af sikkerhedshensyn skal du indtaste dit password for at slette kontoen.',
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.35),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: c,
                  obscureText: true,
                  cursorColor: Colors.black,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  decoration: _dialogFieldDecoration('Password'),
                  onSubmitted: (_) => Navigator.pop(ctx, c.text),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: _outlineBtn,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuller'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: _blackBtn,
                        onPressed: () => Navigator.pop(ctx, c.text),
                        child: const Text('Fortsæt'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(c.dispose);
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
          label: 'Blokerede brugere',
          icon: FluentIcons.prohibited_24_regular,
          onTap: () => Navigator.push(context, _noAnimRoute(BlockedUsersScreen())),
        ),
      if (loggedIn)
        _SettingItem(
          label: 'Log ud',
          icon: FluentIcons.arrow_exit_20_regular,
          onTap: () => _logout(context),
          chevron: false,
        ),
      if (loggedIn)
        _SettingItem(
          label: 'Slet min bruger',
          icon: FluentIcons.delete_24_regular,
          onTap: () => _deleteAccount(context),
          destructive: true,
          chevron: false,
        ),
    ];

    final legalItems = <_SettingItem>[
      _SettingItem(
        label: 'Support',
        icon: FluentIcons.mail_24_regular,
        onTap: () => _openUrl(context, _supportUrl),
      ),
      _SettingItem(
        label: 'Privatlivspolitik',
        icon: FluentIcons.shield_24_regular,
        onTap: () => _openUrl(context, _privacyUrl),
      ),
      _SettingItem(
        label: 'Vilkår for brug',
        icon: FluentIcons.document_24_regular,
        onTap: () => _openUrl(context, _termsUrl),
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
        currentIndex: 3,
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
            if (i != items.length - 1) const Divider(height: 1, color: _hairline),
          ],
        ],
      ),
    );
  }

  Widget _settingsRow(_SettingItem item) {
    final style = TextStyle(
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
            Icon(
              item.icon,
              size: 18,
              color: item.destructive ? Colors.red[600] : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item.label, style: style)),
            if (item.chevron)
              const Icon(
                FluentIcons.chevron_right_24_regular,
                size: 18,
                color: Colors.black54,
              ),
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
