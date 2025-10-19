import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _role;
  bool _showForm = false;
  DateTime? _birthDate;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      helpText: 'Vælg fødselsdato',
      cancelText: 'Annuller',
      confirmText: 'OK',
    );
    if (d != null) setState(() => _birthDate = d);
  }

  Future<void> _createAccount() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (_role == null) {
      _showMessage('Vælg profiltype.');
      return;
    }
    if ([firstName, lastName, phone, email, password].any((e) => e.isEmpty) || _birthDate == null) {
      _showMessage('Udfyld alle felter.');
      return;
    }
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      final birthDateStr = DateFormat('yyyy-MM-dd').format(_birthDate!);
      await FirebaseChatCore.instance.createUserInFirestore(
        types.User(
          id: uid,
          firstName: firstName,
          lastName: lastName,
          role: types.Role.user,
          metadata: {
            'phone': phone,
            'birthDate': birthDateStr,
            'email': email,
            'profileType': _role,
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
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _optionTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _role == value;
    return InkWell(
      onTap: () => setState(() => _role = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(width: 2, color: selected ? Colors.black : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _rolePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hvordan vil du bruge RoomMatch?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _optionTile(
          value: 'seeker',
          title: 'Jeg leder efter et værelse',
          subtitle: 'Match med udlejere og find dit nye hjem',
          icon: Icons.search,
        ),
        const SizedBox(height: 12),
        _optionTile(
          value: 'landlord',
          title: 'Jeg vil udleje et værelse',
          subtitle: 'Opret opslag og find den rette lejer',
          icon: Icons.home_work_outlined,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CustomButtonContainer(
            child: ElevatedButton(
              style: customElevatedButtonStyle(),
              onPressed: _role == null ? null : () => setState(() => _showForm = true),
              child: Text('Fortsæt', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form() {
    return Column(
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
        InkWell(
          onTap: _pickBirthDate,
          child: InputDecorator(
            decoration: customInputDecoration(labelText: 'Fødselsdato'),
            child: Text(
              _birthDate == null ? 'Vælg dato' : DateFormat('yyyy-MM-dd').format(_birthDate!),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
          ),
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
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _role,
          decoration: customInputDecoration(labelText: 'Profiltype'),
          items: const [
            DropdownMenuItem(value: 'seeker', child: Text('Finder værelse')),
            DropdownMenuItem(value: 'landlord', child: Text('Udlejer værelse')),
          ],
          onChanged: (v) => setState(() => _role = v),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: CustomButtonContainer(
            child: ElevatedButton(
              style: customElevatedButtonStyle(),
              onPressed: _createAccount,
              child: Text('Opret profil', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                child: Column(
                  key: ValueKey(_showForm),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_showForm) _rolePicker(),
                    if (_showForm) _form(),
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
