import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../components/custom_styles.dart';
import '../utils/navigation.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _createAccount() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final birthDate = _birthDateController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if ([firstName, lastName, birthDate, phone, email, password].any((e) => e.isEmpty)) {
      _showMessage('Udfyld alle felter.');
      return;
    }
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      await FirebaseChatCore.instance.createUserInFirestore(
        types.User(
          id: uid,
          firstName: firstName,
          lastName: lastName,
          metadata: {
            'phone': phone,
            'birthDate': birthDate,
            'email': email,
          },
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)));
    } on FirebaseAuthException catch (e) {
      _showMessage('Fejl: ${e.message}');
    } catch (_) {
      _showMessage('Uventet fejl.');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstNameController,
                          decoration: customInputDecoration(labelText: 'Fornavn'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _lastNameController,
                          decoration: customInputDecoration(labelText: 'Efternavn'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _birthDateController,
                    decoration: customInputDecoration(labelText: 'Fødselsdato (YYYY-MM-DD)'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: customInputDecoration(labelText: 'Telefonnummer'),
                    keyboardType: TextInputType.phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: customInputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: customInputDecoration(labelText: 'Password'),
                    obscureText: true,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButtonContainer(
                      child: ElevatedButton(
                        style: customElevatedButtonStyle(),
                        onPressed: _createAccount,
                        child: Text(
                          'Opret profil',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16),
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
