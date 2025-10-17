import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_styles.dart';
import '../components/apartment_card.dart';
import 'settings_screen.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';

class YourProfileScreen extends StatefulWidget {
  const YourProfileScreen({super.key});
  @override
  State<YourProfileScreen> createState() => _YourProfileScreenState();
}

class _YourProfileScreenState extends State<YourProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _birthDateFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _editingFirstName = false;
  bool _editingLastName = false;
  bool _editingBirthDate = false;
  bool _editingPhone = false;

  String _firstName = '';
  String _lastName = '';
  String _birthDate = '';
  String _phone = '';
  String _email = '';
  int? _age;

  int? _calcAge(String d) {
    final dt = DateTime.tryParse(d);
    if (dt == null) return null;
    final n = DateTime.now();
    var y = n.year - dt.year;
    if (n.month < dt.month || (n.month == dt.month && n.day < dt.day)) y--;
    return y;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _firstNameFocus.addListener(() {
      setState(() => _editingFirstName = _firstNameFocus.hasFocus);
    });
    _lastNameFocus.addListener(() {
      setState(() => _editingLastName = _lastNameFocus.hasFocus);
    });
    _birthDateFocus.addListener(() {
      setState(() => _editingBirthDate = _birthDateFocus.hasFocus);
    });
    _phoneFocus.addListener(() {
      setState(() => _editingPhone = _phoneFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _birthDateFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
    if (!snap.exists) return;
    final d = snap.data()!;
    setState(() {
      _firstName = d['firstName'] ?? '';
      _lastName = d['lastName'] ?? '';
      _birthDate = d['birthDate'] ?? '';
      _phone = d['phone'] ?? '';
      _email = u.email ?? '';
      _age = _calcAge(_birthDate);
      _firstNameController.text = _firstName;
      _lastNameController.text = _lastName;
      _birthDateController.text = _birthDate;
      _phoneController.text = _phone;
      _emailController.text = _email;
    });
  }

  Future<void> _saveProfile() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'birthDate': _birthDateController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': u.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _loadProfile();
  }

  Widget _loggedOut(BuildContext ctx) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 200,
        child: CustomButtonContainer(
          child: ElevatedButton(
            style: customElevatedButtonStyle(),
            onPressed: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text('Log ind'),
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: 200,
        child: CustomButtonContainer(
          child: ElevatedButton(
            style: customElevatedButtonStyle(),
            onPressed: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
            ),
            child: const Text('Opret profil'),
          ),
        ),
      ),
    ],
  ),
);

  Widget _buildField({
    required IconData icon,
    required bool editing,
    required FocusNode focusNode,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    if (editing) {
      return TextField(
        focusNode: focusNode,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        keyboardType: keyboardType,
        onSubmitted: (_) => focusNode.unfocus(),
      );
    } else {
      final display = controller.text.isNotEmpty ? controller.text : '—';
      return ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(
          display,
          style: TextStyle(fontSize: 16, color: controller.text.isNotEmpty ? Colors.black : Colors.grey[500]),
        ),
        trailing: const Icon(FluentIcons.edit_24_regular, size: 20, color: Colors.grey),
        onTap: () => FocusScope.of(context).requestFocus(focusNode),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Din profil')),
        body: _loggedOut(context),
      );
    }
    final uid = u.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Din profil'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            if (_firstName.isNotEmpty || _lastName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$_firstName $_lastName${_age != null ? ', $_age år' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(.15), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildField(
                      icon: FluentIcons.person_24_regular,
                      editing: _editingFirstName,
                      focusNode: _firstNameFocus,
                      controller: _firstNameController,
                      label: 'Fornavn',
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildField(
                      icon: FluentIcons.person_24_regular,
                      editing: _editingLastName,
                      focusNode: _lastNameFocus,
                      controller: _lastNameController,
                      label: 'Efternavn',
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildField(
                      icon: FluentIcons.calendar_24_regular,
                      editing: _editingBirthDate,
                      focusNode: _birthDateFocus,
                      controller: _birthDateController,
                      label: 'Fødselsdato (YYYY-MM-DD)',
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildField(
                      icon: FluentIcons.phone_24_regular,
                      editing: _editingPhone,
                      focusNode: _phoneFocus,
                      controller: _phoneController,
                      label: 'Telefonnummer',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(FluentIcons.mail_24_regular),
                    title: Text(_email, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: customElevatedButtonStyle(),
                onPressed: _saveProfile,
                child: const Text('Gem ændringer'),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 10),
            const Text('Dine opslag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(DateTime.now()),
              future: FirebaseFirestore.instance.collection('apartments').where('ownedBy', isEqualTo: uid).get(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text('Fejl: ${snap.error}'),
                  );
                }
                final docs = snap.data?.docs ?? [];
                docs.sort((a, b) {
                  final tA = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  final tB = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  return tB.compareTo(tA);
                });
                if (docs.isEmpty) {
                  return Column(
                    children: const [
                      Icon(FluentIcons.home_24_regular, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Ingen aktive opslag.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  );
                }
                return LayoutBuilder(
                  builder: (ctx, constraints) {
                    const count = 2;
                    const hPad = 8.0;
                    const spacing = 16.0;
                    final w = (constraints.maxWidth - hPad * 2 - spacing * (count - 1)) / count;
                    final h = w + 124;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        mainAxisExtent: h,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d = docs[i].data();
                        final images = (d['imageUrls'] as List?)?.whereType<String>().toList() ?? [];
                        return ApartmentCard(
                          images: images,
                          title: d['title'] ?? '',
                          location: d['location'] ?? 'Ukendt',
                          price: d['price'] ?? 0,
                          size: (d['size'] ?? 0).toDouble(),
                          period: d['period'] ?? '',
                          roommates: (d['roommates'] ?? 0) as int,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
