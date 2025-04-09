import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class YourProfileScreen extends StatefulWidget {
  const YourProfileScreen({Key? key}) : super(key: key);

  @override
  State<YourProfileScreen> createState() => _YourProfileScreenState();
}

class _YourProfileScreenState extends State<YourProfileScreen> {
  /// Uploads basic profile info (currently, just the email address) to Firestore.
  Future<void> _uploadProfile() async {
    // Get the current user from Firebase Auth.
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user is currently logged in.")),
      );
      return;
    }

    // Extract the email; if not available, default to a placeholder text.
    final String email = user.email ?? "No email provided";

    try {
      // Write (or merge) the user's email address and a timestamp to Firestore.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profile Screen Placeholder'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadProfile,
                child: const Text(
                'Upload Profile Info',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                )
            ),
          ],
        ),
      ),
    );
  }
}
