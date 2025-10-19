import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/custom_button.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            customSettingButton(
              context: context,
              label: loggedIn ? 'Skift bruger' : 'Log ind',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
            const SizedBox(height: 4),
            customSettingButton(
              context: context,
              label: 'Opret profil',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAccountScreen()));
              },
            ),
            const SizedBox(height: 4),
            if (loggedIn)
              customSettingButton(
                context: context,
                label: 'Log ud',
                onPressed: () => _logout(context),
              ),
            if (loggedIn) const SizedBox(height: 4),
            customSettingButton(
              context: context,
              label: 'Privacy Policy',
              onPressed: () {},
            ),
            const SizedBox(height: 4),
            customSettingButton(
              context: context,
              label: 'Terms of Use',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
