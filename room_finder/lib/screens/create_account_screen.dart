import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_styles.dart';
import '../utils/navigation.dart'; // For navigating to MainScreen after creation

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Creates a new account with extra details and saves them to Firestore.
  Future<void> _createAccount() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String ageText = _ageController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        ageText.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showMessage("Please fill in all fields.");
      return;
    }

    // Validate age
    int? age = int.tryParse(ageText);
    if (age == null) {
      _showMessage("Please enter a valid age.");
      return;
    }

    try {
      // 1) Create the user in Firebase Auth.
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2) Save additional user details in Firestore.
      final uid = userCredential.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'age': age,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _showMessage('Account created successfully!');
        // 3) Navigate to the MainScreen (with Find Roommates active).
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const MainScreen(initialIndex: 1)),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showMessage('Account creation failed: ${e.message}');
    } catch (e) {
      _showMessage('An unexpected error occurred.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            TextField(
              controller: _firstNameController,
              decoration: customInputDecoration(labelText: 'First Name'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: customInputDecoration(labelText: 'Last Name'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              decoration: customInputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: customInputDecoration(labelText: 'Email'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }
}
