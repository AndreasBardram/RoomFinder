import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_styles.dart';
import 'settings_screen.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';

class ApartmentCard extends StatelessWidget {
  final String location;
  final double price;
  const ApartmentCard({super.key, required this.location, required this.price});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            children: [
              Container(
                color: Colors.grey[200],
                height: 100,
                child: const Center(child: Icon(Icons.image, size: 50)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(location,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('DKK ${price.toStringAsFixed(0)}',
                    style:
                        const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
}

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
  }

  Future<void> _loadProfile() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      debugPrint('[profile] no user');
      return;
    }
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
    if (!snap.exists) {
      debugPrint('[profile] doc not found');
      return;
    }
    final d = snap.data()!;
    debugPrint('[profile] loaded: $d');
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
                  onPressed: () =>
                      Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LoginScreen())),
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
                      ctx, MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
                  child: const Text('Opret profil'),
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      return Scaffold(appBar: AppBar(title: const Text('Din profil')), body: _loggedOut(context));
    }
    final uid = u.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Din profil'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
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
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameController,
                    decoration: customInputDecoration(labelText: 'Fornavn'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    decoration: customInputDecoration(labelText: 'Efternavn'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _birthDateController,
              decoration: customInputDecoration(labelText: 'Fødselsdato (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: customInputDecoration(labelText: 'Telefonnummer'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: customInputDecoration(labelText: 'E-mail'),
              enabled: false,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CustomButtonContainer(
                child: ElevatedButton(
                  style: customElevatedButtonStyle(),
                  onPressed: _saveProfile,
                  child: const Text('Gem ændringer'),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Dine opslag',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(DateTime.now()),
              future: FirebaseFirestore.instance
                  .collection('apartments')
                  .where('ownedBy', isEqualTo: uid)
                  .get(),
              builder: (_, snap) {
                debugPrint('[future] state=${snap.connectionState} error=${snap.error}');
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
                debugPrint('[future] docs=${docs.length}');
                docs.sort((a, b) {
                  final tA = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  final tB = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  return tB.compareTo(tA);
                });
                for (var d in docs) {
                  debugPrint('[future] doc=${d.id} ownedBy=${d['ownedBy']} location=${d['location']}');
                }
                if (docs.isEmpty) {
                  return Column(
                    children: const [
                      Icon(FluentIcons.home_24_regular, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Ingen aktive opslag.',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final loc = d['location'] ?? 'Ukendt';
                    final prc = (d['price'] ?? 0).toDouble();
                    return ApartmentCard(location: loc, price: prc);
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
