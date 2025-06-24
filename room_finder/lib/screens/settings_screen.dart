import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/custom_button.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
            const SizedBox(height: 4),
            customSettingButton(
              context: context,
              label: 'Opret profil',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
                );
              },
            ),
            const SizedBox(height: 4),
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
