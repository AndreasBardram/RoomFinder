import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'mere_information.dart';
import 'settings_screen.dart';
import '../components/postcode_filter_field.dart';
import '../components/custom_styles.dart';

class FindRoommatesScreen extends StatefulWidget {
  const FindRoommatesScreen({super.key});
  @override
  State<FindRoommatesScreen> createState() => _FindRoommatesScreenState();
}

class _FindRoommatesScreenState extends State<FindRoommatesScreen> {
  final _locCtl = TextEditingController();

  String _sort = 'Nyeste først';
  String? _location;
  String? _period;
  int? _maxAgeDays;

  static const double _priceMin = 0, _priceMax = 10000;
  static const double _sizeMin = 0, _sizeMax = 200;
  static const int _matesMin = 0, _matesMax = 10;

  RangeValues _price = const RangeValues(_priceMin, _priceMax);
  RangeValues _size = const RangeValues(_sizeMin, _sizeMax);
  RangeValues _mates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());

  static const _sortChoices = ['Nyeste først', 'Ældst først', 'Pris ↓', 'Pris ↑', 'Størrelse ↓', 'Størrelse ↑'];
  static const _periods = ['Ubegrænset', '1-3 måneder', '3-6 måneder', '6-12 måneder'];
  static const Map<int, String> _ageChoices = {1: 'Seneste 24 timer', 3: 'Seneste 3 dage', 7: 'Seneste uge', 30: 'Seneste måned'};

  String _appliedSort = 'Nyeste først';
  String? _appliedLocation;
  String? _appliedPeriod;
  int? _appliedMaxAgeDays;
  RangeValues _appliedPrice = const RangeValues(_priceMin, _priceMax);
  RangeValues _appliedSize = const RangeValues(_sizeMin, _sizeMax);
  RangeValues _appliedMates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());

  Stream<QuerySnapshot<Map<String, dynamic>>>? _resultsStream;

  bool _filtersOpen = true;
  String? _profileType;

  static const _labelColor = Color(0xFF374151);
  static const _iconColor = Color(0xFF4B5563);
  static const _fill = Color(0xFFF3F4F6);
  static const _btnBg = Color(0xFF111827);
  static const _trackActive = Colors.black;
  static const _trackInactive = Color(0xFFB0B6BF);
  static const double _controlH = 44;

  @override
  void initState() {
    super.initState();
    _resultsStream = _buildAppliedQuery().snapshots();
    _loadProfileType();
  }

  Future<void> _loadProfileType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final d = snap.data() ?? {};
    final meta = (d['metadata'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _profileType = (meta['profileType'] ?? '').toString();
      _resultsStream = _buildAppliedQuery().snapshots();
    });
  }

  @override
  void dispose() {
    _locCtl.dispose();
    super.dispose();
  }

  bool get _isSeeker => (_profileType ?? '').toLowerCase() != 'landlord';

  Query<Map<String, dynamic>> _buildAppliedQuery() {
    if (_isSeeker) {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('apartments');
      if (_appliedLocation != null) q = q.where('location', isEqualTo: _appliedLocation);
      if (_appliedPeriod != null) q = q.where('period', isEqualTo: _appliedPeriod);
      if (_appliedMaxAgeDays != null) {
        final ts = Timestamp.fromDate(DateTime.now().subtract(Duration(days: _appliedMaxAgeDays!)));
        q = q.where('createdAt', isGreaterThanOrEqualTo: ts);
      }
      final priceNeeded = _appliedPrice.start > _priceMin || _appliedPrice.end < _priceMax;
      final sizeNeeded = _appliedSize.start > _sizeMin || _appliedSize.end < _sizeMax;
      final mateNeeded = _appliedMates.start > _matesMin || _appliedMates.end < _matesMax;
      if (priceNeeded) q = q.where('price', isGreaterThanOrEqualTo: _appliedPrice.start, isLessThanOrEqualTo: _appliedPrice.end);
      if (sizeNeeded) q = q.where('size', isGreaterThanOrEqualTo: _appliedSize.start, isLessThanOrEqualTo: _appliedSize.end);
      if (mateNeeded) q = q.where('roommates', isGreaterThanOrEqualTo: _appliedMates.start.round(), isLessThanOrEqualTo: _appliedMates.end.round());
      switch (_appliedSort) {
        case 'Pris ↓':
          q = q.orderBy('price', descending: true);
          break;
        case 'Pris ↑':
          q = q.orderBy('price');
          break;
        case 'Størrelse ↓':
          q = q.orderBy('size', descending: true);
          break;
        case 'Størrelse ↑':
          q = q.orderBy('size');
          break;
        case 'Ældst først':
          q = q.orderBy('createdAt');
          break;
        default:
          q = q.orderBy('createdAt', descending: true);
      }
      if (priceNeeded && !_appliedSort.startsWith('Pris')) q = q.orderBy('price');
      if (sizeNeeded && !_appliedSort.startsWith('Størrelse')) q = q.orderBy('size');
      if (mateNeeded) q = q.orderBy('roommates');
      return q;
    } else {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('applications');
      if (_appliedMaxAgeDays != null) {
        final ts = Timestamp.fromDate(DateTime.now().subtract(Duration(days: _appliedMaxAgeDays!)));
        q = q.where('createdAt', isGreaterThanOrEqualTo: ts);
      }
      if (_appliedSort == 'Ældst først') {
        q = q.orderBy('createdAt');
      } else {
        q = q.orderBy('createdAt', descending: true);
      }
      return q;
    }
  }

  void _applyFilters() {
    _appliedSort = _sort;
    _appliedLocation = _location;
    _appliedPeriod = _period;
    _appliedMaxAgeDays = _maxAgeDays;
    _appliedPrice = _price;
    _appliedSize = _size;
    _appliedMates = _mates;
    _resultsStream = _buildAppliedQuery().snapshots();
    setState(() {});
  }

  Future<List<String>> _fetchImageUrls(String parentCollection, String parentId) async {
    final q = await FirebaseFirestore.instance
        .collection('images')
        .where('parentCollection', isEqualTo: parentCollection)
        .where('parentId', isEqualTo: parentId)
        .orderBy('index')
        .limit(3)
        .get();
    return q.docs.map((d) => (d.data()['url'] as String)).toList();
  }

  void _openApplication(String docId, Map<String, dynamic> d) async {
    final images = await _fetchImageUrls('applications', docId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(aspectRatio: 16 / 9, child: _UrlImagesPager(urls: images)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text((d['description'] ?? '').toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSeeker = _isSeeker;
    final themed = Theme.of(context).copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.black,
        selectionColor: Color(0x33000000),
        selectionHandleColor: Colors.black,
      ),
    );

    return Theme(
      data: themed,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
          title: Text(isSeeker ? 'Find værelser' : 'Se ansøgninger'),
          actions: [
            IconButton(
              icon: const Icon(FluentIcons.settings_24_regular),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
        ),
        body: Column(
          children: [
            _buildFilterCard(context, isSeeker),
            Expanded(
              child: _resultsStream == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _resultsStream,
                      builder: (_, snap) {
                        if (snap.hasError) return Center(child: Text('Firestore-fejl: ${snap.error}'));
                        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (!snap.hasData || snap.data!.docs.isEmpty) {
                          return Center(child: Text(isSeeker ? 'Ingen værelser.' : 'Ingen ansøgninger.'));
                        }
                        final docs = snap.data!.docs;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemBuilder: (_, i) {
                            final doc = docs[i];
                            final d = doc.data();
                            if (isSeeker) {
                              return FutureBuilder<List<String>>(
                                future: _fetchImageUrls('apartments', doc.id),
                                builder: (ctx, imgSnap) {
                                  final images = imgSnap.data ?? const <String>[];
                                  return GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MoreInformationScreen(data: d))),
                                    child: Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 2,
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AspectRatio(aspectRatio: 16 / 9, child: _UrlImagesPager(urls: images)),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(d['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Expanded(child: Text(d['location'] ?? 'Ukendt', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                                                    Text('${(d['size'] ?? 0).toString()} m²', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Expanded(child: Text(d['period'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                                                    Text('${(d['price'] ?? 0).toString()} DKK', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text('Roommates: ${(d['roommates'] ?? 0) as int}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              return FutureBuilder<List<String>>(
                                future: _fetchImageUrls('applications', doc.id),
                                builder: (ctx, imgSnap) {
                                  final images = imgSnap.data ?? const <String>[];
                                  return InkWell(
                                    onTap: () => _openApplication(doc.id, d),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 2,
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AspectRatio(aspectRatio: 16 / 9, child: _UrlImagesPager(urls: images)),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(d['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                                const SizedBox(height: 6),
                                                Text((d['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemCount: docs.length,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, bool isSeeker) {
    final appsInfo = !isSeeker
        ? Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                Icon(PhosphorIcons.info(), size: 16, color: _iconColor),
                const SizedBox(width: 6),
                const Expanded(child: Text('Ansøgninger sorteres og kan filtreres på dato. Øvrige filtre vises men anvendes ikke.', style: TextStyle(fontSize: 12, color: _labelColor))),
              ],
            ),
          )
        : const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _filtersOpen = !_filtersOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 18, color: _iconColor),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Filtre', style: TextStyle(color: _labelColor, fontWeight: FontWeight.w600))),
                  AnimatedRotation(
                    turns: _filtersOpen ? .5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(PhosphorIcons.caretDown(), color: _iconColor, size: 20),
                  ),
                ],
              ),
            ),
          ),
          if (_filtersOpen)
            Column(
              children: [
                appsInfo,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      _rowLabel('Sortér', _sizedField(_ddForm<String>(
                        context,
                        value: _sort,
                        items: _sortChoices.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _sort = v ?? _sort),
                      ))),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _label('Lokation'),
                          Expanded(
                            child: SizedBox(
                              height: _controlH,
                              child: Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  Container(
                                    height: _controlH,
                                    decoration: BoxDecoration(color: _fill, borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.only(left: 12, right: 36),
                                    child: Center(
                                      child: PostcodeFilterField(
                                        controller: _locCtl,
                                        onSelected: (s) => setState(() {
                                          _location = s;
                                          _locCtl.text = s ?? '';
                                        }),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(PhosphorIcons.caretDown(), size: 18, color: _iconColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _rowLabel('Periode', _sizedField(_ddForm<String?>(
                        context,
                        value: _period,
                        hint: const Text('Alle'),
                        items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setState(() => _period = v),
                      ))),
                      const SizedBox(height: 12),
                      _rowLabel('Oprettet', _sizedField(_ddForm<int?>(
                        context,
                        value: _maxAgeDays,
                        hint: const Text('Alle'),
                        items: _ageChoices.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                        onChanged: (v) => setState(() => _maxAgeDays = v),
                      ))),
                      const SizedBox(height: 12),
                      _info('Pris', '${_price.start.toInt()}–${_price.end.toInt()} kr.'),
                      _sliderTheme(context, RangeSlider(
                        min: _priceMin,
                        max: _priceMax,
                        divisions: 100,
                        values: _price,
                        onChanged: (v) => setState(() => _price = v),
                      )),
                      const SizedBox(height: 8),
                      _info('Størrelse', '${_size.start.toInt()}–${_size.end.toInt()} m²'),
                      _sliderTheme(context, RangeSlider(
                        min: _sizeMin,
                        max: _sizeMax,
                        divisions: 40,
                        values: _size,
                        onChanged: (v) => setState(() => _size = v),
                      )),
                      const SizedBox(height: 8),
                      _info('Roommates', '${_mates.start.toInt()}–${_mates.end.toInt()}'),
                      _sliderTheme(context, RangeSlider(
                        min: _matesMin.toDouble(),
                        max: _matesMax.toDouble(),
                        divisions: 10,
                        values: _mates,
                        onChanged: (v) => setState(() => _mates = v),
                      )),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            height: _controlH,
                            child: TextButton(
                              style: ButtonStyle(
                                minimumSize: MaterialStateProperty.all(const Size(0, _controlH)),
                                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
                                foregroundColor: MaterialStateProperty.all(_labelColor),
                              ),
                              onPressed: () => setState(() {
                                _locCtl.clear();
                                _location = null;
                                _period = null;
                                _maxAgeDays = null;
                                _price = const RangeValues(_priceMin, _priceMax);
                                _size = const RangeValues(_sizeMin, _sizeMax);
                                _mates = RangeValues(_matesMin.toDouble(), _matesMax.toDouble());
                                _sort = 'Nyeste først';
                              }),
                              child: const Text('Nulstil filtre'),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 200,
                            height: _controlH,
                            child: CustomButtonContainer(
                              child: ElevatedButton(
                                style: customElevatedButtonStyle().copyWith(
                                  minimumSize: MaterialStateProperty.all(const Size(double.infinity, _controlH)),
                                  padding: MaterialStateProperty.all(EdgeInsets.zero),
                                  backgroundColor: MaterialStateProperty.all(_btnBg),
                                  foregroundColor: MaterialStateProperty.all(Colors.white),
                                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                ),
                                onPressed: _applyFilters,
                                child: const Text('Opdater'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _ddForm<T>(
    BuildContext context, {
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    T? value,
    Widget? hint,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      icon: Icon(PhosphorIcons.caretDown(), size: 18, color: _iconColor),
      decoration: const InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _fill,
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      hint: hint,
    );
  }

  Widget _sizedField(Widget child) => SizedBox(height: _controlH, child: Center(child: child));
  Widget _rowLabel(String l, Widget w) => Row(children: [_label(l), Expanded(child: w)]);
  Widget _label(String l) => SizedBox(width: 90, child: Text(l, style: const TextStyle(color: _labelColor)));
  Widget _info(String l, String v) => Row(children: [Icon(PhosphorIcons.info(), size: 16, color: _iconColor), const SizedBox(width: 6), Text('$l: $v', style: const TextStyle(color: _labelColor))]);

  Widget _sliderTheme(BuildContext context, Widget child) {
    final base = SliderTheme.of(context);
    return SliderTheme(
      data: base.copyWith(
        trackHeight: 6,
        activeTrackColor: _trackActive,
        inactiveTrackColor: _trackInactive,
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: SliderComponentShape.noOverlay,
        thumbColor: Colors.white,
        valueIndicatorColor: Colors.grey,
      ),
      child: child,
    );
  }
}

class _UrlImagesPager extends StatefulWidget {
  final List<String> urls;
  const _UrlImagesPager({required this.urls});

  @override
  State<_UrlImagesPager> createState() => _UrlImagesPagerState();
}

class _UrlImagesPagerState extends State<_UrlImagesPager> {
  final _controller = PageController();
  int _i = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int dir) {
    final len = widget.urls.length;
    if (len <= 1) return;
    final next = (_i + dir).clamp(0, len - 1);
    if (next == _i) return;
    _controller.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final len = widget.urls.length;
    if (len == 0) {
      return Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white)));
    }
    final leftEnabled = _i > 0;
    final rightEnabled = _i < len - 1;

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          physics: len > 1 ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
          onPageChanged: (v) => setState(() => _i = v),
          itemCount: len,
          itemBuilder: (_, idx) => Image.network(widget.urls[idx], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        ),
        if (leftEnabled)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => _go(-1)),
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
                child: IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: () => _go(1)),
              ),
            ),
          ),
      ],
    );
  }
}
