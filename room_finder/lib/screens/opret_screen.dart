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
import '../components/apartment_card.dart';
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

  String? _profileType;
  String _ownerFirstName = '';
  String _ownerLastName = '';

  @override
  void initState() {
    super.initState();
    _loadProfileType();
  }

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

  Future<void> _loadProfileType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final d = snap.data() ?? {};
    final meta = (d['metadata'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _profileType = (meta['profileType'] ?? '').toString();
      _ownerFirstName = d['firstName'] ?? '';
      _ownerLastName = d['lastName'] ?? '';
    });
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

  bool _validateListing() {
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

  bool _validateApplication() {
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    if (title.isEmpty || title.length > 100) return _fail('Titel skal udfyldes (max 100 tegn).');
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
    required String folder,
    required String id,
    required int index,
    required XFile file,
  }) async {
    final ref = FirebaseStorage.instance.ref('$folder/$id/$index.jpg');
    final snap = await ref.putFile(File(file.path), SettableMetadata(contentType: 'image/jpeg'));
    return await snap.ref.getDownloadURL();
  }

  Future<void> _createApartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!_validateListing()) return;
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
      final docRef = await FirebaseFirestore.instance.collection('apartments').add({
        'ownedBy': user.uid,
        'ownerFirstName': _ownerFirstName,
        'ownerLastName': _ownerLastName,
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
          (e) => _uploadImage(folder: 'apartments', id: docRef.id, index: e.key, file: e.value),
        ));
        await docRef.update({'imageUrls': urls});
      }
      _clearForm();
      _showError('Opslag gemt!');
    } catch (e) {
      _showError('Fejl under upload: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _createApplication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!_validateApplication()) return;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    setState(() => _isUploading = true);
    try {
      final docRef = await FirebaseFirestore.instance.collection('applications').add({
        'ownedBy': user.uid,
        'ownerFirstName': _ownerFirstName,
        'ownerLastName': _ownerLastName,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (_images.isNotEmpty) {
        final urls = await Future.wait(_images.asMap().entries.map(
          (e) => _uploadImage(folder: 'applications', id: docRef.id, index: e.key, file: e.value),
        ));
        await docRef.update({'imageUrls': urls});
      }
      _clearForm();
      _showError('Ansøgning gemt!');
    } catch (e) {
      _showError('Fejl under upload: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _locationController.clear();
    _addressController.clear();
    _priceController.clear();
    _sizeController.clear();
    _periodController.clear();
    _roommatesController.clear();
    _descriptionController.clear();
    setState(() => _images = []);
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

  Widget _applicationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _imagePickerButton(),
        const SizedBox(height: 24),
        TextField(controller: _titleController, decoration: customInputDecoration(labelText: 'Titel')),
        const SizedBox(height: 16),
        TextField(controller: _descriptionController, decoration: customInputDecoration(labelText: 'Beskrivelse'), maxLines: 5),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: CustomButtonContainer(
            child: ElevatedButton(
              style: customElevatedButtonStyle(),
              onPressed: _isUploading ? null : _createApplication,
              child: const Text('Upload ansøgning'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _listingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _imagePickerButton(),
        const SizedBox(height: 24),
        TextField(controller: _titleController, decoration: customInputDecoration(labelText: 'Titel')),
        const SizedBox(height: 16),
        PostnrField(controller: _locationController),
        const SizedBox(height: 16),
        TextField(controller: _addressController, decoration: customInputDecoration(labelText: 'Adresse')),
        const SizedBox(height: 16),
        TextField(controller: _priceController, decoration: customInputDecoration(labelText: 'Pris (DKK)'), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        TextField(controller: _sizeController, decoration: customInputDecoration(labelText: 'Størrelse (m²)'), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        TextField(controller: _periodController, decoration: customInputDecoration(labelText: 'Periode (måneder / ubegrænset)')),
        const SizedBox(height: 16),
        TextField(controller: _roommatesController, decoration: customInputDecoration(labelText: 'Antal roommates'), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        TextField(controller: _descriptionController, decoration: customInputDecoration(labelText: 'Beskrivelse'), maxLines: 3),
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
    );
  }

  Widget _userPostsSection(String uid) {
    final isSeeker = (_profileType ?? '').toLowerCase() != 'landlord';
    final collection = isSeeker ? 'applications' : 'apartments';
    final title = isSeeker ? 'Dine ansøgninger' : 'Dine opslag';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          key: ValueKey('${collection}_$uid'),
          future: FirebaseFirestore.instance.collection(collection).where('ownedBy', isEqualTo: uid).get(),
          builder: (_, snap) {
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
            docs.sort((a, b) {
              final tA = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final tB = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return tB.compareTo(tA);
            });
            if (docs.isEmpty) {
              return Column(
                children: [
                  Icon(isSeeker ? FluentIcons.document_24_regular : FluentIcons.home_24_regular, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(isSeeker ? 'Ingen ansøgninger.' : 'Ingen aktive opslag.', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              );
            }
            return LayoutBuilder(
              builder: (ctx, constraints) {
                const count = 2;
                const hPad = 8.0;
                const spacing = 16.0;
                final w = (constraints.maxWidth - hPad * 2 - spacing * (count - 1)) / count;
                final h = isSeeker ? w + 88 : w + 124;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: h,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final images = (d['imageUrls'] as List?)?.whereType<String>().toList() ?? [];
                    if (!isSeeker) {
                      return ApartmentCard(
                        images: images,
                        title: d['title'] ?? '',
                        location: d['location'] ?? 'Ukendt',
                        price: d['price'] ?? 0,
                        size: (d['size'] ?? 0).toDouble(),
                        period: d['period'] ?? '',
                        roommates: (d['roommates'] ?? 0) as int,
                      );
                    }
                    final firstImage = images.isNotEmpty ? images.first : null;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: w * 0.6,
                            width: double.infinity,
                            child: firstImage != null
                                ? Image.network(firstImage, fit: BoxFit.cover)
                                : Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.person, color: Colors.white))),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(d['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              (d['description'] ?? '').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final isSeeker = (_profileType ?? '').toLowerCase() != 'landlord';
    return Scaffold(
      appBar: AppBar(
        title: Text(isSeeker ? 'Opret ansøgning' : 'Opret værelse'),
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
                if (_profileType == null)
                  const Center(child: CircularProgressIndicator())
                else
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        isSeeker ? _applicationForm() : _listingForm(),
                        if (uid != null) _userPostsSection(uid),
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
