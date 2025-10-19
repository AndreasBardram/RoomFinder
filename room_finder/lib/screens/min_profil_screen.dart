import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_styles.dart';
import '../components/custom_error_message.dart';
import 'settings_screen.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';

class YourProfileScreen extends StatefulWidget {
  const YourProfileScreen({super.key});
  @override
  State<YourProfileScreen> createState() => _YourProfileScreenState();
}

class _YourProfileScreenState extends State<YourProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController     = TextEditingController();
  final _emailController     = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus  = FocusNode();
  final _birthDateFocus = FocusNode();
  final _phoneFocus     = FocusNode();

  bool _editingFirstName = false;
  bool _editingLastName  = false;
  bool _editingBirthDate = false;
  bool _editingPhone     = false;

  String _firstName = '';
  String _lastName  = '';
  String _birthDate = '';
  String _phone     = '';
  String _email     = '';
  String _imageUrl  = '';
  int?   _age;

  int? _calcAge(String d) {
    final dt = DateTime.tryParse(d);
    if (dt == null) return null;
    final now = DateTime.now();
    var y = now.year - dt.year;
    if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) y--;
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
    if (key == 'phone' || key == 'birthDate') path = 'metadata.$key';
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
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!snap.exists) return;
    final d = snap.data()!;
    final meta = (d['metadata'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _firstName  = d['firstName']  ?? '';
      _lastName   = d['lastName']   ?? '';
      _birthDate  = meta['birthDate'] ?? d['birthDate'] ?? '';
      _phone      = meta['phone']     ?? d['phone']     ?? '';
      _imageUrl   = d['imageUrl']     ?? '';
      _email      = user.email ?? '';
      _age        = _calcAge(_birthDate);

      _firstNameController.text = _firstName;
      _lastNameController.text  = _lastName;
      _birthDateController.text = _birthDate;
      _phoneController.text     = _phone;
      _emailController.text     = _email;
    });
  }

  InputDecoration _editDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF6F7FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _fieldRow({
    required IconData icon,
    required bool editing,
    required FocusNode focusNode,
    required TextEditingController controller,
    required String label,
    String hint = '',
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
              keyboardType: keyboardType,
              cursorColor: Colors.black,
              decoration: _editDecoration(label, hint),
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
                style: TextStyle(fontSize: 16, color: controller.text.isNotEmpty ? Colors.black : Colors.grey[500]),
              ),
            ),
            Icon(FluentIcons.edit_24_regular, size: 18, color: Colors.grey[600]),
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: const Text('Din profil'),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
        ),
        body: _loggedOut(context),
      );
    }

    final nameAge = '${_firstName.isNotEmpty || _lastName.isNotEmpty ? '$_firstName $_lastName' : ''}'
        '${_age != null ? ', $_age år' : ''}';

    final themed = Theme.of(context).copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.black,
        selectionHandleColor: Colors.black,
        selectionColor: Color(0x33000000),
      ),
    );

    return Theme(
      data: themed,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
          title: const Text('Din profil'),
          actions: [
            IconButton(
              icon: const Icon(FluentIcons.settings_24_regular),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
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
                  children: [
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: _imageUrl.isNotEmpty
                          ? Image.network(_imageUrl, fit: BoxFit.cover)
                          : Container(color: const Color(0xFFE5E7EB), child: const Center(child: Icon(Icons.person, size: 56, color: Colors.white))),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          height: 56,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0x88000000)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (nameAge.trim().isNotEmpty)
                      Positioned(
                        left: 16,
                        bottom: 12,
                        child: Text(
                          nameAge,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _fieldRow(
                        icon: FluentIcons.person_24_regular,
                        editing: _editingFirstName,
                        focusNode: _firstNameFocus,
                        controller: _firstNameController,
                        label: 'Fornavn',
                        hint: 'Anders',
                      ),
                      const Divider(height: 1),
                      _fieldRow(
                        icon: FluentIcons.person_24_regular,
                        editing: _editingLastName,
                        focusNode: _lastNameFocus,
                        controller: _lastNameController,
                        label: 'Efternavn',
                        hint: 'Jensen',
                      ),
                      const Divider(height: 1),
                      _fieldRow(
                        icon: FluentIcons.calendar_24_regular,
                        editing: _editingBirthDate,
                        focusNode: _birthDateFocus,
                        controller: _birthDateController,
                        label: 'Fødselsdato',
                        hint: '1998-05-15',
                        keyboardType: TextInputType.datetime,
                      ),
                      const Divider(height: 1),
                      _fieldRow(
                        icon: FluentIcons.phone_24_regular,
                        editing: _editingPhone,
                        focusNode: _phoneFocus,
                        controller: _phoneController,
                        label: 'Telefonnummer',
                        hint: '+45 12 34 56 78',
                        keyboardType: TextInputType.phone,
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Icon(FluentIcons.mail_24_regular, size: 18),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_email, style: const TextStyle(fontSize: 16))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Log ind'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: customElevatedButtonStyle(),
                onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
                child: const Text('Opret profil'),
              ),
            ),
          ],
        ),
      );
}
