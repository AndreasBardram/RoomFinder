import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';

import '../components/custom_styles.dart';
import '../components/custom_error_message.dart';
import '../components/postcode_enter_field.dart';
import '../components/no_transition.dart';
import 'settings_screen.dart';
import 'log_in_screen.dart';
import 'create_profile_screen.dart';
import 'more_information_apartment.dart';
import 'more_information_application.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});
  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  static const int _maxImages = 6;
  static const int _maxTitle = 100;
  static const int _maxDesc = 1000;
  static const int _minDesc = 50;
  static const int _targetMaxSide = 1440;
  static const int _jpegQuality = 85;
  static const int _maxUploadBytes = 4 * 1024 * 1024;

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(bucket: 'gs://roomfinder-cec5a.firebasestorage.app');

  List<XFile> _images = [];
  bool _isUploading = false;
  String? _errorMsg;

  String? _profileType;
  String _ownerFirstName = '';
  String _ownerLastName = '';

  int _periodMonths = 0;
  int _roommates = 2;

  bool get _isSeeker => (_profileType ?? '').toLowerCase() != 'landlord';

  static const _hairline = Color(0xFFF1F5F9);
  static const _fill = Color(0xFFF6F7FA);
  static const _hint = Color(0xFF9AA3B2);
  static const _icon = Color(0xFF4B5563);

  @override
  void initState() {
    super.initState();
    _loadProfileType();
    _descriptionController.addListener(() => setState(() {}));
    for (final c in [_priceController, _sizeController, _budgetController]) {
      c.addListener(() => setState(() {}));
    }
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
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

  String _periodString() => _periodMonths == 0 ? 'Ubegrænset' : '$_periodMonths måneder';

  int? _parseInt(String text) {
    if (text.trim().isEmpty) return null;
    final normalized = text.replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(normalized);
  }

  bool _validateListing() {
    final title = _titleController.text.trim();
    final loc = _locationController.text.trim();
    final addr = _addressController.text.trim();
    final price = _parseInt(_priceController.text);
    final size = _parseInt(_sizeController.text);
    final desc = _descriptionController.text.trim();
    if (title.isEmpty || title.length > _maxTitle) return _fail('Titel skal udfyldes (max $_maxTitle tegn).');
    if (loc.isEmpty) return _fail('Vælg postnummer.');
    if (addr.isEmpty) return _fail('Adresse skal udfyldes.');
    if (price == null || price < 0 || price > 100000) return _fail('Pris: 0-100 000 DKK.');
    if (size == null || size < 1 || size > 1000) return _fail('Størrelse: 1-1 000 m².');
    if (_periodMonths != 0 && (_periodMonths < 1 || _periodMonths > 100)) return _fail('Periode: 1-100 måneder eller ubegrænset.');
    if (_roommates < 1 || _roommates > 10) return _fail('Roommates: 1-10.');
    if (desc.isEmpty || desc.length > _maxDesc) return _fail('Beskrivelse skal udfyldes (max $_maxDesc tegn).');
    if (desc.length < _minDesc) return _fail('Skriv lidt mere (mindst $_minDesc tegn er anbefalet).');
    setState(() => _errorMsg = null);
    return true;
  }

  bool _validateApplication() {
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    final budget = _parseInt(_budgetController.text);
    if (title.isEmpty || title.length > _maxTitle) return _fail('Titel skal udfyldes (max $_maxTitle tegn).');
    if (budget == null || budget < 0 || budget > 100000) return _fail('Budget: 0-100 000 DKK.');
    if (desc.isEmpty || desc.length > _maxDesc) return _fail('Beskrivelse skal udfyldes (max $_maxDesc tegn).');
    if (desc.length < _minDesc) return _fail('Skriv lidt mere (mindst $_minDesc tegn er anbefalet).');
    setState(() => _errorMsg = null);
    return true;
  }

  Future<void> _pickImages() async {
    final imgs = await _picker.pickMultiImage();
    _images = imgs.take(_maxImages).toList();
    setState(() {});
  }

  void _removeImageAt(int i) {
    if (i < 0 || i >= _images.length) return;
    setState(() => _images.removeAt(i));
  }

  void _makeCover(int i) {
    if (i <= 0 || i >= _images.length) return;
    final f = _images.removeAt(i);
    _images.insert(0, f);
    setState(() {});
  }

  Widget _selectedImagesStrip() {
    if (_images.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 12),
        itemBuilder: (_, i) {
          final isCover = i == 0;
          return Stack(
            children: [
              FutureBuilder<Uint8List>(
                future: _images[i].readAsBytes(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(width: 120, height: 90, color: Colors.grey[300]),
                    );
                  }
                  return GestureDetector(
                    onTap: () => _makeCover(i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(snap.data!, width: 120, height: 90, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
              if (isCover)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              Positioned(
                right: 4,
                top: 4,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _removeImageAt(i),
                    child: const SizedBox(
                      width: 26,
                      height: 26,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _images.length,
      ),
    );
  }

  Future<Uint8List> _jpegResized(XFile f) async {
    final src = await f.readAsBytes();
    final decoded = img.decodeImage(src);
    if (decoded == null) throw Exception('Kunne ikke læse billedet');
    int tw = decoded.width, th = decoded.height;
    final wide = decoded.width >= decoded.height;
    if (wide) {
      if (decoded.width > _targetMaxSide) {
        tw = _targetMaxSide;
        th = (decoded.height * _targetMaxSide / decoded.width).round();
      }
    } else {
      if (decoded.height > _targetMaxSide) {
        th = _targetMaxSide;
        tw = (decoded.width * _targetMaxSide / decoded.height).round();
      }
    }
    final resized = (tw != decoded.width || th != decoded.height) ? img.copyResize(decoded, width: tw, height: th, interpolation: img.Interpolation.cubic) : decoded;
    final jpg = img.encodeJpg(resized, quality: _jpegQuality);
    final bytes = Uint8List.fromList(jpg);
    if (bytes.lengthInBytes > _maxUploadBytes) throw Exception('Et billede er for stort (> 4 MB). Prøv igen.');
    return bytes;
  }

  Future<void> _saveImagesToCollection({required String parentCollection, required String parentId, required List<XFile> files}) async {
    final col = FirebaseFirestore.instance.collection('images');
    for (var i = 0; i < files.length && i < _maxImages; i++) {
      final bytes = await _jpegResized(files[i]);
      final path = 'images/$parentCollection/$parentId/$i.jpg';
      final ref = _storage.ref().child(path);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      final data = {
        'parentCollection': parentCollection,
        'parentId': parentId,
        'index': i,
        'path': path,
        'url': url,
        'mime': 'image/jpeg',
        'createdAt': FieldValue.serverTimestamp(),
      };
      final id = '${parentCollection}_${parentId}_$i';
      try {
        await col.doc(id).set(data, SetOptions(merge: true));
      } on FirebaseException {
        await col.add(data);
      }
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
    setState(() => _isUploading = true);
    try {
      final col = FirebaseFirestore.instance.collection('images');
      final imgs = await col.where('parentCollection', isEqualTo: parentCollection).where('parentId', isEqualTo: parentId).get();
      for (final d in imgs.docs) {
        final data = d.data();
        final path = (data['path'] ?? '') as String;
        if (path.isNotEmpty) {
          try {
            await _storage.ref().child(path).delete();
          } catch (_) {}
        }
      }
      final batch = FirebaseFirestore.instance.batch();
      for (final d in imgs.docs) {
        batch.delete(d.reference);
      }
      batch.delete(FirebaseFirestore.instance.collection(parentCollection).doc(parentId));
      await batch.commit();
      setState(() {});
    } catch (e) {
      _showError('Kunne ikke slette: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<bool> _reachedLimit(String collection, String uid, {int max = 5}) async {
    final qs = await FirebaseFirestore.instance.collection(collection).where('ownedBy', isEqualTo: uid).limit(max).get();
    return qs.docs.length >= max;
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
    final price = (_parseInt(_priceController.text) ?? 0).toDouble();
    final size = (_parseInt(_sizeController.text) ?? 0).toDouble();
    final period = _periodString();
    final roommates = _roommates;
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
        await _saveImagesToCollection(parentCollection: 'apartments', parentId: docRef.id, files: _images);
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
    if (await _reachedLimit('applications', user.uid)) {
      _showError('Du kan maksimalt have 5 ansøgninger. Slet en for at oprette ny.');
      return;
    }
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final budget = (_parseInt(_budgetController.text) ?? 0).toDouble();

    setState(() => _isUploading = true);
    try {
      final docRef = await FirebaseFirestore.instance.collection('applications').add({
        'ownedBy': user.uid,
        'ownerFirstName': _ownerFirstName,
        'ownerLastName': _ownerLastName,
        'title': title,
        'description': description,
        'budget': budget,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (_images.isNotEmpty) {
        await _saveImagesToCollection(parentCollection: 'applications', parentId: docRef.id, files: _images);
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
    _descriptionController.clear();
    _budgetController.clear();
    _images = [];
    _periodMonths = 6;
    _roommates = 2;
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
                onPressed: () => pushNoAnim(context, const LoginScreen()),
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
                onPressed: () => pushNoAnim(context, const CreateAccountScreen()),
                child: const Text('Opret profil'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));

  Widget _titleLabelWithCounter() => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            const Text('Titel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_titleController.text.length}/$_maxTitle', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      );

  InputDecoration _dec({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hint),
      filled: true,
      fillColor: _fill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: suffix,
    );
  }

  Widget _textField(
    TextEditingController c, {
    String hint = '',
    TextInputType? type,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
    bool hideCounter = true,
    Widget? suffix,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      cursorColor: Colors.black,
      buildCounter: hideCounter ? (_, {required int currentLength, required bool isFocused, required int? maxLength}) => const SizedBox.shrink() : null,
      decoration: _dec(hint: hint, suffix: suffix),
    );
  }

  Widget _periodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Udlejningsperiode (måneder)'),
        Container(
          decoration: BoxDecoration(color: _fill, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _periodMonths > 0 ? () => setState(() => _periodMonths--) : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _periodMonths == 0 ? 'Ubegrænset' : '$_periodMonths',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _periodMonths < 100 ? () => setState(() => _periodMonths++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          decoration: BoxDecoration(color: _fill, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(child: Center(child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)))),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        if (helper != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(helper, style: const TextStyle(color: _hint, fontSize: 12))),
      ],
    );
  }

  Widget _imagePickerButton() {
    final has = _images.isNotEmpty;
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _DashedRRectPainter(color: Colors.black12, radius: 16, dash: 8, gap: 6, strokeWidth: 2),
          child: Container(
            height: 160,
            color: _fill,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FluentIcons.arrow_upload_24_regular, size: 28, color: _icon),
                const SizedBox(height: 8),
                Text(
                  has ? '${_images.length} billede(r) valgt – tryk for at ændre' : 'Tryk for at tilføje op til $_maxImages billeder',
                  style: const TextStyle(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _titleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleLabelWithCounter(),
        _textField(_titleController, hint: 'Skriv en titel', maxLength: _maxTitle, hideCounter: true),
      ],
    );
  }

  Widget _applicationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _imagePickerButton(),
        _selectedImagesStrip(),
        const SizedBox(height: 24),
        _titleField(),
        const SizedBox(height: 16),
        _label('Budget (DKK)'),
        _textField(_budgetController, hint: 'fx 6000', type: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        const SizedBox(height: 16),
        _label('Beskrivelse'),
        _textField(_descriptionController, hint: 'Skriv en beskrivelse', maxLines: 6, maxLength: _maxDesc, hideCounter: true),
        const SizedBox(height: 16),
        _previewButton(isApplication: true),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CustomButtonContainer(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
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
        _selectedImagesStrip(),
        const SizedBox(height: 24),
        _titleField(),
        const SizedBox(height: 16),
        _label('Postnummer'),
        PostnrField(controller: _locationController),
        const SizedBox(height: 16),
        _label('Adresse'),
        _textField(_addressController, hint: 'fx Nørrebrogade 1', type: TextInputType.streetAddress),
        const SizedBox(height: 16),
        _label('Pris (DKK)'),
        _textField(_priceController, hint: 'fx 6000', type: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        const SizedBox(height: 16),
        _label('Størrelse (m²)'),
        _textField(_sizeController, hint: 'fx 18', type: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        const SizedBox(height: 16),
        _periodPicker(),
        const SizedBox(height: 16),
        _stepper(label: 'Antal roommates', value: _roommates, min: 1, max: 10, onChanged: (v) => setState(() => _roommates = v)),
        const SizedBox(height: 16),
        _label('Beskrivelse'),
        _textField(_descriptionController, hint: 'Skriv en beskrivelse', maxLines: 5, maxLength: _maxDesc, hideCounter: true),
        const SizedBox(height: 16),
        _previewButton(isApplication: false),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CustomButtonContainer(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: _isUploading ? null : _createApartment,
              child: const Text('Upload værelse'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewButton({required bool isApplication}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(FluentIcons.eye_24_regular),
        label: const Text('Forhåndsvis'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          foregroundColor: Colors.black87,
        ),
        onPressed: () => _showPreview(isApplication: isApplication),
      ),
    );
  }

  void _showPreview({required bool isApplication}) async {
    final bytes = _images.isNotEmpty ? await _images.first.readAsBytes() : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sådan ser dit opslag ud', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: bytes == null ? Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.image, color: Colors.white))) : Image.memory(bytes, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_titleController.text.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        if (isApplication) ...[
                          Text('Budget: ${_budgetController.text.isEmpty ? '—' : _budgetController.text} DKK', style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 6),
                          Text(_descriptionController.text.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: Text(_locationController.text.isEmpty ? 'Ukendt' : _locationController.text, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                              Text(_sizeController.text.isEmpty ? '— m²' : '${_sizeController.text} m²', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: Text('Roommates: $_roommates', style: const TextStyle(fontSize: 12, color: Colors.black54))),
                              Text(_priceController.text.isEmpty ? '— DKK' : '${_priceController.text} DKK', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Luk'))),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _fetchAllImages(String parentCollection, String parentId) async {
    try {
      final q = await FirebaseFirestore.instance
          .collection('images')
          .where('parentCollection', isEqualTo: parentCollection)
          .where('parentId', isEqualTo: parentId)
          .orderBy('index')
          .limit(_maxImages)
          .get();
      return q.docs.map((d) => (d.data()['url'] as String)).toList();
    } catch (_) {
      final q2 = await FirebaseFirestore.instance
          .collection('images')
          .where('parentCollection', isEqualTo: parentCollection)
          .where('parentId', isEqualTo: parentId)
          .limit(_maxImages)
          .get();
      q2.docs.sort((a, b) => ((a.data()['index'] ?? 999) as int).compareTo((b.data()['index'] ?? 999) as int));
      return q2.docs.map((d) => (d.data()['url'] as String)).toList();
    }
  }

  Widget _itemCard({required String collection, required String parentId, required Map<String, dynamic> data, required double imageHeight}) {
    final title = (data['title'] ?? '').toString();

    void _openDetails() {
      if (collection == 'apartments') {
        pushNoAnim(
          context,
          MoreInformationScreen(data: data, parentCollection: 'apartments', parentId: parentId),
        );
      } else {
        pushNoAnim(
          context,
          MoreInformationApplicationScreen(data: data, parentCollection: 'applications', parentId: parentId),
        );
      }
    }

    return InkWell(
      onTap: _openDetails,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.white,
                    elevation: 2,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(FluentIcons.delete_24_regular, color: Color(0xFFDC2626)),
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
              padding: const EdgeInsets.all(12),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            if (collection == 'apartments') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text((data['location'] ?? 'Ukendt').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                    Text('${(data['size'] ?? 0).toString()} m²', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text((data['period'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                    Text('${(data['price'] ?? 0).toString()} DKK', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text((data['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyItemCard(double imageHeight, bool isSeeker) {
    final title = isSeeker ? 'Ingen ansøgninger.' : 'Ingen aktive opslag.';
    final icon = isSeeker ? FluentIcons.document_24_regular : FluentIcons.home_24_regular;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: imageHeight, color: Colors.grey[300], child: const SizedBox.shrink()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey))),
              ],
            ),
          ),
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
        const Divider(color: _hairline),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
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
            return LayoutBuilder(
              builder: (ctx, constraints) {
                final w = constraints.maxWidth;
                final imageH = w * 0.6;
                if (docs.isEmpty) {
                  return Column(children: [_emptyItemCard(imageH, isSeeker)]);
                }
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

    final themed = Theme.of(context).copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.black,
        selectionColor: Color(0x33000000),
        selectionHandleColor: Colors.black,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: _fill,
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: _hint),
      ),
    );

    return Theme(
      data: themed,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(_isSeeker ? 'Opret ansøgning' : 'Opret værelse'),
          actions: [
            IconButton(
              icon: const Icon(FluentIcons.settings_24_regular),
              onPressed: () => pushNoAnim(context, const SettingsScreen()),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: _hairline),
          ),
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
                          _isSeeker ? _applicationForm() : _listingForm(),
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
      ),
    );
  }
}

class _ImagesPager extends StatefulWidget {
  final Future<List<String>> future;
  final double height;
  const _ImagesPager({required this.future, required this.height});

  @override
  State<_ImagesPager> createState() => _ImagesPagerState();
}

class _ImagesPagerState extends State<_ImagesPager> {
  final _controller = PageController();
  List<String>? _imgs;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    widget.future.then((v) {
      if (!mounted) return;
      setState(() => _imgs = v);
    }).catchError((_) {
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
    final leftEnabled = _i > 0;
    final rightEnabled = _i < _imgs!.length - 1;
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: _imgs!.length > 1 ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
            onPageChanged: (v) => setState(() => _i = v),
            itemCount: _imgs!.length,
            itemBuilder: (_, idx) => Image.network(_imgs![idx], height: widget.height, width: double.infinity, fit: BoxFit.cover),
          ),
          if (leftEnabled)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () => _go(-1),
                  ),
                ),
              ),
            ),
          if (rightEnabled)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () => _go(1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
    this.dash = 6,
    this.gap = 4,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      double drawn = 0;
      while (drawn < metric.length) {
        final end = (drawn + dash).clamp(0, metric.length).toDouble();
        final extract = metric.extractPath(drawn, end);
        canvas.drawPath(extract, paint);
        drawn = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dash != dash ||
      old.gap != gap ||
      old.strokeWidth != strokeWidth;
}
