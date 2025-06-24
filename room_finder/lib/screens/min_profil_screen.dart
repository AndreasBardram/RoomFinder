import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_styles.dart';
import 'settings_screen.dart';
import 'log_ind_screen.dart';
import 'create_account_screen.dart';

class ApartmentCard extends StatelessWidget {
  final String city;
  final double price;
  const ApartmentCard({super.key, required this.city, required this.price});
  @override
  Widget build(BuildContext context) {
    return Container(
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
              child: Text(
                city,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '\$${price.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YourProfileScreen extends StatefulWidget {
  const YourProfileScreen({super.key});
  @override
  State<YourProfileScreen> createState() => _YourProfileScreenState();
}

class _YourProfileScreenState extends State<YourProfileScreen> {
  final _firstNameController = TextEditingController();
  final _instagramController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hobbiesController = TextEditingController();
  String _firstName = '';
  int? _age;
  String _hobbies = '';
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _apartmentsFuture = Future.value([]);
  @override
  void initState() {
    super.initState();
    _loadProfile();
    _apartmentsFuture = _fetchApartments();
  }
  @override
  void dispose() {
    _firstNameController.dispose();
    _instagramController.dispose();
    _descriptionController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final d = doc.data();
      setState(() {
        _firstName = d?['firstName'] ?? '';
        _age = d?['age'];
        _hobbies = d?['hobbies'] ?? '';
        _firstNameController.text = _firstName;
        _hobbiesController.text = _hobbies;
      });
    }
  }
  Future<void> _uploadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'firstName': _firstNameController.text.trim(),
      'instagram': _instagramController.text.trim(),
      'description': _descriptionController.text.trim(),
      'hobbies': _hobbiesController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile info uploaded.')));
  }
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchApartments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snap = await FirebaseFirestore.instance.collection('apartments').where('ownedBy', isEqualTo: user.uid).get();
    return snap.docs;
  }
  void _refreshApartments() {
    setState(() => _apartmentsFuture = _fetchApartments());
  }
  Widget _loggedOutBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: CustomButtonContainer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ElevatedButton(
                  style: customElevatedButtonStyle(),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Log ind'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: CustomButtonContainer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ElevatedButton(
                  style: customElevatedButtonStyle(),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
                  child: const Text('Opret profil'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: user == null
          ? _loggedOutBody(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  if (_firstName.isNotEmpty || _age != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$_firstName${_age != null ? ', $_age' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _firstNameController,
                    decoration: customInputDecoration(labelText: 'First Name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _instagramController,
                    decoration: customInputDecoration(labelText: 'Instagram Link'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hobbiesController,
                    decoration: customInputDecoration(labelText: 'Hobbies'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: customInputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _uploadProfile,
                    style: customElevatedButtonStyle(),
                    child: const Text('Upload Profile Info', style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('All Apartments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshApartments),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                    future: _apartmentsFuture,
                    builder: (_, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: CircularProgressIndicator());
                      }
                      if (!snap.hasData || snap.data!.isEmpty) {
                        return Column(
                          children: const [
                            Icon(FluentIcons.home_24_regular, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No apartments available.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        );
                      }
                      final docs = snap.data!;
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
                          final city = d['city'] ?? 'Unknown';
                          final price = (d['price'] ?? 0).toDouble();
                          return ApartmentCard(city: city, price: price);
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
