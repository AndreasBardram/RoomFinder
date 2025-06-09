import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'settings_screen.dart';
import '../components/custom_styles.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _cityController  = TextEditingController();
  final _priceController = TextEditingController();

  bool _isUploading = false;

  @override
  void dispose() {
    _cityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _createApartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No user logged in.')));
      return;
    }

    final city  = _cityController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (city.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid city and price.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      await FirebaseFirestore.instance.collection('apartments').add({
        'ownedBy': user.uid,
        'city'   : city,
        'price'  : price,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _cityController.clear();
      _priceController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Apartment uploaded!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Apartment Details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                TextField(
                  controller: _cityController,
                  decoration: customInputDecoration(labelText: 'City'),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _priceController,
                  decoration: customInputDecoration(labelText: 'Price (in \$)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),

                CustomButtonContainer(
                  margin: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _createApartment,
                    style: customElevatedButtonStyle(),
                    child: const Text('Upload Apartment'),
                  ),
                ),
              ],
            ),
          ),

          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
