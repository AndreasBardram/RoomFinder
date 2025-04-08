import 'package:flutter/material.dart';
import '../components/custom_button.dart'; // import your customSettingButton

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example layout matching your old style:
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
              label: 'Your Profile',
              onPressed: () {
                // Optionally show a dialog:
                // showDialog(
                //   context: context,
                //   builder: (_) => const CustomYourProfileDialog(),
                // );
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
            const SizedBox(height: 4),
            customSettingButton(
              context: context,
              label: 'Restore Purchase',
              onPressed: () {},
            ),
            const SizedBox(height: 4),
            customSettingButton(
              context: context,
              label: 'Upgrade to Premium',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
