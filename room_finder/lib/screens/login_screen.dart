import 'package:flutter/material.dart';
import '../utils/navigation.dart';   
import '../components/custom_styles.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to get user input from text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    // Here you would typically call some auth service, etc.
    // We assume successful login for example:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using SafeArea if you want to avoid status-bar overlap
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),  // Hide keyboard
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo or title
                  const FlutterLogo(size: 72),
                  const SizedBox(height: 24),

                  // Username field
                  TextField(
                    controller: _usernameController,
                    decoration:
                        customInputDecoration(labelText: 'Username'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextField(
                    controller: _passwordController,
                    decoration:
                        customInputDecoration(labelText: 'Password'),
                    obscureText: true,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Login button with same styling as your "Generate" button
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
