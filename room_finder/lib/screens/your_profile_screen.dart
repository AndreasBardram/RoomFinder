import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/custom_styles.dart'; // Ensure this path is correct.
import 'settings_screen.dart'; // Import the Settings screen

class YourProfileScreen extends StatefulWidget {
  const YourProfileScreen({super.key});

  @override
  State<YourProfileScreen> createState() => _YourProfileScreenState();
}

class _YourProfileScreenState extends State<YourProfileScreen> {
  // Controllers for input fields.
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // NEW: Controller for Hobbies
  final TextEditingController _hobbiesController = TextEditingController();

  // State variables to hold profile info fetched from Firestore.
  String _firstName = '';
  int? _age;
  String _hobbies = ''; // NEW: State variable

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Loads the profile data from Firestore and updates the state.
  Future<void> _loadProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _firstName = data?['firstName'] ?? '';
          _age = data?['age']; // Assumes age is stored as an integer
          _hobbies = data?['hobbies'] ?? ''; // NEW: Load hobbies
          _firstNameController.text = _firstName;
          _hobbiesController.text = _hobbies; // NEW: Pre-fill hobbies field
        });
      }
    } catch (error) {
      print("Failed to load profile: $error");
    }
  }

  /// Uploads profile info (email, first name, Instagram link, description, hobbies) to Firestore.
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
    final String hobbies = _hobbiesController.text.trim(); // NEW

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
        'firstName': firstName,
        'instagram': instagram,
        'description': description,
        'hobbies': hobbies, // NEW
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
    _hobbiesController.dispose(); // NEW
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
              // Navigate to the Settings screen when the settings icon is pressed
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
              // Image placeholder with overlay: a Stack with a CircleAvatar and text.
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
                  // Overlay with user's first name and age (if available)
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
              // Input field for first name.
              TextField(
                controller: _firstNameController,
                decoration: customInputDecoration(labelText: 'First Name'),
              ),
              const SizedBox(height: 16),
              // Input field for Instagram link.
              TextField(
                controller: _instagramController,
                decoration: customInputDecoration(labelText: 'Instagram Link'),
              ),
              const SizedBox(height: 16),
              // NEW: Input field for Hobbies.
              TextField(
                controller: _hobbiesController,
                decoration: customInputDecoration(labelText: 'Hobbies'),
              ),
              const SizedBox(height: 16),
              // Multiline input field for description.
              TextField(
                controller: _descriptionController,
                decoration: customInputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              // Button to trigger the _uploadProfile function.
              ElevatedButton(
                onPressed: _uploadProfile,
                child: const Text(
                  'Upload Profile Info',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
