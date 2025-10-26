import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';

import '../utils/navigation.dart';
import '../components/no_transition.dart';
import 'welcome_screen.dart';

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

  String? _role;
  bool _showForm = false;
  DateTime? _birthDate;

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
    if (d != null) {
      setState(() {
        _birthDate = d;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(d);
      });
    }
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
      await pushReplacementNoAnim(context, const MainScreen(initialIndex: 0));
    } on FirebaseAuthException catch (e) {
      _showMessage('Fejl: ${e.message}');
    } catch (_) {
      _showMessage('Uventet fejl.');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8A93A6), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF6F7FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  ButtonStyle get _primaryBtn => ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );

  Widget _labeled(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        field,
      ],
    );
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: selected ? 2 : 1.5,
            color: selected ? Colors.black : const Color(0xFFE6E8EF),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8A93A6), fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: selected ? 2 : 1.5),
                color: selected ? Colors.black : Colors.transparent,
              ),
              child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rolePicker() {
    final canContinue = _role != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/logo.png', width: 60, height: 60, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Opret profil',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        _optionTile(
          value: 'seeker',
          title: 'Jeg leder efter et værelse',
          subtitle: 'Match med udlejere og find dit hjem',
          icon: Icons.search,
        ),
        const SizedBox(height: 12),
        _optionTile(
          value: 'landlord',
          title: 'Jeg vil udleje et værelse',
          subtitle: 'Opret opslag og find den rette lejer',
          icon: Icons.home_outlined,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Visibility(
            visible: canContinue,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: ElevatedButton(
              style: _primaryBtn,
              onPressed: () => setState(() => _showForm = true),
              child: const Text('Fortsæt'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _labeled(
                'Fornavn',
                TextField(
                  controller: _firstNameController,
                  cursorColor: Colors.black,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  decoration: _fieldDecoration('Anders'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _labeled(
                'Efternavn',
                TextField(
                  controller: _lastNameController,
                  cursorColor: Colors.black,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  decoration: _fieldDecoration('Jensen'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _labeled(
          'Fødselsdato',
          TextField(
            controller: _birthDateController,
            readOnly: true,
            cursorColor: Colors.black,
            onTap: _pickBirthDate,
            decoration: _fieldDecoration('Vælg dato').copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined)),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14, color: Colors.black),
          ),
        ),
        const SizedBox(height: 16),
        _labeled(
          'Telefonnummer',
          TextField(
            controller: _phoneController,
            cursorColor: Colors.black,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: _fieldDecoration('+45 12 34 56 78'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        _labeled(
          'E-mail',
          TextField(
            controller: _emailController,
            cursorColor: Colors.black,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: _fieldDecoration('din@email.dk'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        _labeled(
          'Password',
          TextField(
            controller: _passwordController,
            cursorColor: Colors.black,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _createAccount(),
            autofillHints: const [AutofillHints.newPassword],
            decoration: _fieldDecoration('•••••••'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        _labeled(
          'Profiltype',
          DropdownButtonFormField<String>(
            value: _role,
            isExpanded: true,
            decoration: _fieldDecoration('Finder værelse'),
            items: const [
              DropdownMenuItem(value: 'seeker', child: Text('Finder værelse')),
              DropdownMenuItem(value: 'landlord', child: Text('Udlejer værelse')),
            ],
            onChanged: (v) => setState(() => _role = v),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: _primaryBtn,
            onPressed: _createAccount,
            child: const Text('Opret profil'),
          ),
        ),
      ],
    );
  }

  Future<bool> _handleBack() async {
    if (_showForm) {
      setState(() => _showForm = false);
      return false;
    }
    if (!mounted) return false;
    await pushAndRemoveAllNoAnim(context, const WelcomeScreen());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: Duration.zero,
                  transitionBuilder: (c, _) => c,
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
      ),
    );
  }
}
