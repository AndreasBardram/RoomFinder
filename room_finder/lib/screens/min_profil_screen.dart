import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_styles.dart';
import '../components/apartment_card.dart';
import '../components/custom_error_message.dart';
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
  String _intent = '';
  bool _editingIntent = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _linkControllers = <String, TextEditingController>{
    'instagram': TextEditingController(),
    'facebook': TextEditingController(),
    'whatsapp': TextEditingController(),
    'website': TextEditingController(),
  };

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _birthDateFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _linkFocus = <String, FocusNode>{
    'instagram': FocusNode(),
    'facebook': FocusNode(),
    'whatsapp': FocusNode(),
    'website': FocusNode(),
  };

  bool _editingFirstName = false;
  bool _editingLastName = false;
  bool _editingBirthDate = false;
  bool _editingPhone = false;
  final _editingLink = <String, bool>{
    'instagram': false,
    'facebook': false,
    'whatsapp': false,
    'website': false,
  };

  String _firstName = '';
  String _lastName = '';
  String _birthDate = '';
  String _phone = '';
  String _email = '';
  String _imageUrl = '';
  int? _age;

  int? _calcAge(String d) {
    final dt = DateTime.tryParse(d);
    if (dt == null) return null;
    final now = DateTime.now();
    var y = now.year - dt.year;
    if (now.month < dt.month || (now.month == dt.month && now.day < dt.day))
      y--;
    return y;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _firstNameFocus.addListener(_firstNameListener);
    _lastNameFocus.addListener(_lastNameListener);
    _birthDateFocus.addListener(_birthDateListener);
    _phoneFocus.addListener(_phoneListener);
    for (final k in _linkFocus.keys) {
      _linkFocus[k]!.addListener(() => _linkListener(k));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _firstNameFocus.removeListener(_firstNameListener);
    _lastNameFocus.removeListener(_lastNameListener);
    _birthDateFocus.removeListener(_birthDateListener);
    _phoneFocus.removeListener(_phoneListener);
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _birthDateFocus.dispose();
    _phoneFocus.dispose();
    for (final k in _linkControllers.keys) {
      _linkControllers[k]!.dispose();
      _linkFocus[k]!.dispose();
    }
    super.dispose();
  }

  void _firstNameListener() {
    final f = _firstNameFocus.hasFocus;
    if (!f && _firstNameController.text.trim().isNotEmpty) {
      _saveField('firstName', _firstNameController.text);
    }
    setState(() => _editingFirstName = f);
  }

  void _lastNameListener() {
    final f = _lastNameFocus.hasFocus;
    if (!f && _lastNameController.text.trim().isNotEmpty) {
      _saveField('lastName', _lastNameController.text);
    }
    setState(() => _editingLastName = f);
  }

  void _birthDateListener() {
    final f = _birthDateFocus.hasFocus;
    if (!f && _birthDateController.text.trim().isNotEmpty) {
      _saveField('birthDate', _birthDateController.text);
    }
    setState(() => _editingBirthDate = f);
  }

  void _phoneListener() {
    final f = _phoneFocus.hasFocus;
    if (!f && _phoneController.text.trim().isNotEmpty) {
      _saveField('phone', _phoneController.text);
    }
    setState(() => _editingPhone = f);
  }

  void _linkListener(String p) {
    final f = _linkFocus[p]!.hasFocus;
    if (!f && _linkControllers[p]!.text.trim().isNotEmpty) {
      _saveField('links.$p', _linkControllers[p]!.text);
    }
    setState(() => _editingLink[p] = f);
  }

  void _showUpdated() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          content: CustomErrorMessage(message: 'Profiloplysninger opdateret'),
        ),
      );
  }

  Future<void> _saveField(String key, String value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    var path = key;
    if (key == 'phone' || key == 'birthDate' || key == 'intent')
      path = 'metadata.$key';
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      path: value.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _loadProfile();
    _showUpdated();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!snap.exists) return;
    final d = snap.data()!;
    final meta = (d['metadata'] as Map<String, dynamic>?) ?? {};
    final links = (d['links'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _firstName = d['firstName'] ?? '';
      _lastName = d['lastName'] ?? '';
      _birthDate = meta['birthDate'] ?? d['birthDate'] ?? '';
      _phone = meta['phone'] ?? d['phone'] ?? '';
      _imageUrl = d['imageUrl'] ?? '';
      _email = user.email ?? '';
      _age = _calcAge(_birthDate);
      _intent = meta['intent']?.toString() ?? '';

      _firstNameController.text = _firstName;
      _lastNameController.text = _lastName;
      _birthDateController.text = _birthDate;
      _phoneController.text = _phone;
      _emailController.text = _email;

      for (final k in _linkControllers.keys) {
        _linkControllers[k]!.text = links[k]?.toString() ?? '';
      }
    });
  }

  Widget _fieldRow({
    required IconData icon,
    required bool editing,
    required FocusNode focusNode,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    if (editing) {
      return Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              keyboardType: keyboardType,
              onSubmitted: (_) => focusNode.unfocus(),
            ),
          ),
        ],
      );
    }
    final display = controller.text.isNotEmpty ? controller.text : '—';
    return InkWell(
      onTap: () => FocusScope.of(context).requestFocus(focusNode),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                display,
                style: TextStyle(
                    fontSize: 16,
                    color: controller.text.isNotEmpty
                        ? Colors.black
                        : Colors.grey[500]),
              ),
            ),
            Icon(FluentIcons.edit_24_regular,
                size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _linkRow(String p, IconData icon, String label) => _fieldRow(
        icon: icon,
        editing: _editingLink[p]!,
        focusNode: _linkFocus[p]!,
        controller: _linkControllers[p]!,
        label: label,
        keyboardType: TextInputType.url,
      );
  String _intentLabel(String v) {
    if (v == 'rent') return 'Jeg vil leje';
    if (v == 'rentOut') return 'Jeg vil udleje';
    return '—';
  }

  Widget _intentRow() {
    if (_editingIntent) {
      return Row(
        children: [
          const Icon(FluentIcons.arrow_swap_24_regular, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Jeg vil leje'),
                  selected: _intent == 'rent',
                  onSelected: (_) {
                    setState(() => _intent = 'rent');
                    _saveField('intent', 'rent');
                    setState(() => _editingIntent = false);
                  },
                ),
                ChoiceChip(
                  label: const Text('Jeg vil udleje'),
                  selected: _intent == 'rentOut',
                  onSelected: (_) {
                    setState(() => _intent = 'rentOut');
                    _saveField('intent', 'rentOut');
                    setState(() => _editingIntent = false);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }
    return InkWell(
      onTap: () => setState(() => _editingIntent = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(FluentIcons.arrow_swap_24_regular, size: 18),
            const SizedBox(width: 12),
            Expanded(
                child: Text(_intentLabel(_intent),
                    style: TextStyle(
                        fontSize: 16,
                        color: _intent.isNotEmpty
                            ? Colors.black
                            : Colors.grey[500]))),
            Icon(FluentIcons.edit_24_regular,
                size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Din profil')),
        body: _loggedOut(context),
      );
    }
    final uid = user.uid;

    final nameAge =
        '${_firstName.isNotEmpty || _lastName.isNotEmpty ? '$_firstName $_lastName' : ''}'
        '${_age != null ? ', $_age år' : ''}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Din profil'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: _imageUrl.isNotEmpty
                        ? Image.network(_imageUrl, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey[300],
                            child: const Center(
                                child: Icon(Icons.person,
                                    size: 60, color: Colors.white)),
                          ),
                  ),
                  if (nameAge.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        nameAge,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _fieldRow(
                      icon: FluentIcons.person_24_regular,
                      editing: _editingFirstName,
                      focusNode: _firstNameFocus,
                      controller: _firstNameController,
                      label: 'Fornavn',
                    ),
                    const Divider(height: 1),
                    _fieldRow(
                      icon: FluentIcons.person_24_regular,
                      editing: _editingLastName,
                      focusNode: _lastNameFocus,
                      controller: _lastNameController,
                      label: 'Efternavn',
                    ),
                    const Divider(height: 1),
                    _fieldRow(
                      icon: FluentIcons.calendar_24_regular,
                      editing: _editingBirthDate,
                      focusNode: _birthDateFocus,
                      controller: _birthDateController,
                      label: 'Fødselsdato (YYYY-MM-DD)',
                      keyboardType: TextInputType.datetime,
                    ),
                    const Divider(height: 1),
                    _fieldRow(
                      icon: FluentIcons.phone_24_regular,
                      editing: _editingPhone,
                      focusNode: _phoneFocus,
                      controller: _phoneController,
                      label: 'Telefonnummer',
                      keyboardType: TextInputType.phone,
                    ),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            _fieldRow(
                              icon: FluentIcons.person_24_regular,
                              editing: _editingFirstName,
                              focusNode: _firstNameFocus,
                              controller: _firstNameController,
                              label: 'Fornavn',
                            ),
                            const Divider(height: 1),
                            _fieldRow(
                              icon: FluentIcons.person_24_regular,
                              editing: _editingLastName,
                              focusNode: _lastNameFocus,
                              controller: _lastNameController,
                              label: 'Efternavn',
                            ),
                            const Divider(height: 1),
                            _fieldRow(
                              icon: FluentIcons.calendar_24_regular,
                              editing: _editingBirthDate,
                              focusNode: _birthDateFocus,
                              controller: _birthDateController,
                              label: 'Fødselsdato (YYYY-MM-DD)',
                              keyboardType: TextInputType.datetime,
                            ),
                            const Divider(height: 1),
                            _fieldRow(
                              icon: FluentIcons.phone_24_regular,
                              editing: _editingPhone,
                              focusNode: _phoneFocus,
                              controller: _phoneController,
                              label: 'Telefonnummer',
                              keyboardType: TextInputType.phone,
                            ),
                            const Divider(height: 1),
                            _intentRow(),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(FluentIcons.mail_24_regular,
                                      size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(_email,
                                          style:
                                              const TextStyle(fontSize: 16))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Icon(FluentIcons.mail_24_regular, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(_email,
                                  style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _linkRow('instagram', FluentIcons.camera_24_regular,
                        'Instagram'),
                    const Divider(height: 1),
                    _linkRow('facebook', FluentIcons.people_team_24_regular,
                        'Facebook'),
                    const Divider(height: 1),
                    _linkRow(
                        'whatsapp', FluentIcons.chat_24_regular, 'WhatsApp'),
                    const Divider(height: 1),
                    _linkRow(
                        'website', FluentIcons.globe_24_regular, 'Website'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 10),
            const Text('Dine opslag',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(DateTime.now()),
              future: FirebaseFirestore.instance
                  .collection('apartments')
                  .where('ownedBy', isEqualTo: uid)
                  .get(),
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
                  final tA =
                      (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                          0;
                  final tB =
                      (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                          0;
                  return tB.compareTo(tA);
                });
                if (docs.isEmpty) {
                  return Column(
                    children: const [
                      Icon(FluentIcons.home_24_regular,
                          size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Ingen aktive opslag.',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  );
                }
                return LayoutBuilder(
                  builder: (ctx, constraints) {
                    const count = 2;
                    const hPad = 8.0;
                    const spacing = 16.0;
                    final w = (constraints.maxWidth -
                            hPad * 2 -
                            spacing * (count - 1)) /
                        count;
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
                        final images = (d['imageUrls'] as List?)
                                ?.whereType<String>()
                                .toList() ??
                            [];
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

  Widget _loggedOut(BuildContext ctx) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: customElevatedButtonStyle(),
                onPressed: () => Navigator.push(ctx,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Log ind'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: customElevatedButtonStyle(),
                onPressed: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                        builder: (_) => const CreateAccountScreen())),
                child: const Text('Opret profil'),
              ),
            ),
          ],
        ),
      );
}
