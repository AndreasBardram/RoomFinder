import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

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
    final imgs = await _picker.pickMultiImage();
    _images = imgs.take(3).toList();
    debugPrint('[pick] selected=${_images.length}');
    setState(() {});
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
                    Text('Tryk for at tilføje op til 3 billeder (valgfrit)'),
                  ],
                ),
        ),
      ),
    );
  }

  Future<Uint8List> _jpeg1080(XFile f) async {
    final src = await f.readAsBytes();
    debugPrint('[_jpeg1080] platform=${kIsWeb ? 'web' : 'native'} srcBytes=${src.length}');
    final decoded = img.decodeImage(src);
    if (decoded == null) throw Exception('Kunne ikke læse billedet');
    int tw = decoded.width, th = decoded.height;
    if (decoded.width >= decoded.height) {
      if (decoded.width > 1080) {
        tw = 1080;
        th = (decoded.height * 1080 / decoded.width).round();
      }
    } else {
      if (decoded.height > 1080) {
        th = 1080;
        tw = (decoded.width * 1080 / decoded.height).round();
      }
    }
    final resized = (tw != decoded.width || th != decoded.height)
        ? img.copyResize(decoded, width: tw, height: th, interpolation: img.Interpolation.cubic)
        : decoded;
    final jpg = img.encodeJpg(resized, quality: 80);
    debugPrint('[_jpeg1080] out ${resized.width}x${resized.height} bytes=${jpg.length}');
    return Uint8List.fromList(jpg);
  }

  Uint8List _unwrapImageField(dynamic v) {
  if (v is Uint8List) return v;
  if (v is Blob) return v.bytes;
  if (v is List<int>) return Uint8List.fromList(v);
  if (v is List<dynamic>) return Uint8List.fromList(v.cast<int>());
  throw Exception('Ukendt billedtype: ${v.runtimeType}');
  }

  Future<void> _saveImagesToCollection({
    required String parentCollection,
    required String parentId,
    required List<XFile> files,
  }) async {
    final imagesCol = FirebaseFirestore.instance.collection('images');
    for (var i = 0; i < files.length && i < 3; i++) {
      final bytes = await _jpeg1080(files[i]);
      debugPrint('[save] parent=$parentCollection/$parentId idx=$i bytes=${bytes.lengthInBytes}');
      if (bytes.lengthInBytes > 950 * 1024) {
        throw Exception('Et billede er for stort (>950 KB). Prøv igen.');
      }
      final imageDocId = '${parentCollection}_${parentId}_$i';
      debugPrint('[save] writing images/$imageDocId');
      await imagesCol.doc(imageDocId).set({
        'parentCollection': parentCollection,
        'parentId': parentId,
        'index': i,
        'bytes': bytes,
        'mime': 'image/jpeg',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[save] ok images/$imageDocId');
    }
    debugPrint('[save] all done for $parentCollection/$parentId');
  }

  Future<Uint8List?> _fetchFirstImage(String parentCollection, String parentId) async {
    debugPrint('[fetchFirst] $parentCollection/$parentId');
    try {
      final q = await FirebaseFirestore.instance
          .collection('images')
          .where('parentCollection', isEqualTo: parentCollection)
          .where('parentId', isEqualTo: parentId)
          .orderBy('index')
          .limit(1)
          .get();
      debugPrint('[fetchFirst] docs=${q.docs.length}');
      if (q.docs.isEmpty) return null;
      return _unwrapImageField(q.docs.first.data()['bytes']);
    } catch (e) {
      debugPrint('[fetchFirst][err] $e');
      final q2 = await FirebaseFirestore.instance
          .collection('images')
          .where('parentCollection', isEqualTo: parentCollection)
          .where('parentId', isEqualTo: parentId)
          .limit(3)
          .get();
      debugPrint('[fetchFirst][fallback] docs=${q2.docs.length}');
      if (q2.docs.isEmpty) return null;
      q2.docs.sort((a, b) => ((a.data()['index'] ?? 999) as int).compareTo((b.data()['index'] ?? 999) as int));
      return _unwrapImageField(q2.docs.first.data()['bytes']);
    }
  }

  Future<List<Uint8List>> _fetchAllImages(String parentCollection, String parentId) async {
    debugPrint('[fetchAll] $parentCollection/$parentId');
    try {
      final q = await FirebaseFirestore.instance
          .collection('images')
          .where('parentCollection', isEqualTo: parentCollection)
          .where('parentId', isEqualTo: parentId)
          .orderBy('index')
          .limit(3)
          .get();
      debugPrint('[fetchAll] docs=${q.docs.length}');
      return q.docs.map((d) => _unwrapImageField(d.data()['bytes'])).toList();
    } catch (e) {
      debugPrint('[fetchAll][err] $e');
      final q2 = await FirebaseFirestore.instance
          .collection('images')
          .where('parentCollection', isEqualTo: parentCollection)
          .where('parentId', isEqualTo: parentId)
          .limit(3)
          .get();
      debugPrint('[fetchAll][fallback] docs=${q2.docs.length}');
      q2.docs.sort((a, b) => ((a.data()['index'] ?? 999) as int).compareTo((b.data()['index'] ?? 999) as int));
      return q2.docs.map((d) => _unwrapImageField(d.data()['bytes'])).toList();
    }
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
      debugPrint('[createApartment] start');
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
      debugPrint('[createApartment] docId=${docRef.id}');
      if (_images.isNotEmpty) {
        await _saveImagesToCollection(parentCollection: 'apartments', parentId: docRef.id, files: _images);
      }
      _clearForm();
      _showError('Opslag gemt!');
    } catch (e, st) {
      debugPrint('[createApartment][err] $e\n$st');
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
      debugPrint('[createApplication] start');
      final docRef = await FirebaseFirestore.instance.collection('applications').add({
        'ownedBy': user.uid,
        'ownerFirstName': _ownerFirstName,
        'ownerLastName': _ownerLastName,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[createApplication] docId=${docRef.id}');
      if (_images.isNotEmpty) {
        await _saveImagesToCollection(parentCollection: 'applications', parentId: docRef.id, files: _images);
      }
      _clearForm();
      _showError('Ansøgning gemt!');
    } catch (e, st) {
      debugPrint('[createApplication][err] $e\n$st');
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
    _images = [];
    debugPrint('[clearForm] cleared');
    setState(() {});
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

  Widget _cover(String parentCollection, String parentId, double height) {
    return FutureBuilder<Uint8List?>(
      future: _fetchFirstImage(parentCollection, parentId),
      builder: (_, s) {
        if (s.hasError) debugPrint('[cover][err] ${s.error}');
        if (s.connectionState == ConnectionState.waiting) {
          return Container(height: height, color: Colors.grey[300], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (s.data == null) {
          return Container(height: height, color: Colors.grey[300], child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white)));
        }
        return Image.memory(s.data!, height: height, width: double.infinity, fit: BoxFit.cover);
      },
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
                    final parentId = docs[i].id;
                    if (!isSeeker) {
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cover('apartments', parentId, w * 0.6),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(d['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(d['location'] ?? 'Ukendt', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                                  Text('${(d['size'] ?? 0).toString()} m²', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(child: Text(d['period'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                                  Text('${(d['price'] ?? 0).toString()} DKK', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Roommates: ${(d['roommates'] ?? 0) as int}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ),
                          ],
                        ),
                      );
                    }
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cover('applications', parentId, w * 0.6),
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
