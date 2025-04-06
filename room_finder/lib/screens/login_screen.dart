import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Replace with your actual file paths
import '../utils/navigation.dart';
import '../components/custom_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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

      // Navigate to main screen if successful
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Common sign-in errors (e.g. user not found, wrong password)
      _showMessage('Login failed: ${e.message}');
    } catch (e) {
      // Other unexpected errors
      _showMessage('An unexpected error occurred.');
    }
  }

  /// Create a new account in Firebase Auth, then save to Firestore
  Future<void> _createAccount() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    try {
      // 1) Create the user in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2) Save additional user details in Firestore
      final uid = userCredential.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'createdAt': DateTime.now(),
        });

        _showMessage('Account created! Logging you in...');

        // 3) Navigate to the main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // E.g. email already in use, invalid email format, weak password
      _showMessage('Account creation failed: ${e.message}');
    } catch (e) {
      // Other unexpected errors
      _showMessage('An unexpected error occurred.');
    }
  }

  /// For testing: skip login
  void _skipLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  /// Show a SnackBar with a message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optional background gradient
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
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
                    const SizedBox(height: 16),

                    // Create Account button
                    CustomButtonContainer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: ElevatedButton(
                          style: customElevatedButtonStyle(),
                          onPressed: _createAccount,
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
                    const SizedBox(height: 16),

                    // Skip button for testing
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
