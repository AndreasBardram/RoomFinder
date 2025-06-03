import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_styles.dart';
import 'settings_screen.dart';

class YourProfileScreen extends StatefulWidget {
  const YourProfileScreen({super.key});

  @override
  State<YourProfileScreen> createState() => _YourProfileScreenState();
}

class _YourProfileScreenState extends State<YourProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hobbiesController = TextEditingController();

  String _firstName = '';
  int? _age;
  String _hobbies = '';
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _firstName = data?['firstName'] ?? '';
          _age = data?['age'];
          _hobbies = data?['hobbies'] ?? '';
          _firstNameController.text = _firstName;
          _hobbiesController.text = _hobbies;
          _reviews = reviewsSnapshot.docs.map((doc) => doc.data()).toList();
        });
      }
    } catch (error) {
      print("Failed to load profile: $error");
    }
  }

  Future<void> _uploadProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user is currently logged in.")),
      );
      return;
    }

    final String email = user.email ?? "No email provided";
    final String firstName = _firstNameController.text.trim();
    final String instagram = _instagramController.text.trim();
    final String description = _descriptionController.text.trim();
    final String hobbies = _hobbiesController.text.trim();

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
        'firstName': firstName,
        'instagram': instagram,
        'description': description,
        'hobbies': hobbies,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile info uploaded successfully.")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload profile: $error")),
      );
      print("Failed to upload profile: $error");
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _instagramController.dispose();
    _descriptionController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  if (_firstName.isNotEmpty || _age != null)
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: Colors.white.withOpacity(0.7),
                        child: Text(
                          "$_firstName${_age != null ? ', $_age' : ''}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
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
                child: const Text(
                  'Upload Profile Info',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _reviews.isEmpty
                  ? Column(
                      children: const [
                        Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No reviews yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        final name = review['reviewerName'] ?? 'Anonymous';
                        final comment = review['comment'] ?? '';
                        final timestamp = review['timestamp']?.toDate();
                        final dateString = timestamp != null
                            ? '${timestamp.month}/${timestamp.day}/${timestamp.year}'
                            : '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment),
                                if (dateString.isNotEmpty)
                                  Text(
                                    dateString,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
