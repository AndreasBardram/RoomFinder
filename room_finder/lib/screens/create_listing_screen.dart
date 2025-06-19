import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'settings_screen.dart';
import '../components/custom_styles.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _titleController       = TextEditingController();
  final _cityController        = TextEditingController();
  final _priceController       = TextEditingController();
  final _roommatesController   = TextEditingController();
  final _descriptionController = TextEditingController();

  final _picker  = ImagePicker();
  List<XFile> _images = [];
  bool _isUploading   = false;

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _roommatesController.dispose();
    _descriptionController.dispose();
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
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade600, width: 3),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined, size: 32),
              const SizedBox(height: 8),
              Text(
                hasImages
                    ? '${_images.length} selected • tap to change'
                    : 'Tap to add up to 10 photos',
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
    final ref = FirebaseStorage.instance
        .ref('apartments/$listingId/$index.jpg');

    final snap = await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await snap.ref.getDownloadURL();
  }

  /* ---------------------------- upload flow --------------------------- */

  Future<void> _createApartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No user logged in.')));
      return;
    }

    final title       = _titleController.text.trim();
    final city        = _cityController.text.trim();
    final price       = double.tryParse(_priceController.text.trim());
    final roommates   = int.tryParse(_roommatesController.text.trim());
    final description = _descriptionController.text.trim();

    if (title.isEmpty ||
        city.isEmpty ||
        price == null ||
        roommates == null ||
        description.isEmpty ||
        _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields and select 1–10 photos.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      /* ---- create Firestore doc first ---- */
      final docRef = await FirebaseFirestore.instance
          .collection('apartments')
          .add({
        'ownedBy'    : user.uid,
        'title'      : title,
        'city'       : city,
        'price'      : price,
        'roommates'  : roommates,
        'description': description,
        'createdAt'  : FieldValue.serverTimestamp(),
      });

      /* ---- upload images in parallel ---- */
      final uploadFutures = _images.asMap().entries.map(
        (e) => _uploadImage(
          listingId: docRef.id,
          index: e.key,
          file: e.value,
        ),
      );

      final urls = await Future.wait(uploadFutures);

      /* ---- write URLs back ---- */
      await docRef.update({'imageUrls': urls});

      /* ---- clear UI ---- */
      _titleController.clear();
      _cityController.clear();
      _priceController.clear();
      _roommatesController.clear();
      _descriptionController.clear();
      setState(() => _images = []);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Apartment uploaded!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /* -------------------------------- UI -------------------------------- */

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
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                TextField(
                  controller: _titleController,
                  decoration: customInputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _cityController,
                  decoration:
                      customInputDecoration(labelText: 'Location (City)'),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _priceController,
                  decoration:
                      customInputDecoration(labelText: 'Price (in DKK)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _roommatesController,
                  decoration: customInputDecoration(
                      labelText: 'Number of Roommates'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _descriptionController,
                  decoration: customInputDecoration(labelText: 'Description'),
                  maxLines: 3,
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

                ElevatedButton(
                  onPressed: _isUploading ? null : _createApartment,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Upload Apartment'),
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
