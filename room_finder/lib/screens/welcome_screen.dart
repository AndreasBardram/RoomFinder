import 'package:flutter/material.dart';
import '../components/custom_styles.dart';
import '../utils/navigation.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Velkommen',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CustomButtonContainer(
                    child: ElevatedButton(
                      style: customElevatedButtonStyle(),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: Text(
                        'Log ind',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CustomButtonContainer(
                    child: ElevatedButton(
                      style: customElevatedButtonStyle(),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
                      ),
                      child: Text(
                        'Opret profil',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
                  ),
                  child: const Text('Gennemse uden konto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
