import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_styles.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _socialController = TextEditingController();
  final _bioController = TextEditingController();
  String? _intent;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final d = snap.data() ?? {};
    final meta = (d['metadata'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _firstNameController.text = d['firstName']?.toString() ?? '';
      _lastNameController.text = d['lastName']?.toString() ?? '';
      _birthDateController.text = meta['birthDate']?.toString() ?? d['birthDate']?.toString() ?? '';
      _phoneController.text = meta['phone']?.toString() ?? d['phone']?.toString() ?? '';
      _emailController.text = user.email ?? '';
      _intent = meta['intent']?.toString();
      _socialController.text = meta['social']?.toString() ?? d['social']?.toString() ?? '';
      _bioController.text = meta['bio']?.toString() ?? d['bio']?.toString() ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final updates = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'metadata.birthDate': _birthDateController.text.trim(),
      'metadata.phone': _phoneController.text.trim(),
      'metadata.intent': _intent ?? '',
      'metadata.social': _socialController.text.trim(),
      'metadata.bio': _bioController.text.trim().substring(0, _bioController.text.trim().length.clamp(0, 200)),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil opdateret')));
    Navigator.pop(context, true);
  }

  Widget _field(IconData icon, String label, TextEditingController c, {TextInputType? type, bool readOnly = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: c,
            readOnly: readOnly,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            keyboardType: type,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _socialController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Rediger profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _field(FluentIcons.person_24_regular, 'Fornavn', _firstNameController),
                    const SizedBox(height: 12),
                    _field(FluentIcons.person_24_regular, 'Efternavn', _lastNameController),
                    const SizedBox(height: 12),
                    _field(FluentIcons.calendar_24_regular, 'Fødselsdato (YYYY-MM-DD)', _birthDateController, type: TextInputType.datetime),
                    const SizedBox(height: 12),
                    _field(FluentIcons.phone_24_regular, 'Telefonnummer', _phoneController, type: TextInputType.phone),
                    const SizedBox(height: 12),
                    _field(FluentIcons.mail_24_regular, 'E-mail', _emailController, readOnly: true),
                    const SizedBox(height: 12),
                    _field(FluentIcons.globe_24_regular, 'Social media', _socialController, type: TextInputType.url),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Hvad vil du?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Jeg vil leje'),
                          selected: _intent == 'rent',
                          onSelected: (_) => setState(() => _intent = 'rent'),
                        ),
                        ChoiceChip(
                          label: const Text('Jeg vil udleje'),
                          selected: _intent == 'rentOut',
                          onSelected: (_) => setState(() => _intent = 'rentOut'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(alignment: Alignment.centerLeft, child: Text('Beskrivelse', style: Theme.of(context).textTheme.titleMedium)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      maxLines: 5,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: 'Skriv kort om dig selv (max 200 tegn)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: customElevatedButtonStyle(),
                onPressed: _save,
                child: const Text('Gem ændringer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
