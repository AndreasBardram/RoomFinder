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
    final col = FirebaseFirestore.instance.collection('images');
    var ok = 0;
    for (var i = 0; i < files.length && i < 3; i++) {
      final bytes = await _jpeg1080(files[i]);
      debugPrint('[save] parent=$parentCollection/$parentId idx=$i bytes=${bytes.lengthInBytes}');
      if (bytes.lengthInBytes > 950 * 1024) throw Exception('Et billede er for stort (>950 KB). Prøv igen.');
      final data = {
        'parentCollection': parentCollection,
        'parentId': parentId,
        'index': i,
        'bytes': Blob(bytes),
        'mime': 'image/jpeg',
        'createdAt': FieldValue.serverTimestamp(),
      };
      final id = '${parentCollection}_${parentId}_$i';
      try {
        debugPrint('[save] set images/$id');
        await col.doc(id).set(data);
        debugPrint('[save] ok set images/$id');
        ok++;
      } on FirebaseException catch (e) {
        debugPrint('[save][set][err] code=${e.code} msg=${e.message}');
        final r = await col.add(data);
        debugPrint('[save] ok add images/${r.id}');
        ok++;
      }
    }
    debugPrint('[save] done count=$ok');
  }

  Future<Uint8List?> _fetchFirstImage(String parentCollection, String parentId) async {
    debugPrint('[fetchFirst] $parentCollection/$parentId');
    final byId = '${parentCollection}_${parentId}_0';
    try {
      final doc = await FirebaseFirestore.instance.collection('images').doc(byId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['bytes'] != null) return _unwrapImageField(data['bytes']);
      }
    } catch (e) {
      debugPrint('[fetchFirst][byId][err] $e');
    }
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

  Future<bool> _confirmDelete(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Slet?'),
            content: Text('Vil du slette "$title"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuller')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Slet')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteListing(String parentCollection, String parentId) async {
    debugPrint('[delete] start $parentCollection/$parentId');
    setState(() => _isUploading = true);
    try {
      final col = FirebaseFirestore.instance.collection('images');
      final imgs = await col
          .where('parentCollection', isEqualTo: parentCollection)
          .where('parentId', isEqualTo: parentId)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in imgs.docs) {
        batch.delete(d.reference);
      }
      batch.delete(FirebaseFirestore.instance.collection(parentCollection).doc(parentId));
      await batch.commit();
      debugPrint('[delete] ok $parentCollection/$parentId and ${imgs.docs.length} images');
      setState(() {});
    } catch (e, st) {
      debugPrint('[delete][err] $e\n$st');
      _showError('Kunne ikke slette: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<bool> _reachedLimit(String collection, String uid, {int max = 5}) async {
    final qs = await FirebaseFirestore.instance.collection(collection).where('ownedBy', isEqualTo: uid).limit(max).get();
    final reached = qs.docs.length >= max;
    debugPrint('[limit] $collection count=${qs.docs.length} reached=$reached');
    return reached;
  }

  Future<void> _createApartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!_validateListing()) return;
    if (await _reachedLimit('apartments', user.uid)) {
      _showError('Du kan maksimalt have 5 opslag. Slet et for at oprette nyt.');
      return;
    }
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
    if (await _reachedLimit('applications', user.uid)) {
      _showError('Du kan maksimalt have 5 ansøgninger. Slet en for at oprette ny.');
      return;
    }
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

  Widget _itemCard({
    required String collection,
    required String parentId,
    required Map<String, dynamic> data,
    required double imageHeight,
  }) {
    final title = (data['title'] ?? '').toString();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _ImagesPager(future: _fetchAllImages(collection, parentId), height: imageHeight),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () async {
                      if (await _confirmDelete(title)) {
                        await _deleteListing(collection, parentId);
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (collection == 'apartments') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(child: Text((data['location'] ?? 'Ukendt').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                  Text('${(data['size'] ?? 0).toString()} m²', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text((data['period'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                  Text('${(data['price'] ?? 0).toString()} DKK', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              child: Text('Roommates: ${(data['roommates'] ?? 0) as int}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text((data['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
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
                final w = constraints.maxWidth;
                final imageH = w * 0.6;
                return ListView.separated(
                  itemCount: docs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final id = docs[i].id;
                    return _itemCard(collection: collection, parentId: id, data: d, imageHeight: imageH);
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

class _ImagesPager extends StatefulWidget {
  final Future<List<Uint8List>> future;
  final double height;
  const _ImagesPager({required this.future, required this.height});

  @override
  State<_ImagesPager> createState() => _ImagesPagerState();
}

class _ImagesPagerState extends State<_ImagesPager> {
  final _controller = PageController();
  List<Uint8List>? _imgs;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    widget.future.then((v) {
      if (!mounted) return;
      setState(() => _imgs = v);
    }).catchError((e) {
      debugPrint('[_ImagesPager][err] $e');
      if (!mounted) return;
      setState(() => _imgs = const []);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int dir) {
    if (_imgs == null || _imgs!.isEmpty) return;
    final next = (_i + dir).clamp(0, _imgs!.length - 1);
    if (next == _i) return;
    _controller.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    setState(() => _i = next);
  }

  @override
  Widget build(BuildContext context) {
    if (_imgs == null) {
      return Container(height: widget.height, color: Colors.grey[300], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_imgs!.isEmpty) {
      return Container(height: widget.height, color: Colors.grey[300], child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white)));
    }
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (v) => setState(() => _i = v),
            itemCount: _imgs!.length,
            itemBuilder: (_, idx) => Image.memory(_imgs![idx], height: widget.height, width: double.infinity, fit: BoxFit.cover),
          ),
          if (_imgs!.length > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _i == 0 ? null : () => _go(-1),
                  ),
                ),
              ),
            ),
          if (_imgs!.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _i == _imgs!.length - 1 ? null : () => _go(1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
