import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../components/custom_styles.dart';
import 'settings_screen.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController    = TextEditingController();
  final _priceController       = TextEditingController();
  final _roommatesController   = TextEditingController();
  final _periodController      = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _roommatesController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  /* --------------------------- image picker --------------------------- */

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    if (picked.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 10 photos.')),
      );
      return;
    }
    setState(() => _images = picked);
  }

  Widget _imagePickerButton() {
    final hasImages = _images.isNotEmpty;
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined, size: 32),
              const SizedBox(height: 8),
              Text(
                hasImages
                    ? '${_images.length} billede(r) valgt – tryk for at ændre'
                    : 'Tryk for at tilføje op til 10 billeder',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ------------------------- single image upload ---------------------- */

  Future<String> _uploadImage({
    required String listingId,
    required int index,
    required XFile file,
  }) async {
    final ref =
        FirebaseStorage.instance.ref('apartments/$listingId/$index.jpg');
    final snap = await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await snap.ref.getDownloadURL();
  }

  /* ---------------------------- upload flow --------------------------- */

  Future<void> _createApartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title       = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location    = _locationController.text.trim();
    final price       = double.tryParse(_priceController.text.trim());
    final roommates   = int.tryParse(_roommatesController.text.trim());
    final period      = _periodController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        location.isEmpty ||
        price == null ||
        roommates == null ||
        period.isEmpty ||
        _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Udfyld alle felter og vælg 1-10 billeder.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('apartments')
          .add({
        'ownedBy'    : user.uid,
        'title'      : title,
        'description': description,
        'location'   : location,
        'price'      : price,
        'roommates'  : roommates,
        'period'     : period,
        'createdAt'  : FieldValue.serverTimestamp(),
      });

      final uploads = _images.asMap().entries.map(
        (e) => _uploadImage(
          listingId: docRef.id,
          index: e.key,
          file: e.value,
        ),
      );
      final urls = await Future.wait(uploads);
      await docRef.update({'imageUrls': urls});

      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _priceController.clear();
      _roommatesController.clear();
      _periodController.clear();
      setState(() => _images = []);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lejeopslag gemt!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fejl under upload: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /* -------------------  Logged-out placeholder ------------------------ */

  Widget _loggedOutBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: CustomButtonContainer(
              child: ElevatedButton(
                style: customElevatedButtonStyle(),
                onPressed: () => Navigator.push(
                  context,
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
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
                ),
                child: const Text('Opret profil'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------- UI -------------------------------- */

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
      body: user == null
          ? _loggedOutBody(context)
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Detaljer',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        decoration: customInputDecoration(labelText: 'Titel'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration:
                            customInputDecoration(labelText: 'Beskrivelse'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _locationController,
                        decoration:
                            customInputDecoration(labelText: 'Lokation'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _priceController,
                        decoration:
                            customInputDecoration(labelText: 'Leje (DKK)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _roommatesController,
                        decoration: customInputDecoration(
                            labelText: 'Antal roommates'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _periodController,
                        decoration:
                            customInputDecoration(labelText: 'Periode'),
                      ),
                      const SizedBox(height: 24),
                      _imagePickerButton(),
                      const SizedBox(height: 16),
                      if (_images.isNotEmpty)
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_images[i].path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButtonContainer(
                          child: ElevatedButton(
                            style: customElevatedButtonStyle(),
                            onPressed: _isUploading ? null : _createApartment,
                            child: const Text('Upload lejlighed'),
                          ),
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
