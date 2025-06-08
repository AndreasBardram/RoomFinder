import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Replace with your actual file paths
import '../utils/navigation.dart';
import '../components/custom_styles.dart';
import 'create_account_screen.dart'; // Import the new account creation screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Log in the user (must already exist in Firebase Auth)
  Future<void> _login() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password.');
      return;
    }

    try {
      // Attempt sign in with Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Navigate to MainScreen with Find Roommates active (initialIndex = 0)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 0)),
      );
    } on FirebaseAuthException catch (e) {
      // Common sign-in errors (e.g. user not found, wrong password)
      _showMessage('Login failed: ${e.message}');
    } catch (e) {
      // Other unexpected errors
      _showMessage('An unexpected error occurred.');
    }
  }

  /// Show a SnackBar with a message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// For testing: skip login
  void _skipLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color now just the primary color
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Hide keyboard on tap
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Email field
                  TextField(
                    controller: _usernameController,
                    decoration: customInputDecoration(labelText: 'Email'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  TextField(
                    controller: _passwordController,
                    decoration: customInputDecoration(labelText: 'Password'),
                    obscureText: true,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  // Buttons aligned horizontally with minimal space
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Log In button
                      CustomButtonContainer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: ElevatedButton(
                            style: customElevatedButtonStyle(),
                            onPressed: _login,
                            child: Text(
                              'Log In',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5), // Minimal space between buttons
                      // Create Account button
                      CustomButtonContainer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: ElevatedButton(
                            style: customElevatedButtonStyle(),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateAccountScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Create Account',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5), // Minimal space between buttons
                      // Skip button
                      CustomButtonContainer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: ElevatedButton(
                            style: customElevatedButtonStyle(),
                            onPressed: _skipLogin,
                            child: Text(
                              'Skip',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
