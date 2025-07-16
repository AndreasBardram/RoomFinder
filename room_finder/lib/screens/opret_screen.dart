import 'dart:io';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../components/custom_styles.dart';
import '../components/custom_error_message.dart';
import '../components/postcode_enter_field.dart';
import 'settings_screen.dart';
import 'log_ind_screen.dart';
import 'opret_profil_screen.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});
  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _periodController = TextEditingController();
  final _roommatesController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  bool _isUploading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _periodController.dispose();
    _roommatesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showError(String m, {Duration d = const Duration(seconds: 5)}) {
    setState(() => _errorMsg = m);
    Future.delayed(d, () {
      if (!mounted) return;
      if (_errorMsg == m) setState(() => _errorMsg = null);
    });
  }

  bool _fail(String m) {
    _showError(m);
    return false;
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final loc = _locationController.text.trim();
    final addr = _addressController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final size = double.tryParse(_sizeController.text.trim());
    final per = _periodController.text.trim();
    final perNum = int.tryParse(per);
    final mate = int.tryParse(_roommatesController.text.trim());
    final desc = _descriptionController.text.trim();
    if (title.isEmpty || title.length > 100) return _fail('Titel skal udfyldes (max 100 tegn).');
    if (loc.isEmpty) return _fail('Vælg postnummer.');
    if (addr.isEmpty) return _fail('Adresse skal udfyldes.');
    if (price == null || price < 0 || price > 100000) return _fail('Pris: 0-100 000 DKK.');
    if (size == null || size < 1 || size > 1000) return _fail('Størrelse: 1-1 000 m².');
    final perOk = per.toLowerCase() == 'ubegrænset' || (perNum != null && perNum >= 1 && perNum <= 100);
    if (!perOk) return _fail('Periode: "ubegrænset" eller 1-100 måneder.');
    if (mate == null || mate < 1 || mate > 10) return _fail('Roommates: 1-10.');
    if (desc.isEmpty || desc.length > 1000) return _fail('Beskrivelse skal udfyldes (max 1000 tegn).');
    setState(() => _errorMsg = null);
    return true;
  }

  Future<void> _pickImages() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 85);
    if (imgs.length > 10) {
      _showError('Max 10 photos.');
      return;
    }
    setState(() => _images = imgs);
  }

  Widget _imagePickerButton() {
    final has = _images.isNotEmpty;
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
          child: has
              ? Text('${_images.length} billede(r) valgt – tryk for at ændre')
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.image, size: 32, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Tryk for at tilføje op til 10 billeder (valgfrit)'),
                  ],
                ),
        ),
      ),
    );
  }

  Future<String> _uploadImage({
    required String listingId,
    required int index,
    required XFile file,
  }) async {
    final ref = FirebaseStorage.instance.ref('apartments/$listingId/$index.jpg');
    final snap = await ref.putFile(File(file.path), SettableMetadata(contentType: 'image/jpeg'));
    return await snap.ref.getDownloadURL();
  }

  Future<void> _createApartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!_validate()) return;
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final address = _addressController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final size = double.parse(_sizeController.text.trim());
    final period = _periodController.text.trim();
    final roommates = int.parse(_roommatesController.text.trim());
    final description = _descriptionController.text.trim();
    setState(() => _isUploading = true);
    try {
      final ownerSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final owner = ownerSnap.data() ?? {};
      final docRef = await FirebaseFirestore.instance.collection('apartments').add({
        'ownedBy': user.uid,
        'ownerFirstName': owner['firstName'] ?? '',
        'ownerLastName': owner['lastName'] ?? '',
        'title': title,
        'location': location,
        'address': address,
        'price': price,
        'size': size,
        'period': period,
        'roommates': roommates,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (_images.isNotEmpty) {
        final urls = await Future.wait(_images.asMap().entries.map(
          (e) => _uploadImage(listingId: docRef.id, index: e.key, file: e.value),
        ));
        await docRef.update({'imageUrls': urls});
      }
      _titleController.clear();
      _locationController.clear();
      _addressController.clear();
      _priceController.clear();
      _sizeController.clear();
      _periodController.clear();
      _roommatesController.clear();
      _descriptionController.clear();
      setState(() => _images = []);
      _showError('Opslag gemt!');
    } catch (e) {
      _showError('Fejl under upload: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

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
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
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
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
                child: const Text('Opret profil'),
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
        title: const Text('Opret værelse'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
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
                      _imagePickerButton(),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _titleController,
                        decoration: customInputDecoration(labelText: 'Titel'),
                      ),
                      const SizedBox(height: 16),
                      PostnrField(controller: _locationController),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addressController,
                        decoration: customInputDecoration(labelText: 'Adresse'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _priceController,
                        decoration: customInputDecoration(labelText: 'Pris (DKK)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _sizeController,
                        decoration: customInputDecoration(labelText: 'Størrelse (m²)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _periodController,
                        decoration: customInputDecoration(labelText: 'Periode (måneder / ubegrænset)'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _roommatesController,
                        decoration: customInputDecoration(labelText: 'Antal roommates'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration: customInputDecoration(labelText: 'Beskrivelse'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButtonContainer(
                          child: ElevatedButton(
                            style: customElevatedButtonStyle(),
                            onPressed: _isUploading ? null : _createApartment,
                            child: const Text('Upload værelse'),
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
                if (_errorMsg != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                    child: Dismissible(
                      key: ValueKey(_errorMsg),
                      direction: DismissDirection.down,
                      onDismissed: (_) => setState(() => _errorMsg = null),
                      child: CustomErrorMessage(message: _errorMsg!),
                    ),
                  ),
              ],
            ),
    );
  }
}
